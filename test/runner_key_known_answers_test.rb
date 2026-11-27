# frozen_string_literal: true

require_relative("test_helper")
require "openssl"

# Checks a runner key's encryption against answers computed elsewhere: HKDF's first test case from RFC 5869, the
# P-256 exchange of RFC 5903, and a token encrypted by hand with that exchange's shared secret.
class RunnerKeyKnownAnswersTest < Minitest::Test
  # The bytes that hex digits, with spaces between them, stand for.
  def bytes(hex)
    [hex.delete(" ")].pack("H*")
  end

  # The P-256 key whose private value is +scalar+, in hex, read from RFC 5915's ECPrivateKey: the version, the private
  # value, the curve, and the public point.
  def key(scalar)
    curve = OpenSSL::ASN1::ASN1Data.new([OpenSSL::ASN1::ObjectId("prime256v1")], 0, :CONTEXT_SPECIFIC)
    public = OpenSSL::ASN1::ASN1Data.new([OpenSSL::ASN1::BitString(point(scalar))], 1, :CONTEXT_SPECIFIC)
    fields = [OpenSSL::ASN1::Integer(1), OpenSSL::ASN1::OctetString(bytes(scalar)), curve, public]
    OpenSSL::PKey::EC.new(OpenSSL::ASN1::Sequence(fields).to_der)
  end

  # The public point of the private value +scalar+, uncompressed.
  def point(scalar)
    group = OpenSSL::PKey::EC::Group.new("prime256v1")
    group.generator.mul(OpenSSL::BN.new(scalar.delete(" "), 16)).to_octet_string(:uncompressed)
  end

  # RFC 5903, section 8.1: the initiator's private value.
  def initiator
    key("C88F01F5 10D9AC3F 70A292DA A2316DE5 44E9AAB8 AFE84049 C62A9C57 862D1433")
  end

  # RFC 5903, section 8.1: the responder's private value.
  def responder
    key("C6EF9C5D 78AE012A 011164AC B397CE20 88685D8F 06BF9BE0 B283AB46 476BEE53")
  end

  # RFC 5869, appendix A.1, through OpenSSL's HKDF with the hash Proof names.
  def test_openssl_hkdf_gives_the_first_test_case_of_its_rfc
    okm = OpenSSL::KDF.hkdf(
      bytes("0b" * 22),
      salt: bytes("000102030405060708090a0b0c"),
      info: bytes("f0f1f2f3f4f5f6f7f8f9"),
      length: 42,
      hash: "SHA256"
    )

    assert_equal(bytes("3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"), okm)
  end

  # RFC 5903, section 8.1: the shared secret of the two keys is girx, and the initiator's public key is (gix, giy).
  def test_openssl_ecdh_gives_the_p256_exchange_of_its_rfc
    gix = "DAD0B653 94221CF9 B051E1FE CA5787D0 98DFE637 FC90B9EF 945D0C37 72581180"
    giy = "5271A046 1CDB8252 D61F1C45 6FA3E59A B1F45B33 ACCF5F58 389E0577 B8990BB3"
    girx = "D6840F6B 42F6EDAF D13116E0 E1256520 2FEF8E9E CE7DCE03 812464D0 4B9442DE"

    assert_equal(bytes("04 #{gix} #{giy}"), initiator.public_key.to_octet_string(:uncompressed))
    assert_equal(bytes(girx), initiator.derive(OpenSSL::PKey.read(responder.public_to_der)))
  end

  # A token encrypted by hand: the key is HKDF-SHA256 of RFC 5903's shared secret, with no salt, over the label
  # "proof runner token", the ephemeral key, and the runner's key, each length-prefixed, and AES-256-GCM encrypts the
  # token with no associated data. The runner's key decrypts it, so the format can't change unnoticed.
  def test_a_runner_key_decrypts_a_token_encrypted_by_hand
    token = Proof::EncryptedToken.new(
      ephemeral_key: initiator.public_to_der,
      nonce: "\x00".b * 12,
      ciphertext: bytes("5382f19ded16850ad10c790f"),
      auth_tag: bytes("4fd1b391c45e3cc15b899ff6868c671a")
    )

    assert_equal("runner token", Proof::RunnerKey.new(key: responder).decrypt(token))
  end
end

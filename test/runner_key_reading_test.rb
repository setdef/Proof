# frozen_string_literal: true

require "minitest/mock"
require "openssl"
require_relative("test_helper")

# Architecture, "Certificates": `RunnerKey.read` takes only the DER that `public_der` gives, on any OpenSSL build.
class RunnerKeyReadingTest < Minitest::Test
  # The DER of a P-256 public key, named by its curve, with the point given as +form+.
  def encoded(key, form, curve: OpenSSL::ASN1::ObjectId("prime256v1"))
    algorithm = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::ObjectId("id-ecPublicKey"), curve])
    OpenSSL::ASN1::Sequence([algorithm, OpenSSL::ASN1::BitString(key.public_key.to_octet_string(form))]).to_der
  end

  # +key+ written every other way OpenSSL reads: as a compressed point, with the curve's parameters spelled out, in
  # PEM, with its private half, and with a byte after it.
  def written_otherwise(key)
    explicit = OpenSSL::PKey::EC::Group.new("prime256v1").tap { |group| group.asn1_flag = 0 }
    [
      encoded(key, :compressed),
      encoded(key, :uncompressed, curve: OpenSSL::ASN1.decode(explicit.to_der)),
      key.public_to_pem,
      key.private_to_der,
      "#{key.public_to_der}\x00",
    ]
  end

  # Architecture, "Certificates": `read` reads the DER that `public_der` gives, which the join tag and the server's tag
  # are over. A key written any other way would give other bytes back, so it is refused with the message of any key
  # that isn't one.
  def test_a_key_written_any_other_way_is_refused
    key = OpenSSL::PKey::EC.generate("prime256v1")

    written_otherwise(key).each do |der|
      error = assert_raises(Proof::RunnerKeyError, der.inspect) { Proof::RunnerKey.read(der) }

      assert_equal("a runner's key is the DER of an EC P-256 public key", error.message)
    end
    assert_equal(key.public_to_der, Proof::RunnerKey.read(encoded(key, :uncompressed)).public_der)
  end

  # An OpenSSL build keeps the form a key was read in: it writes a compressed point back as it read it, and its group
  # says nothing of that. `read` checks the bytes it is given, not what OpenSSL writes back or says, so a build like
  # that can't make it accept a compressed point.
  def test_a_compressed_point_is_refused_whatever_the_openssl_build_writes_back
    key = OpenSSL::PKey::EC.generate("prime256v1")
    compressed = encoded(key, :compressed)
    reading = OpenSSL::PKey.read(compressed)
    reading.define_singleton_method(:public_to_der) { compressed }
    reading.define_singleton_method(:group) { OpenSSL::PKey::EC::Group.new("prime256v1") }

    OpenSSL::PKey.stub(:read, reading) do
      error = assert_raises(Proof::RunnerKeyError) { Proof::RunnerKey.read(compressed) }

      assert_equal("a runner's key is the DER of an EC P-256 public key", error.message)
    end
  end

  # A key with no public half has no point to write, so it is refused as any other key that isn't one is.
  def test_a_key_with_no_public_half_is_refused
    OpenSSL::PKey.stub(:read, OpenSSL::PKey::EC.new("prime256v1")) do
      assert_raises(Proof::RunnerKeyError) { Proof::RunnerKey.read("any bytes") }
    end
  end
end

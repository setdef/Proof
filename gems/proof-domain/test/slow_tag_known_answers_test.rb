# frozen_string_literal: true

require_relative("test_helper")

# Checks the slow tags against answers computed elsewhere: scrypt's test vectors from RFC 7914, and Proof's three
# tags at the cost Proof uses, computed with OpenSSL alone over salts written out by hand.
class SlowTagKnownAnswersTest < Minitest::Test
  # A fingerprint: the pin of a key whose SHA-256 is that of "proof server key".
  FINGERPRINT = "sha256//ouNVSVyn9VS3HHXJN66+ylUann5nGKEOoewjqqBfQlY="
  # A nonce of the bytes 0 to 15.
  NONCE = (0..15).to_a.pack("C*")
  # RFC 7914, section 12: the password, the salt, N, r, p, and the 64 bytes scrypt gives, in hex.
  VECTORS = {
    ["", "", 16, 1, 1] =>
      "77d6576238657b203b19ca42c18a0497f16b4844e3074ae8dfdffa3fede21442" \
      "fcd0069ded0948f8326a753a0fc81f17e8d3e0fb2e0d3628cf35e20c38d18906",
    ["password", "NaCl", 1024, 8, 16] =>
      "fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b373162" \
      "2eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640",
    ["pleaseletmein", "SodiumChloride", 16_384, 8, 1] =>
      "7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2" \
      "d5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887",
  }.freeze
  private_constant(:FINGERPRINT, :NONCE, :VECTORS)

  # The bytes that hex digits, with spaces and line breaks between them, stand for.
  def bytes(hex)
    [hex.delete(" \n")].pack("H*")
  end

  # The code every tag here is computed from.
  def code
    Proof::OneTimeCode.parse("Q8MR-2T4W")
  end

  # RFC 7914, section 12, the first three vectors, through OpenSSL's scrypt with the parameter names Proof passes. The
  # fourth takes 1 GiB, and the cost below checks Proof's own parameters.
  def test_openssl_scrypt_gives_the_test_vectors_of_its_rfc
    VECTORS.each do |parameters, hex|
      pass, salt, cost, block, parallel = parameters

      assert_equal(bytes(hex), OpenSSL::KDF.scrypt(pass, salt:, N: cost, r: block, p: parallel, length: 64), pass)
    end
  end

  # Architecture, "Certificates": "The scrypt parameters (N=2^17, r=8, p=1, 32 bytes) are constants in Proof".
  def test_the_cost_is_n_2_to_the_17_r_8_p_1_and_32_bytes
    assert_equal(Proof::SlowTag::Cost.new(n: 2 ** 17, r: 8, p: 1, length: 32), Proof::SlowTag::COST)
    assert_predicate(Proof::SlowTag::COST, :frozen?)
  end

  # Architecture, "Certificates": the parameters are "never read from a server". No method that computes a tag takes
  # a cost, and the code that computes one at another cost can't be named from outside Proof.
  def test_no_method_that_computes_a_tag_takes_a_cost
    parameters = %i[sign_in join server].to_h { |kind| [kind, Proof::SlowTag.method(kind).parameters] }

    expected = {
      sign_in: [%i[req code], %i[keyreq nonce], %i[keyreq fingerprint]],
      join: [%i[req code], %i[keyreq runner_key]],
      server: [%i[req code], %i[keyreq fingerprint], %i[keyreq runner_key]],
    }

    assert_equal(expected, parameters)
    assert_raises(NameError) { Proof::TagMaker }
  end

  # Architecture, "Certificates": `T = scrypt(code, salt: "proof login", nonce, F)`, with each field length-prefixed.
  def test_a_sign_in_tag_is_scrypt_over_the_label_the_nonce_and_the_fingerprint
    expected = bytes("185e33faaf25a023c0b6bf8002033a697d50cbf1d9a3518d176db9e035fdeadd")

    assert_equal(expected, Proof::SlowTag.sign_in(code, nonce: NONCE, fingerprint: FINGERPRINT).bytes)
  end

  # Architecture, "Certificates": `J = scrypt(c, salt: "proof join", R)`.
  def test_a_join_tag_is_scrypt_over_the_label_and_the_runners_key
    expected = bytes("5dc5f3014a1b2d9f2eda58f51e628c09bc24f04cc63bb795467c1f6a08aa743c")

    assert_equal(expected, Proof::SlowTag.join(code, runner_key: "runner key").bytes)
  end

  # Architecture, "Certificates": `S = scrypt(c, salt: "proof server", F, R)`.
  def test_a_server_tag_is_scrypt_over_the_label_the_fingerprint_and_the_runners_key
    expected = bytes("09cc51b1d12fb36a95f1ada77f98360322b68dfd4f6af9f58c6c4f75302b386f")

    assert_equal(expected, Proof::SlowTag.server(code, fingerprint: FINGERPRINT, runner_key: "runner key").bytes)
  end
end

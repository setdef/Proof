# frozen_string_literal: true

require_relative("test_helper")
require "minitest/mock"
require "proof/testing"

# Checks the rules of a slow tag, at the cost only Proof::Testing has, so each tag takes a millisecond.
class SlowTagTest < Minitest::Test
  # The pin of a fingerprint of 32 bytes of +byte+.
  def pin(byte)
    "sha256//#{[byte * 32].pack('m0')}"
  end

  # The tags at the test cost.
  def tags
    Proof::Testing::QUICK_TAGS
  end

  # A code, as typed.
  def code(text = "Q8MR-2T4W")
    Proof::OneTimeCode.parse(text)
  end

  # A sign-in tag of +code+ over a nonce of 16 bytes of +nonce+ and the fingerprint of +fingerprint+.
  def sign_in(code, nonce: "n", fingerprint: "f")
    tags.sign_in(code, nonce: nonce * 16, fingerprint: pin(fingerprint))
  end

  # A server's tag of +code+ over the fingerprint of +fingerprint+ and +runner_key+.
  def server(code, fingerprint: "f", runner_key: "r")
    tags.server(code, fingerprint: pin(fingerprint), runner_key:)
  end

  # Architecture, "Certificates": "A forged tag needs the code." A tag of a wrong code never matches.
  def test_a_tag_of_another_code_differs
    refute_equal(sign_in(code), sign_in(code("Q8MR-2T4X")))
    refute_equal(tags.join(code, runner_key: "r"), tags.join(code("Q8MR-2T4X"), runner_key: "r"))
    refute_equal(server(code), server(code("Q8MR-2T4X")))
  end

  # Architecture, "Certificates": "Codes are normalized before scrypt", so every way of typing a code gives one tag.
  def test_every_way_of_typing_a_code_gives_one_tag
    assert_equal(sign_in(code("Q8MR-2T4W")), sign_in(code("q8mr2t4w")))
  end

  # A tag is computed only from a one-time code, which is read before it is used, never from text as typed.
  def test_a_tag_of_text_is_refused
    error = assert_raises(Proof::InvalidSlowTagError) { tags.join("Q8MR-2T4W", runner_key: "r") }

    assert_equal("a slow tag is computed from a Proof::OneTimeCode, not a String", error.message)
  end

  # Architecture, "Certificates": "A fresh salt per code stops any table built ahead of time", so the nonce and the
  # fingerprint each change a sign-in tag.
  def test_the_nonce_and_the_fingerprint_change_a_sign_in_tag
    refute_equal(sign_in(code), sign_in(code, nonce: "m"))
    refute_equal(sign_in(code), sign_in(code, fingerprint: "g"))
  end

  # Architecture, "Certificates": a runner pins the server's key "only if `S` matches over the key it saw", and a join
  # tag is over the runner's key, so a relayed request with another key doesn't match.
  def test_the_runners_key_and_the_fingerprint_change_the_tags_over_them
    refute_equal(tags.join(code, runner_key: "r"), tags.join(code, runner_key: "s"))
    refute_equal(server(code), server(code, runner_key: "s"))
    refute_equal(server(code), server(code, fingerprint: "g"))
  end

  # A nonce is 16 bytes.
  def test_a_nonce_of_another_length_is_refused
    ["n" * 15, "n" * 17, nil].each do |nonce|
      assert_raises(Proof::InvalidSlowTagError, nonce.inspect) { tags.sign_in(code, nonce:, fingerprint: pin("f")) }
    end
  end

  # Glossary, "fingerprint": the SHA-256 of the server's public key, in the form `http.pinnedPubkey` takes.
  def test_a_fingerprint_in_another_form_is_refused
    hex = "sha256//#{'f'.unpack1('H*') * 32}"
    raw = "f" * 32
    short = "sha256//#{['f' * 31].pack('m0')}"
    loose = pin("f").sub("=", "")

    [hex, raw, short, loose, nil].each do |fingerprint|
      assert_raises(Proof::InvalidSlowTagError, fingerprint.inspect) { tags.server(code, fingerprint:, runner_key: "r") }
    end
  end

  # A runner's key is bytes, and an empty key is no key.
  def test_an_empty_runners_key_is_refused
    ["", nil].each do |runner_key|
      assert_raises(Proof::InvalidSlowTagError, runner_key.inspect) { tags.join(code, runner_key:) }
    end
  end

  # A tag is 32 bytes, so a tag received from the network is checked before it is compared.
  def test_a_tag_is_32_bytes
    assert_equal(32, sign_in(code).bytes.bytesize)
    ["t" * 31, "t" * 33, nil].each do |bytes|
      assert_raises(Proof::InvalidSlowTagError, bytes.inspect) { Proof::SlowTag.new(bytes:) }
    end
  end

  # A tag received as bytes equals the tag computed over the same fields.
  def test_a_received_tag_equals_the_one_computed
    computed = sign_in(code)

    assert_equal(computed, Proof::SlowTag.new(bytes: computed.bytes.dup))
    assert(computed.eql?(Proof::SlowTag.new(bytes: computed.bytes.dup)))
    refute_equal(computed, computed.bytes)
  end

  # Architecture, "Certificates": tags are compared in constant time, with OpenSSL's comparison of two strings of one
  # length.
  def test_equality_compares_in_constant_time
    compared = []
    comparison = lambda do |one, other|
      compared << [one, other]
      true
    end
    equal = OpenSSL.stub(:fixed_length_secure_compare, comparison) do
      Proof::SlowTag.new(bytes: "a" * 32) == Proof::SlowTag.new(bytes: "b" * 32)
    end

    assert(equal)
    assert_equal([["a" * 32, "b" * 32]], compared)
  end
end

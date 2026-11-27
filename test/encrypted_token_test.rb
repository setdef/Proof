# frozen_string_literal: true

require_relative("test_helper")

# Checks the fields of a token encrypted to a runner's key, as they arrive from the network.
class EncryptedTokenTest < Minitest::Test
  # The fields of a token in the form AES-GCM gives them.
  def fields
    { ephemeral_key: "key", nonce: "n" * 12, ciphertext: "token", auth_tag: "t" * 16 }
  end

  # A nonce is the 12 bytes AES-GCM takes, and a tag the 16 it gives: Ruby's openssl checks as few bytes of a tag as it
  # is given.
  def test_a_nonce_or_a_tag_of_another_length_is_refused
    { nonce: ["n" * 11, "n" * 13], auth_tag: ["t" * 12, "t" * 17] }.each do |field, values|
      values.each do |value|
        assert_raises(Proof::InvalidEncryptedTokenError, field.to_s) { Proof::EncryptedToken.new(**fields, field => value) }
      end
    end
  end

  # Every field is bytes, and an empty ephemeral key is no key.
  def test_a_field_that_isnt_bytes_or_an_empty_key_is_refused
    [{ ephemeral_key: "" }, { ephemeral_key: nil }, { ciphertext: nil }, { nonce: 12 }].each do |change|
      assert_raises(Proof::InvalidEncryptedTokenError, change.inspect) { Proof::EncryptedToken.new(**fields, **change) }
    end
  end

  # The fields keep their bytes, in the binary encoding.
  def test_the_fields_are_binary
    token = Proof::EncryptedToken.new(**fields)

    assert_equal(fields.transform_values(&:b), token.to_h)
    assert(token.to_h.values.all? { |value| value.encoding == Encoding::BINARY && value.frozen? })
  end
end

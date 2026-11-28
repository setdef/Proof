# frozen_string_literal: true

require_relative("token_cipher")

module Proof
  class EncryptedToken < Data.define(:ephemeral_key, :nonce, :ciphertext, :auth_tag)
    NONCE_LENGTH = 12
    TAG_LENGTH = 16
    public_constant(:NONCE_LENGTH, :TAG_LENGTH)

    def initialize(ephemeral_key:, nonce:, ciphertext:, auth_tag:)
      super(
        ephemeral_key: TokenCipher.field(ephemeral_key, 1.., "ephemeral key is bytes, and isn't empty"),
        nonce: TokenCipher.field(nonce, NONCE_LENGTH..NONCE_LENGTH, "nonce is #{NONCE_LENGTH} bytes"),
        ciphertext: TokenCipher.field(ciphertext, 0.., "ciphertext is bytes"),
        auth_tag: TokenCipher.field(auth_tag, TAG_LENGTH..TAG_LENGTH, "tag is #{TAG_LENGTH} bytes")
      )
    end

    # @dynamic ephemeral_key, nonce, ciphertext, auth_tag
  end
end

# frozen_string_literal: true

require "openssl"
require_relative("runner_key_errors")

module Proof
  module TokenCipher
    NAME = "aes-256-gcm"
    LABEL = "proof runner token"
    private_constant(:NAME, :LABEL)

    def self.field(value, lengths, refusal)
      return value.b.freeze if value.is_a?(String) && lengths.cover?(value.bytesize)

      raise(InvalidEncryptedTokenError, "an encrypted token's #{refusal}")
    end

    def self.encrypt(token, recipient)
      ephemeral = OpenSSL::PKey::EC.generate(RunnerKey::CURVE)
      ephemeral_key = ephemeral.public_to_der
      cipher = keyed(:encrypt, ephemeral.derive(recipient), info(ephemeral_key, recipient))
      # A fresh key for every token makes a nonce that repeats harmless, and a random one costs nothing. The tag
      # exists only once the ciphertext is finished, and keywords are evaluated in order.
      nonce = cipher.random_iv
      EncryptedToken.new(ephemeral_key:, nonce:, ciphertext: ciphered(cipher, token), auth_tag: cipher.auth_tag)
    end

    def self.decrypt(encrypted, recipient)
      ephemeral_key = encrypted.ephemeral_key
      cipher = keyed(:decrypt, recipient.derive(RunnerKey.read(ephemeral_key).key), info(ephemeral_key, recipient))
      cipher.iv = encrypted.nonce
      cipher.auth_tag = encrypted.auth_tag
      ciphered(cipher, encrypted.ciphertext)
    end

    def self.info(ephemeral_key, recipient)
      # The key depends on both public keys, so a token encrypted to one runner's key never decrypts with another's.
      LengthPrefixed.join(LABEL, ephemeral_key, recipient.public_to_der)
    end

    def self.keyed(direction, shared, info)
      cipher = OpenSSL::Cipher.new(NAME).public_send(direction)
      cipher.key = OpenSSL::KDF.hkdf(shared, salt: "", info:, length: cipher.key_len, hash: "SHA256")
      cipher
    end

    def self.ciphered(cipher, bytes)
      cipher.auth_data = ""
      cipher.update(bytes) + cipher.final
    end
    private_class_method(:info, :keyed, :ciphered)
  end
  private_constant(:TokenCipher)
end

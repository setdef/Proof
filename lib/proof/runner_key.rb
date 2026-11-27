# frozen_string_literal: true

require "openssl"
require_relative("encrypted_token")
require_relative("runner_key_errors")
require_relative("token_cipher")

module Proof
  # steep:ignore:start
  class RunnerKey < Data.define(:key)
    # steep:ignore:end
    CURVE = "prime256v1"
    public_constant(:CURVE)

    def self.generate
      new(key: OpenSSL::PKey::EC.generate(CURVE))
    end

    def self.read(der)
      new(key: OpenSSL::PKey.read(der))
    rescue OpenSSL::PKey::PKeyError
      raise(RunnerKeyError, "a runner's key is the DER of an EC P-256 public key")
    end

    def self.runner_key?(key)
      key.is_a?(OpenSSL::PKey::EC) && key.group == OpenSSL::PKey::EC::Group.new(CURVE)
    end

    def initialize(key:)
      raise(RunnerKeyError, "a runner's key is an EC P-256 key, not #{key.class}") unless self.class.runner_key?(key)

      super
    end

    def public_der
      key.public_to_der
    end

    def encrypt(token)
      TokenCipher.encrypt(token, key)
    end

    def decrypt(encrypted)
      raise(RunnerKeyError, "only the runner's private key decrypts its token") unless key.private?

      opened(encrypted).force_encoding(Encoding::UTF_8)
    end

    private def opened(encrypted)
      TokenCipher.decrypt(encrypted, key)
    rescue RunnerKeyError, OpenSSL::Cipher::CipherError
      # One message for every cause, so a refusal tells whoever changed the token nothing.
      raise(TokenDecryptionError, "the token doesn't decrypt with this runner's key")
    end
  end
end

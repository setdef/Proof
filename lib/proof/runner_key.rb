# frozen_string_literal: true

require "openssl"
require_relative("encrypted_token")
require_relative("runner_key_errors")
require_relative("token_cipher")

module Proof
  class RunnerKey < Data.define(:key)
    CURVE = "prime256v1"
    public_constant(:CURVE)

    def self.generate
      new(key: OpenSSL::PKey::EC.generate(CURVE))
    end

    SPKI_HEAD = ["3059301306072a8648ce3d020106082a8648ce3d030107034200"].pack("H*")
    private_constant(:SPKI_HEAD)

    READ_REFUSAL = "a runner's key is the DER of an EC P-256 public key"
    private_constant(:READ_REFUSAL)

    def self.read(der)
      key = parsed(der)
      # The tags are over the bytes a join request carries, and the token's key over the bytes public_der gives, so
      # those must be one string. OpenSSL reads PEM and a private key too, and a build may write a compressed point
      # back as it read it, so the bytes are compared with the DER built here from the key's own point, not with what
      # OpenSSL writes.
      return new(key:) if key && runner_key?(key) && canonical(key) == der

      raise(RunnerKeyError, READ_REFUSAL)
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

    def self.parsed(der)
      key = OpenSSL::PKey.read(der)
      key if key.is_a?(OpenSSL::PKey::EC)
    rescue OpenSSL::PKey::PKeyError
      nil
    end

    def self.canonical(key)
      point = key.public_key or return
      # The head of a SubjectPublicKeyInfo of 91 bytes: id-ecPublicKey, prime256v1 by its name, and a bit string of 66
      # bytes, whose first is the unused bits, none.
      "#{SPKI_HEAD}#{point.to_octet_string(:uncompressed)}"
    end
    private_class_method(:parsed, :canonical)

    private def opened(encrypted)
      TokenCipher.decrypt(encrypted, key)
    rescue RunnerKeyError, OpenSSL::Cipher::CipherError
      # One message for every cause, so a refusal tells whoever changed the token nothing. Ruby would keep the error
      # rescued here as the cause, and print its message after this one.
      raise(TokenDecryptionError, "the token doesn't decrypt with this runner's key", cause: nil)
    end

    # @dynamic key
  end
end

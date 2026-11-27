# frozen_string_literal: true

require "openssl"

module Proof
  class TagMaker < Data.define(:cost)
    def sign_in(code, nonce:, fingerprint:)
      tag(code, "proof login", TagFields.nonce(nonce), TagFields.fingerprint(fingerprint))
    end

    def join(code, runner_key:)
      tag(code, "proof join", TagFields.runner_key(runner_key))
    end

    def server(code, fingerprint:, runner_key:)
      tag(code, "proof server", TagFields.fingerprint(fingerprint), TagFields.runner_key(runner_key))
    end

    private def tag(code, *salt)
      unless code.is_a?(OneTimeCode)
        raise(InvalidSlowTagError, "a slow tag is computed from a Proof::OneTimeCode, not a #{code.class}")
      end

      derived = OpenSSL::KDF.scrypt(
        code.characters, salt: LengthPrefixed.join(*salt), N: cost.n, r: cost.r, p: cost.p, length: cost.length
      )
      SlowTag.new(bytes: derived)
    end

    # @dynamic cost, initialize
  end
  private_constant(:TagMaker)
end

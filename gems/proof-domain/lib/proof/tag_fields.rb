# frozen_string_literal: true

module Proof
  module TagFields
    PIN = %r{\Asha256//(?<hash>[A-Za-z0-9+/]{43}=)\z}
    private_constant(:PIN)

    def self.tag(given)
      length = SlowTag::COST.length
      return given.b.freeze if given.is_a?(String) && given.bytesize == length

      raise(InvalidSlowTagError, "a slow tag is #{length} bytes")
    end

    def self.nonce(given)
      return given.b if given.is_a?(String) && given.bytesize == SlowTag::NONCE_LENGTH

      raise(InvalidSlowTagError, "a slow tag's nonce is #{SlowTag::NONCE_LENGTH} bytes")
    end

    def self.fingerprint(given)
      encoded = PIN.match(given.to_s)&.[](:hash)
      hash = encoded&.unpack1("m")
      # Base64 can write one hash in several ways, which would make one fingerprint several pins.
      return hash if hash.is_a?(String) && [hash].pack("m0") == encoded

      raise(InvalidSlowTagError, "a fingerprint is sha256// and the Base64 of 32 bytes, as http.pinnedPubkey takes it")
    end

    def self.runner_key(given)
      return given.b if given.is_a?(String) && !given.empty?

      raise(InvalidSlowTagError, "a runner's key is the bytes of its public key, and can't be empty")
    end
  end
  private_constant(:TagFields)
end

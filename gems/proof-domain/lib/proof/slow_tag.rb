# frozen_string_literal: true

require "openssl"

module Proof
  # steep:ignore:start
  class SlowTag < Data.define(:bytes)
    # steep:ignore:end
    # steep:ignore:start
    class Cost < Data.define(:n, :r, :p, :length)
      # steep:ignore:end
    end

    COST = Cost.new(n: 2 ** 17, r: 8, p: 1, length: 32)
    public_constant(:COST)

    NONCE_LENGTH = 16
    public_constant(:NONCE_LENGTH)

    def self.sign_in(code, nonce:, fingerprint:)
      TagMaker.new(cost: COST).sign_in(code, nonce:, fingerprint:)
    end

    def self.join(code, runner_key:)
      TagMaker.new(cost: COST).join(code, runner_key:)
    end

    def self.server(code, fingerprint:, runner_key:)
      TagMaker.new(cost: COST).server(code, fingerprint:, runner_key:)
    end

    def initialize(bytes:)
      super(bytes: TagFields.tag(bytes))
    end

    def ==(other)
      # Data#== compares with String#==, which stops at the first byte that differs. Both tags are 32 bytes, which
      # OpenSSL's fixed-length comparison needs.
      other.is_a?(self.class) && OpenSSL.fixed_length_secure_compare(bytes, other.bytes)
    end
    alias eql? ==
  end
end

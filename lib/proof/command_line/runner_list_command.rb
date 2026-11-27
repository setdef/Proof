# frozen_string_literal: true

module Proof
  module CommandLine
    class RunnerListCommand < Data.define(:json)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic json, initialize
    end
  end
end

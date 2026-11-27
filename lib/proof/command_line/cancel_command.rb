# frozen_string_literal: true

module Proof
  module CommandLine
    class CancelCommand < Data.define(:runs)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic runs, initialize
    end
  end
end

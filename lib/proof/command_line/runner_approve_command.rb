# frozen_string_literal: true

module Proof
  module CommandLine
    class RunnerApproveCommand < Data.define(:code)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic code, initialize
    end
  end
end

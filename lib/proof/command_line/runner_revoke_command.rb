# frozen_string_literal: true

module Proof
  module CommandLine
    class RunnerRevokeCommand < Data.define(:name, :force)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic name, force, initialize
    end
  end
end

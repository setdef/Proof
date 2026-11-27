# frozen_string_literal: true

module Proof
  module CommandLine
    class HookInstallCommand < Data.define(:task, :force)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic task, force, initialize
    end
  end
end

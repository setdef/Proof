# frozen_string_literal: true

module Proof
  module CommandLine
    class RunnerSetupCommand < Data.define(:server, :name, :desktop, :no_wsl, :dry_run)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic server, name, desktop, no_wsl, dry_run, initialize
    end
  end
end

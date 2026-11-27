# frozen_string_literal: true

module Proof
  module CommandLine
    class ServerSetupCommand < Data.define(:dry_run)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic dry_run, initialize
    end
  end
end

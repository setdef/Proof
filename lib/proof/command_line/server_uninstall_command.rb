# frozen_string_literal: true

module Proof
  module CommandLine
    class ServerUninstallCommand < Data.define(:force)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic force, initialize
    end
  end
end

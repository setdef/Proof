# frozen_string_literal: true

module Proof
  module CommandLine
    class GlobalFlags < Data.define(:quiet, :debug, :no_color, :no_input, :version)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic quiet, debug, no_color, no_input, version, initialize
    end
  end
end

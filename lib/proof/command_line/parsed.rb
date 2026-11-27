# frozen_string_literal: true

module Proof
  module CommandLine
    class Parsed < Data.define(:global, :command)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic global, command, initialize
    end
  end
end

# frozen_string_literal: true

module Proof
  module CommandLine
    class HelpAsked < Data.define(:path)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic path, initialize
    end
  end
end

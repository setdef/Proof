# frozen_string_literal: true

module Proof
  module CommandLine
    class TaskWords < Data.define(:name, :words)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic name, words, initialize
    end
  end
end

# frozen_string_literal: true

module Proof
  module CommandLine
    class LogsCommand < Data.define(:run, :tail, :no_pager)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic run, tail, no_pager, initialize
    end
  end
end

# frozen_string_literal: true

module Proof
  module CommandLine
    class WatchCommand < Data.define(:run, :json)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic run, json, initialize
    end
  end
end

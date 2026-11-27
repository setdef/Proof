# frozen_string_literal: true

module Proof
  module CommandLine
    class DownloadCommand < Data.define(:run, :patterns, :output, :json)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic run, patterns, output, json, initialize
    end
  end
end

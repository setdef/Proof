# frozen_string_literal: true

module Proof
  module CommandLine
    class VersionAsked < Data.define
      def self.of(line)
        new if line.given?("version") && !line.help? && line.command.path.empty?
      end

      # Steep reports as missing the method that Data.define makes, and the signature declares it.
      # @dynamic initialize
    end
  end
end

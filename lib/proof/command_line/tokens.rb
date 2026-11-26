# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
    module Tokens
      def self.flag?(token)
        token.start_with?("-") && token != "-"
      end

      def self.expand(token)
        cluster = token.length > 2 && flag?(token) && !token.start_with?("--")
        cluster ? token.delete_prefix("-").chars.map { |letter| "-#{letter}" } : [token]
      end

      def self.cluster?(token, switches)
        letters = token.delete_prefix("-").chars
        token.length > 2 && !token.start_with?("--") && letters.all? { |letter| switches.include?("-#{letter}") }
      end
    end
    private_constant(:Tokens)
  end
end

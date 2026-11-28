# frozen_string_literal: true

module Proof
  module CommandLine
    module FlagName
      LETTERLESS = [nil, "-", "--"].freeze
      private_constant(:LETTERLESS)

      def self.typed(word, switches)
        # --os=linux is named --os. Cut at "=", -q=1 would be -q, which Proof has.
        name = word.split("=").first.to_s
        lacking = (letters(name) - switches).first
        # A word of letters is named by the first one Proof lacks (issue #51), unless it lacks none, or the first is
        # "-", which is no letter a flag can have.
        LETTERLESS.include?(lacking) ? word : lacking.to_s
      end

      def self.letters(name)
        letters = name.length > 2 && !name.start_with?("--")
        letters ? name.delete_prefix("-").chars.map { |letter| "-#{letter}" } : [name]
      end
      private_class_method(:letters)
    end
  end
end

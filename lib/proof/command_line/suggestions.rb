# frozen_string_literal: true

require "did_you_mean"

module Proof
  module CommandLine
    module Suggestions
      def self.for(word, dictionary)
        return [] if word.start_with?("-") && !word.start_with?("--")

        DidYouMean::SpellChecker.new(dictionary:).correct(word)
      end
    end
  end
end

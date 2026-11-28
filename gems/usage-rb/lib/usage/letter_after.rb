# frozen_string_literal: true

module Usage
  class LetterAfter < Data.define(:text)
    def refused_by?(_rules)
      # usage reads the letter after one that takes a value as a flag of its own, which can never be the value.
      true
    end

    # @dynamic text, initialize
  end
end

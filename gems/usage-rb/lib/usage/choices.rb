# frozen_string_literal: true

module Usage
  class Choices < Data.define(:values, :strict)
    def strict?
      strict
    end

    def accepts?(word)
      # With no values there is nothing to check a word against, so any word is accepted.
      values.empty? || !strict || values.include?(word)
    end

    # @dynamic values, strict, initialize
  end
end

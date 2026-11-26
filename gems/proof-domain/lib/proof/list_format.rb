# frozen_string_literal: true

module Proof
  module ListFormat
    def self.conjunction(items)
      joined(items, "and")
    end

    def self.disjunction(items)
      joined(items, "or")
    end

    def self.joined(items, word)
      # Two items take the word with no comma, and three or more take a serial comma.
      *rest, last = items
      return last.to_s if rest.empty?

      "#{rest.join(', ')}#{',' if rest.size > 1} #{word} #{last}"
    end
    private_class_method(:joined)
  end
end

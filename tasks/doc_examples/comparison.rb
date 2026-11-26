# frozen_string_literal: true

module DocExamples
  # Compares the value of an expression with the value its +# =>+ comment gives.
  module Comparison
    # What is wrong with +actual+, or nil when it matches +expected+. The two
    # must be equal and print the same, so 1.0 doesn't match 1 and a hash with
    # its keys in another order doesn't match.
    def self.mismatch(actual, expected)
      seen, wanted = [actual, expected].map(&:inspect)
      return if actual == expected && seen == wanted

      "expected #{wanted}, but got #{seen}"
    end
  end
end

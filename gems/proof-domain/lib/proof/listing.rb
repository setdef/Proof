# frozen_string_literal: true

module Proof
  module Listing
    def self.set(values, kind, minimum)
      return unless [Array, Set].any? { |collection| values.is_a?(collection) }

      found = Set.new(values).freeze
      found if found.all?(kind) && found.size >= minimum
    end
  end
  private_constant(:Listing)
end

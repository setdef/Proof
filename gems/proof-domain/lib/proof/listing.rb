# frozen_string_literal: true

module Proof
  module Listing
    def self.set(values, kind, minimum)
      return unless values.is_a?(Array) || values.is_a?(Set)

      found = Set.new(values).freeze
      found if found.all?(kind) && found.size >= minimum
    end
  end
  private_constant(:Listing)
end

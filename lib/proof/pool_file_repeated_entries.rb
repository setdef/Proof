# frozen_string_literal: true

module Proof
  class PoolFileRepeatedEntries
    def initialize(entries, refusal:)
      @entries = entries
      @refusal = refusal
    end

    def check
      repeat = Name.first_repeat(@entries.map { |entry| entry.arguments.first })
      return unless repeat

      # first_repeat found two positions in the list it was given, which has one name for each entry.
      first, second = @entries.values_at(repeat.first, repeat.last) #: [KdlNode, KdlNode]
      @refusal.repeated_entry(second, first)
    end
  end
end

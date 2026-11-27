# frozen_string_literal: true

module Proof
  class PoolFileRepeatedEntries
    def initialize(entries, refusal:)
      @entries = entries
      @refusal = refusal
    end

    def check
      @entries.each_with_index { |entry, index| refuse_after(entry, index) }
    end

    private def refuse_after(entry, index)
      name = entry.arguments.first
      first = @entries.take(index).find { |other| PoolFileNames.same?(other.arguments.first, name) }
      @refusal.repeated_entry(entry, first) if first
    end
  end
end

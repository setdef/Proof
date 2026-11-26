# frozen_string_literal: true

module Proof
  module Sqlite
    module Refusals
      PLACED = "Placed"
      private_constant(:PLACED)

      def self.append(run, fact, read)
        id = run.id
        version = run.version
        raise(RunAlreadyPlacedError.new(id:)) if run.placement && FactRows.kind(fact) == PLACED
        raise(RunChangedError.new(id:, version:, read:)) unless version == read
      end

      def self.beaten(run, fact, rows)
        id = run.id
        placed = rows.any? { |row| row[:kind] == PLACED }
        return RunAlreadyPlacedError.new(id:) if placed && FactRows.kind(fact) == PLACED

        RunChangedError.new(id:, version: rows.size, read: run.version - 1)
      end
    end
  end
end

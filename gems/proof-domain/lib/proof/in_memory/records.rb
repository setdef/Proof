# frozen_string_literal: true

module Proof
  module InMemory
    class Records
      def initialize(table)
        @table = table
      end

      def runs
        rebuilt = @table.map { |id, facts| Run.new(id:, facts:) }
        rebuilt.sort_by { |run| run.queued.position }
      end

      def add(run)
        id = run.id
        raise(RunExistsError.new(id:)) if @table.key?(id)

        free(run.queued.position)
        @table[id] = run.facts
      end

      def append(id, fact, read)
        added = stored(id, fact, read).with_fact(fact)
        @table[id] = added.facts
        added
      end

      private def free(position)
        raise(QueuePositionTakenError.new(position:)) if runs.any? { |stored| stored.queued.position == position }
      end

      private def stored(id, fact, read)
        run = Run.new(id:, facts: @table[id] || raise(UnknownRunError.new(id:)))
        raise(RunAlreadyPlacedError.new(id:)) if fact.is_a?(Run::Placed) && run.placement

        version = run.version
        (version == read) ? run : raise(RunChangedError.new(id:, version:, read:))
      end
    end
  end
end

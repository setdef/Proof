# frozen_string_literal: true

require_relative("fact_rows")
require_relative("refusals")
require_relative("run_rows")

module Proof
  module Sqlite
    class Writer
      def initialize(facts)
        @facts = facts
        @create = facts.command(:create)
      end

      def add(run)
        insert(RunRows.rows(run))
      rescue ROM::SQL::UniqueConstraintError
        # The unique indexes refuse a run whose ID or queue position another run has. Whether the ID is stored says
        # which.
        id = run.id
        raise(RunExistsError.new(id:)) unless @facts.of(id.to_s).to_a.empty?

        raise(QueuePositionTakenError.new(position: run.queued.position))
      end

      def append(run, fact)
        id = run.id
        insert(FactRows.row(id, run.version, fact))
      rescue ROM::SQL::UniqueConstraintError
        # The unique indexes refuse a writer that read before another wrote. What the other writer stored says which.
        raise(Refusals.beaten(run, fact, @facts.of(id.to_s).to_a))
      end

      private def insert(rows)
        @facts.transaction { @create.call(rows) }
      end
    end
  end
end

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
        # The unique indexes refuse a run whose ID or queue position another run has. What is stored says which.
        raise(Refusals.added(run, stored(run)))
      end

      def append(run, fact)
        insert(FactRows.row(run.id, run.version, fact))
      rescue ROM::SQL::UniqueConstraintError
        # The unique indexes refuse a writer that read before another wrote. What the other writer stored says which.
        raise(Refusals.beaten(run, fact, stored(run)))
      end

      private def insert(rows)
        @facts.transaction { @create.call(rows) }
      end

      private def stored(run)
        @facts.of(run.id.to_s).to_a
      end
    end
  end
end

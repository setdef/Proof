# frozen_string_literal: true

module Proof
  module Sqlite
    module RunRows
      def self.rows(run)
        run.facts.each_with_index.map { |fact, index| FactRows.row(run.id, index + 1, fact) }
      end

      def self.runs(rows)
        rows.group_by { |row| row[:run_id] }
          .map { |id, run_rows| run(RunId.parse(String(id)), run_rows) }
          .sort_by { |run| run.queued.position }
      end

      def self.run(id, rows)
        # Every read rebuilds the run from its facts, so a record changed behind Proof's back fails to load.
        Run.new(id:, facts: rows.map { |row| FactRows.fact(row) })
      end
    end
  end
end

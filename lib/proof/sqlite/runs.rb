# frozen_string_literal: true

require_relative("database")
require_relative("fact_rows")
require_relative("refusals")
require_relative("run_rows")
require_relative("writer")

module Proof
  module Sqlite
    class Runs
      attr_reader :path

      def initialize(path:)
        # The class line is ignored by Steep, which doesn't count attr_reader as defining the reader that the
        # signature declares, and RuboCop rejects a method that only returns an instance variable.
        @path = path
        @container = Database.open(path)
        @facts = @container.relations[:facts]
        @writer = Writer.new(@facts)
      end

      def close
        @container.gateways[:default].disconnect
      end

      def use_logger(logger)
        @container.gateways[:default].use_logger(logger)
      end

      def add(run)
        @writer.add(run)
        nil
      end

      def find(id)
        rows = @facts.of(id.to_s).to_a
        RunRows.run(id, rows) unless rows.empty?
      end

      def append(id, fact, version:)
        run = find(id) || raise(UnknownRunError.new(id:))
        Refusals.append(run, fact, version)
        added = run.with_fact(fact)
        @writer.append(added, fact)
        added
      end

      def queued
        all.select { |run| run.state == :queued }
      end

      def holding_resources
        all.select(&:holds_resources?)
      end

      def next_position
        (@facts.max(:position) || 0) + 1
      end

      private def all
        RunRows.runs(@facts.in_order.to_a)
      end

      # @dynamic path
    end
  end
end

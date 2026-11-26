# frozen_string_literal: true

require_relative("records")

module Proof
  module InMemory
    class Runs
      attr_reader :records

      def initialize(records: {})
        @records = records
        @lock = Thread::Mutex.new
      end

      def add(run)
        @lock.synchronize { Records.new(records).add(run) }
        nil
      end

      def find(id)
        facts = @lock.synchronize { records[id] }
        # Every read rebuilds the run from its facts, so a record changed behind Proof's back fails to load.
        Run.new(id:, facts:) if facts
      end

      def append(id, fact, version:)
        @lock.synchronize { Records.new(records).append(id, fact, version) }
      end

      def queued
        all.select { |run| run.state == :queued }
      end

      def holding_resources
        all.select(&:holds_resources?)
      end

      def next_position
        positions = all.map { |run| run.queued.position }
        (positions.max || 0) + 1
      end

      private def all
        @lock.synchronize { Records.new(records).runs }
      end
    end
  end
end

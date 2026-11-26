# frozen_string_literal: true

require_relative("run_fixtures")

module Proof
  module Testing
    module AtOnce
      def self.place(runs, count)
        run(count) do |thread|
          runs.append(RunFixtures.id, RunFixtures.placed(runner: "runner-#{thread}"), version: 1)
          :placed
        rescue RunAlreadyPlacedError, RunChangedError
          :refused
        end
      end

      def self.add(runs, ids)
        run(ids.size) do |thread|
          runs.add(RunFixtures.run(id: ids[thread]))
          :added
        rescue QueuePositionTakenError
          :refused
        end
      end

      def self.run(count, &)
        start = Thread::Queue.new
        threads = Array.new(count) { |thread| waiting(start, thread, &) }
        # Closing the queue lets every waiting thread go at once, so the calls overlap.
        start.close
        threads.map(&:value)
      end

      def self.waiting(start, thread)
        Thread.new do
          start.pop
          yield(thread)
        end
      end
    end
  end
end

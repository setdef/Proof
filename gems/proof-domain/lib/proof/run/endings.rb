# frozen_string_literal: true

# The table below names the final states while the file loads, so the file loads them first.
require_relative("facts")

module Proof
  class Run
    module Endings
      # @type var needs: Hash[Class, [Symbol, String]]
      needs = {
        Succeeded => [
          :passed?,
          "a run succeeds only after its command exits with 0, its whole output arrives, and its artifacts are kept",
        ],
        Failed => [
          :failed?,
          "a run fails only after its whole output arrives and its command ends with another status than 0 or its " \
            "artifacts aren't kept, or when the server is short of space before its command starts",
        ],
        TimedOut => [:started?, "a run times out only after its command starts"],
        OutOfMemory => [:started?, "a run runs out of memory only after its command starts"],
        Canceled => [:canceled?, "a run is canceled only after a cancel is asked for"],
        Lost => [:placed?, "a run is lost only after it is placed"],
      }
      NEEDS = needs.freeze
      AFTER_FINAL = "a final state is final: only the run's processes ending, once, may follow lost"
      private_constant(:NEEDS, :AFTER_FINAL)

      def self.broken(fact, earlier)
        needed, message = NEEDS[fact.class]
        message unless public_send(needed, earlier)
      end

      def self.after_final(fact, earlier)
        AFTER_FINAL unless fact.is_a?(ProcessesEnded) && earlier.any?(Lost) && earlier.none?(ProcessesEnded)
      end

      def self.passed?(earlier)
        earlier.any? { |fact| fact.is_a?(CommandEnded) && fact.exited_zero? } &&
          earlier.any?(OutputCompleted) && earlier.any?(ArtifactsKept)
      end

      def self.failed?(earlier)
        short_of_space?(earlier) || (earlier.any?(OutputCompleted) && earlier.any? { |fact| short_of_a_pass?(fact) })
      end

      def self.short_of_space?(earlier)
        earlier.any? { |fact| fact.is_a?(ArtifactsNotKept) && fact.before_command? }
      end

      def self.short_of_a_pass?(fact)
        (fact.is_a?(CommandEnded) && !fact.exited_zero?) || fact.is_a?(ArtifactsNotKept)
      end

      def self.started?(earlier)
        earlier.any?(CommandStarted)
      end

      def self.canceled?(earlier)
        earlier.any?(CancelAsked)
      end

      def self.placed?(earlier)
        earlier.any?(Placed)
      end
    end
    private_constant(:Endings)

    # @dynamic ==, cancel_asked?, ending, eql?, facts, hash, holds_resources?, id, initialize, placement, queued, state
    # @dynamic version, with_fact
  end
end

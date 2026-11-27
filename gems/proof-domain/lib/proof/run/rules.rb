# frozen_string_literal: true

# The tables below name the facts while the file loads, so the file loads them first.
require_relative("endings")
require_relative("facts")

module Proof
  # steep:ignore:start
  class Run
    # steep:ignore:end
    module Rules
      MESSAGES = {
        first: "a run's first fact, and only its first, is that it was queued",
        artifacts_once: "a run's artifacts are kept or not kept once",
        short_of_space: "a run's artifacts go unkept for space only after it is placed and before its command starts",
        after_command: "a run's artifacts are kept, or not kept for a reason other than space, " \
          "only after its command ends",
      }.freeze
      # @type var order: Hash[Class, [Class, String]]
      order = {
        Placed => [Queued, "a run is placed once"],
        CommandStarted => [Placed, "a run's command starts once, after the run is placed"],
        CommandEnded => [CommandStarted, "a run's command ends once, after it starts"],
        OutputCompleted => [CommandEnded, "a run's whole output arrives once, after its command ends"],
        CancelAsked => [Queued, "a cancel is asked for once"],
        ProcessesEnded => [Lost, "a run's processes end as a fact only after the run is lost"],
      }
      ORDER = order.freeze
      private_constant(:MESSAGES, :ORDER)

      def self.broken(facts)
        facts.each_with_index.lazy.filter_map { |fact, index| broken_by(fact, facts.take(index)) }
          .first
      end

      def self.broken_by(fact, earlier)
        return MESSAGES[:first] unless earlier.empty? == fact.is_a?(Queued)
        return Endings.after_final(fact, earlier) if earlier.any?(Final)

        following(fact, earlier)
      end

      def self.following(fact, earlier)
        case fact
        when Queued then nil
        when Final then Endings.broken(fact, earlier)
        when ArtifactsKept, ArtifactsNotKept then artifacts(fact, earlier)
        else ordered(fact, earlier)
        end
      end

      def self.ordered(fact, earlier)
        kind = fact.class
        needed, message = ORDER[kind]
        message if earlier.any?(kind) || earlier.none?(needed)
      end

      def self.artifacts(fact, earlier)
        return MESSAGES[:artifacts_once] if earlier.any?(ArtifactsKept) || earlier.any?(ArtifactsNotKept)
        return short_of_space(earlier) if fact.is_a?(ArtifactsNotKept) && fact.before_command?

        MESSAGES[:after_command] if earlier.none?(CommandEnded)
      end

      def self.short_of_space(earlier)
        MESSAGES[:short_of_space] if earlier.none?(Placed) || earlier.any?(CommandStarted)
      end
      private_class_method(:broken_by, :following, :ordered, :artifacts, :short_of_space)
    end
    private_constant(:Rules)

    # Steep wants every opening of a class to define all the methods that the signature declares for it, and this
    # file opens Run only to hold a module.
  end
end

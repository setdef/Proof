# frozen_string_literal: true

require_relative("run/endings")
require_relative("run/facts")
require_relative("run/rules")

module Proof
  # steep:ignore:start
  class Run
    # steep:ignore:end
    FINAL_STATES = {
      Succeeded => :succeeded,
      Failed => :failed,
      TimedOut => :timed_out,
      OutOfMemory => :out_of_memory,
      Canceled => :canceled,
      Lost => :lost,
    }.freeze
    public_constant(:FINAL_STATES)

    attr_reader :id, :facts, :queued

    def initialize(id:, facts:)
      raise(InvalidRunError, format("a run's ID is a Proof::RunId, not %p", id)) unless id.is_a?(RunId)

      broken = Rules.broken(Fact.listed(facts))
      raise(InvalidRunError, "run #{id} breaks a rule: #{broken}") if broken

      @id = id
      @facts = facts.dup.freeze
      # The rules put the fact that the run was queued first and only there, and the check tells Steep its class.
      facts.each { |fact| @queued = fact if fact.is_a?(Queued) }
    end

    def ==(other)
      case other
      when Run then id == other.id
      else false
      end
    end
    alias eql? ==

    def hash
      [Run, id].hash
    end

    def with_fact(fact)
      Run.new(id:, facts: [*facts, fact])
    end

    def version
      facts.size
    end

    def placement
      facts.each { |fact| return fact if fact.is_a?(Placed) }
      nil
    end

    def ending
      # Steep finds nothing in common between the modules Fact and Final, which the final facts include both of.
      # steep:ignore:start
      facts.each { |fact| return fact if fact.is_a?(Final) }
      # steep:ignore:end
      nil
    end

    def state
      final = ending
      return FINAL_STATES[final.class] if final

      placement ? :running : :queued
    end

    def cancel_asked?
      facts.any?(CancelAsked)
    end

    def holds_resources?
      case state
      when :running then true
      when :lost then facts.none?(ProcessesEnded)
      else false
      end
    end
  end
end

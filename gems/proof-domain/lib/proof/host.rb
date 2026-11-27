# frozen_string_literal: true

require_relative("member_check")
require_relative("name")
require_relative("resources")
require_relative("room")
require_relative("runner")

module Proof
  class Host < Data.define(:name, :share, :person_active, :runners)
    # @type var rules: Hash[Symbol, [String, MemberCheck::rule]]
    rules = {
      name: [Name.message("a host's name", "nuc"), MemberCheck.method(:named?)],
      share: ["a host's share is resources, not %p", Resources.method(:===)],
      person_active: ["whether a person is active is true or false, not %p", MemberCheck.method(:flag?)],
      runners: ["a host's runners are a list of runners with different names, not %p", Runner.method(:listed?)],
    }
    RULES = rules.freeze
    private_constant(:RULES)

    def initialize(name:, share:, person_active:, runners:)
      problem = MemberCheck.problem(RULES, { name:, share:, person_active:, runners: })
      raise(InvalidHostError, problem) if problem

      super(name: -name, share:, person_active:, runners: runners.dup.freeze)
    end

    def capacity
      Room.capacity(runners)
    end

    def spots
      runners.map { |runner| [self, runner] }
    end

    def holding(runs, names = runners.map(&:name))
      runs.select { |run| run.placement&.on?(name, names) }
    end

    def free_on(runner, runs)
      Room.free(capacity, holding(runs), kept).least(Room.free(runner.capacity, holding(runs, [runner.name])))
    end

    def ever_on(runner)
      runner.capacity.least(capacity.minus(memory_share))
    end

    def kept
      person_active ? share : memory_share
    end

    private def memory_share
      share.with(cpus: 0)
    end

    # @dynamic name, share, person_active, runners
  end
end

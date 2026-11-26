# frozen_string_literal: true

require_relative("capacity")
require_relative("member_check")
require_relative("runner")

module Proof
  class Host < Data.define(:name, :share, :person_active, :runners)
    RULES = {
      name: ["a host's name is a name, not %p", MemberCheck.method(:named?)],
      share: ["a host's share is resources, not %p", -> (value) { value.is_a?(Resources) }],
      person_active: ["whether a person is active is true or false, not %p", MemberCheck.method(:flag?)],
      runners: ["a host's runners are a list of runners with different names, not %p", Runner.method(:listed?)],
    }.freeze
    private_constant(:RULES)

    def initialize(name:, share:, person_active:, runners:)
      problem = MemberCheck.problem(RULES, { name:, share:, person_active:, runners: })
      raise(InvalidHostError, problem) if problem

      super(name: -name, share:, person_active:, runners: runners.dup.freeze)
    end

    def capacity
      Capacity.most(runners.map(&:capacity))
    end

    def holding(runs, names = runners.map(&:name))
      runs.select { |run| run.placement&.on?(name, names) }
    end

    def free_on(runner, runs)
      on_host = Capacity.free(capacity, holding(runs), kept)
      Capacity.least(on_host, Capacity.free(runner.capacity, holding(runs, [runner.name])))
    end

    def ever_on(runner)
      Capacity.least(runner.capacity, Capacity.free(capacity, [], memory_share))
    end

    def kept
      person_active ? share : memory_share
    end

    private def memory_share
      Resources.new(cpus: 0, megabytes: share.megabytes)
    end
  end
end

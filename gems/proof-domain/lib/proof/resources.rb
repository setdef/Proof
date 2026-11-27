# frozen_string_literal: true

require_relative("size")
require_relative("size_text")

module Proof
  # steep:ignore:start
  class Resources < Data.define(:cpus, :megabytes)
    # steep:ignore:end
    MEMORY_MESSAGE = "memory is a size: a number, whole or decimal, an optional space, and MB, GB, TB, " \
      "MiB, GiB, or TiB in any case, such as \"512MB\", \"8 GB\", \"1.5gib\", or \"0.5TB\", not %p"
    # @type var rules: Hash[Symbol, [String, MemberCheck::rule]]
    rules = {
      cpus: ["cpus is a whole number from 0, not %p", -> (value) { MemberCheck.whole?(value, 0) }],
      megabytes: ["megabytes is a whole number from 0, not %p", -> (value) { MemberCheck.whole?(value, 0) }],
    }
    RULES = rules.freeze
    private_constant(:MEMORY_MESSAGE, :RULES)

    def self.request(cpus:, memory:)
      raise(InvalidResourcesError, format("cpus is a whole number from 1, not %p", cpus)) unless
        MemberCheck.whole?(cpus, 1)

      megabytes = SizeText.megabytes(memory)
      raise(InvalidResourcesError, format(MEMORY_MESSAGE, memory)) unless megabytes

      new(cpus:, megabytes:)
    end

    def self.none
      new(cpus: 0, megabytes: 0)
    end

    def self.share(cpus:, memory:)
      size = Size.read(memory, name: "share memory")
      raise(InvalidResourcesError, format("share cpus is a whole number from 0, not %p", cpus)) unless
        MemberCheck.whole?(cpus, 0)

      new(cpus:, megabytes: size.megabytes)
    end

    def initialize(cpus:, megabytes:)
      problem = MemberCheck.problem(RULES, { cpus:, megabytes: })
      raise(InvalidResourcesError, problem) if problem

      super
    end

    def fits_within?(available)
      cpus <= available.cpus && megabytes <= available.megabytes
    end

    def minus(taken)
      combine(taken) { |have, take| [have - take, 0].max }
    end

    def least(other)
      combine(other) { |one, two| [one, two].min }
    end

    def most(other)
      combine(other) { |one, two| [one, two].max }
    end

    private def combine(other)
      Resources.new(cpus: yield(cpus, other.cpus), megabytes: yield(megabytes, other.megabytes))
    end
  end
end

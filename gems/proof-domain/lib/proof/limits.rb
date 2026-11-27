# frozen_string_literal: true

require_relative("member_check")
require_relative("size")

module Proof
  # steep:ignore:start
  class Limits < Data.define(:output, :artifacts)
    # steep:ignore:end
    RULES = MemberCheck.rules(
      output: ["limits output is a size, not %p", Size.method(:===)],
      artifacts: ["limits artifacts is a size, not %p", Size.method(:===)]
    )
    private_constant(:RULES)

    def initialize(output: Size.new(megabytes: 1024), artifacts: Size.new(megabytes: 16 * 1024))
      problem = MemberCheck.problem(RULES, { output:, artifacts: })
      raise(InvalidLimitsError, problem) if problem

      super
    end
  end
end

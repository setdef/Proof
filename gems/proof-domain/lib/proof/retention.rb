# frozen_string_literal: true

require_relative("duration")
require_relative("member_check")

module Proof
  # steep:ignore:start
  class Retention < Data.define(:runs, :output, :artifacts)
    # steep:ignore:end
    DAY = 86_400
    WHOLE_DAYS = -> (value) { value.is_a?(Duration) && (value.seconds % DAY).zero? }
    RULES = {
      runs: ["retention runs is a duration in whole days, not %p", WHOLE_DAYS],
      output: ["retention output is a duration in whole days, not %p", WHOLE_DAYS],
      artifacts: ["retention artifacts is a duration in whole days, not %p", WHOLE_DAYS],
    }.freeze
    private_constant(:DAY, :WHOLE_DAYS, :RULES)

    def initialize(
      runs: Duration.new(seconds: 90 * DAY),
      output: Duration.new(seconds: 14 * DAY),
      artifacts: Duration.new(seconds: 7 * DAY)
    )
      problem = MemberCheck.problem(RULES, { runs:, output:, artifacts: })
      raise(InvalidRetentionError, problem) if problem

      super
    end
  end
end

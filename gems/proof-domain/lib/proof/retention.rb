# frozen_string_literal: true

require_relative("duration")
require_relative("member_check")

module Proof
  class Retention < Data.define(:runs, :output, :artifacts)
    DAY = 86_400
    WHOLE_DAYS = -> (value) { value.is_a?(Duration) && (value.seconds % DAY).zero? }
    # @type var rules: Hash[Symbol, [String, MemberCheck::rule]]
    rules = {
      runs: ["retention runs is a duration in whole days, not %p", WHOLE_DAYS],
      output: ["retention output is a duration in whole days, not %p", WHOLE_DAYS],
      artifacts: ["retention artifacts is a duration in whole days, not %p", WHOLE_DAYS],
    }
    RULES = rules.freeze
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

    # @dynamic runs, output, artifacts
  end
end

# frozen_string_literal: true

require_relative("member_check")
require_relative("size")

module Proof
  class Limits < Data.define(:output, :artifacts)
    # @type var rules: Hash[Symbol, [String, MemberCheck::rule]]
    rules = {
      output: ["limits output is a size, not %p", Size.method(:===)],
      artifacts: ["limits artifacts is a size, not %p", Size.method(:===)],
    }
    RULES = rules.freeze
    private_constant(:RULES)

    def initialize(output: Size.new(megabytes: 1024), artifacts: Size.new(megabytes: 16 * 1024))
      problem = MemberCheck.problem(RULES, { output:, artifacts: })
      raise(InvalidLimitsError, problem) if problem

      super
    end

    # @dynamic output, artifacts
  end
end

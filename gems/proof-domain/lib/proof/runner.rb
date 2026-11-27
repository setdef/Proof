# frozen_string_literal: true

require_relative("member_check")
require_relative("name")

module Proof
  # steep:ignore:start
  class Runner < Data.define(:name, :os, :labels, :capacity, :connected)
    # steep:ignore:end
    RULES = MemberCheck.rules(
      name: [Name.message("a runner's name", "nuc-linux"), MemberCheck.method(:named?)],
      os: ["a runner's OS is a Proof::OS, not %p", OS.method(:===)],
      labels: ["a runner's labels are a set of labels, not %p", LabelSet.method(:===)],
      capacity: ["a runner's capacity is resources, not %p", Resources.method(:===)],
      connected: ["whether a runner is connected is true or false, not %p", MemberCheck.method(:flag?)]
    )
    private_constant(:RULES)

    def self.listed?(given)
      return false unless given.is_a?(Array) && given.all?(Runner)

      names = given.map(&:name)
      names.uniq.size == names.size
    end

    def initialize(name:, os:, labels:, capacity:, connected:)
      problem = MemberCheck.problem(RULES, { name:, os:, labels:, capacity:, connected: })
      raise(InvalidRunnerError, problem) if problem

      super(name: -name, os:, labels:, capacity:, connected:)
    end

    def takes?(queued)
      queued.os.include?(os) && labels.offers_every_label_of?(queued.labels)
    end
  end
end

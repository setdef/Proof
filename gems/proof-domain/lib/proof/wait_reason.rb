# frozen_string_literal: true

require_relative("wait_check")

module Proof
  class WaitReason < Data.define(:kind, :hosts, :runs)
    KINDS = %i[behind_runs person_active no_runner_connected no_label].freeze
    public_constant(:KINDS)

    def self.all(queued, hosts, holding)
      found = queued.filter_map do |run|
        reason = of(run.queued, hosts, holding)
        [run.id, reason] if reason
      end
      found.to_h
    end

    def self.of(queued, hosts, holding)
      verdicts = WaitCheck.verdicts(queued, hosts, holding)
      return if verdicts.key?(:fits)

      kind = WaitCheck.nearest(verdicts)
      new(
        kind:,
        hosts: verdicts.fetch(kind, []).map(&:name),
        # Runs are in the way only when they are the nearest reason, so this is empty for every other kind.
        runs: WaitCheck.holders(verdicts.fetch(:behind_runs, []), holding)
      )
    end

    def initialize(kind:, hosts: [], runs: [])
      raise(InvalidWaitReasonError, format("a wait reason is one of #{KINDS.join(', ')}, not %p", kind)) unless
        KINDS.include?(kind)

      super(kind:, hosts: hosts.dup.freeze, runs: runs.dup.freeze)
    end
  end
end

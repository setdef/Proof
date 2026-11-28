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

      kind = nearest(verdicts)
      new(
        kind:,
        hosts: verdicts.fetch(kind, []).map(&:name),
        # Runs are in the way only when they are the nearest reason, so this is empty for every other kind.
        runs: holders(verdicts.fetch(:behind_runs, []), holding)
      )
    end

    def initialize(kind:, hosts: [], runs: [])
      raise(InvalidWaitReasonError, format("a wait reason is one of #{KINDS.join(', ')}, not %p", kind)) unless
        KINDS.include?(kind)

      super(kind:, hosts: hosts.dup.freeze, runs: runs.dup.freeze)
    end

    def self.nearest(verdicts)
      KINDS.find { |kind| verdicts.key?(kind) } || :no_runner_connected
    end
    private_class_method(:nearest)

    def self.holders(hosts, holding)
      # A run is placed on one host, so no run is here twice.
      held = hosts.flat_map { |host| host.holding(holding) }
      held.sort_by! { |run| run.queued.position }
      held.map(&:id)
    end
    private_class_method(:holders)

    # @dynamic kind, hosts, runs
  end
end

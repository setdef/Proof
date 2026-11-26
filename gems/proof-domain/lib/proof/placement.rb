# frozen_string_literal: true

require_relative("runner_choice")
require_relative("wait_reason")

module Proof
  class Placement
    def initialize(runs:, hosts:, clock:)
      @runs = runs
      @hosts = hosts
      @clock = clock
    end

    def place_next
      found = RunnerChoice.first(@runs.queued, @hosts.hosts, @runs.holding_resources)
      place(*found) if found
    end

    def wait_reasons
      WaitReason.all(@runs.queued, @hosts.hosts, @runs.holding_resources)
    end

    private def place(run, host, runner)
      placed = Run::Placed.new(at: @clock.now, host: host.name, runner: runner.name)
      @runs.append(run.id, placed, version: run.version)
    end
  end
end

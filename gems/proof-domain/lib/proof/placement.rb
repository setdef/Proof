# frozen_string_literal: true

require_relative("closest_host")
require_relative("runner_choice")
require_relative("shortfall")
require_relative("wait_reason")

module Proof
  class Placement
    def initialize(runs:, hosts:, clock:)
      @runs = runs
      @hosts = hosts
      @clock = clock
    end

    def place_next
      found = RunnerChoice.first(queue, @hosts.hosts, @runs.holding_resources)
      place(found) if found
    end

    def check(queued)
      closest = ClosestHost.of(queued, @hosts.hosts)
      raise(ClosestHost.refusal(closest, queued.resources)) if closest
    end

    def wait_reasons
      WaitReason.all(queue, @hosts.hosts, @runs.holding_resources)
    end

    private def queue
      # A run whose cancel was asked for ends canceled with no runner, so it is never placed and waits behind nothing.
      @runs.queued.reject(&:cancel_asked?)
    end

    private def place(chosen)
      run, host, runner = chosen
      placed = Run::Placed.new(at: @clock.now, host: host.name, runner: runner.name)
      @runs.append(run.id, placed, version: run.version)
    end
  end
end

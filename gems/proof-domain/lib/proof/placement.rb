# frozen_string_literal: true

module Proof
  class Placement
    def self.first(queued, hosts, holding)
      queued.each do |run|
        found = spot(run.queued, hosts, holding)
        return [run, *found] if found
      end
      nil
    end

    def self.spot(queued, hosts, holding)
      fitting = hosts.flat_map(&:spots).select { |spot| fits?(queued, spot, holding) }
      # The emptiest runner goes first, so runs spread out and each host keeps the most room for a person.
      fitting.min_by { |spot| emptiest_first(spot, holding) }
    end

    def self.fits?(queued, spot, holding)
      host, runner = spot
      runner.connected && runner.takes?(queued) && queued.resources.fits_within?(host.free_on(runner, holding))
    end

    def self.emptiest_first(spot, holding)
      host, runner = spot
      free = host.free_on(runner, holding)
      [-free.megabytes, -free.cpus, runner.name]
    end

    def initialize(runs:, hosts:, clock:)
      @runs = runs
      @hosts = hosts
      @clock = clock
    end

    def place_next
      found = Placement.first(@runs.queued, @hosts.hosts, @runs.holding_resources)
      place(*found) if found
    end

    private def place(run, host, runner)
      placed = Run::Placed.new(at: @clock.now, host: host.name, runner: runner.name)
      @runs.append(run.id, placed, version: run.version)
    end
  end
end

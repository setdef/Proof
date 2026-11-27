# frozen_string_literal: true

module Proof
  module RunnerChoice
    def self.first(queued, hosts, holding)
      queued.each do |run|
        found = best(run.queued, hosts, holding)
        return chosen(run, found) if found
      end
      nil
    end

    def self.chosen(run, pair)
      # Steep reads a splat in an Array literal as a list, so the three are named here, where it can see the tuple.
      host, runner = pair
      [run, host, runner]
    end

    def self.best(queued, hosts, holding)
      fitting = hosts.flat_map(&:spots).select { |pair| fits?(queued, pair, holding) }
      # The emptiest runner goes first, so runs spread out and each host keeps the most room for a person.
      fitting.min_by { |pair| emptiest_first(pair, holding) }
    end

    def self.fits?(queued, pair, holding)
      host, runner = pair
      runner.connected && runner.takes?(queued) && queued.resources.fits_within?(host.free_on(runner, holding))
    end

    def self.emptiest_first(pair, holding)
      host, runner = pair
      free = host.free_on(runner, holding)
      [-free.megabytes, -free.cpus, runner.name, host.name]
    end
  end
  private_constant(:RunnerChoice)
end

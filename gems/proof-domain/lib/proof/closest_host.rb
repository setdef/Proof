# frozen_string_literal: true

module Proof
  module ClosestHost
    def self.of(queued, hosts)
      resources = queued.resources
      pairs = hosts.flat_map(&:spots).select { |_host, runner| runner.takes?(queued) }
      closest(pairs, resources) if pairs.none? { |host, runner| resources.fits_within?(host.ever_on(runner)) }
    end

    def self.closest(pairs, resources)
      # The pair whose worst shortfall is the smallest, so a surplus of one resource can't hide the lack of another.
      pairs.min_by { |pair| [-worst(pair, resources), pair.last.name] }
    end

    def self.refusal(pair, resources)
      host, runner = pair
      RunFitsNoHostError.new(host: host.name, shortfalls: Shortfall.of(host.ever_on(runner), resources))
    end

    def self.worst(pair, resources)
      host, runner = pair
      # Nothing short is a whole fraction, 1, which every pair weighed here is below.
      [1, *Shortfall.of(host.ever_on(runner), resources).map(&:fraction)].min
    end
  end
  private_constant(:ClosestHost)
end

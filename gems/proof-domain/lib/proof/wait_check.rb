# frozen_string_literal: true

module Proof
  module WaitCheck
    def self.verdicts(queued, hosts, holding)
      grouped = pairs_of(queued, hosts).group_by { |pair| verdict(queued, pair, holding) }
      grouped.transform_values { |found| hosts_of(found) }
    end

    def self.pairs_of(queued, hosts)
      hosts.flat_map(&:spots).select { |_host, runner| queued.os.include?(runner.os) }
    end

    def self.hosts_of(pairs)
      by_name = pairs.to_h { |host, _runner| [host.name, host] }
      by_name.values
    end

    def self.nearest(verdicts)
      WaitReason::KINDS.find { |kind| verdicts.key?(kind) } || :no_runner_connected
    end

    def self.verdict(queued, pair, holding)
      host, runner = pair
      resources = queued.resources
      return :no_label unless runner.labels.offers_every_label_of?(queued.labels)
      return :no_runner_connected unless runner.connected && resources.fits_within?(host.ever_on(runner))

      in_the_way(resources, pair, holding)
    end

    def self.in_the_way(resources, pair, holding)
      host, runner = pair
      return :fits if resources.fits_within?(host.free_on(runner, holding))

      # It could fit this runner some time, so either the runs on its host or the person there are in the way.
      resources.fits_within?(host.free_on(runner, [])) ? :behind_runs : :person_active
    end

    def self.holders(hosts, holding)
      # A run is placed on one host, so no run is here twice.
      held = hosts.flat_map { |host| host.holding(holding) }
      held.sort_by! { |run| run.queued.position }
      held.map(&:id)
    end
  end
  private_constant(:WaitCheck)
end

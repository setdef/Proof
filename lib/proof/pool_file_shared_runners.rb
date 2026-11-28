# frozen_string_literal: true

module Proof
  class PoolFileSharedRunners
    def initialize(hosts, refusal:)
      @hosts = hosts
      @refusal = refusal
      @seen = []
    end

    def check
      @seen.clear
      @hosts.each { |host| check_host(host) }
    end

    private def check_host(host)
      host.pairs_named("runner").each { |pair| check_runner(host, pair) }
    end

    private def check_runner(host, pair)
      runner, child = pair
      repeat = Name.first_repeat(@seen.map(&:first) + [runner])
      return @seen << [runner, host] unless repeat

      # The runners seen repeat none, so the runner repeats the one at the position first_repeat found.
      _, earlier = @seen[repeat.first] #: [kdl_value, KdlNode]
      # A runner twice on one host is the host entry's mistake.
      @refusal.shared_runner(child, runner, earlier) unless earlier.equal?(host)
    end
  end
end

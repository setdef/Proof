# frozen_string_literal: true

module Proof
  class PoolFileSharedRunners
    def initialize(hosts, refusal:)
      @hosts = hosts
      @refusal = refusal
    end

    def check
      @hosts.each_with_index { |host, index| refuse_in(host, index) }
    end

    private def refuse_in(host, index)
      host.pairs_named("runner").each { |runner, child| refuse_listed(child, runner, index) }
    end

    private def refuse_listed(child, runner, index)
      first = @hosts.take(index).find { |host| PoolFileNames.among?(host.arguments_named("runner"), runner) }
      @refusal.shared_runner(child, runner, first) if first
    end
  end
end

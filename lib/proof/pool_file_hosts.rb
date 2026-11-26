# frozen_string_literal: true

module Proof
  class PoolFileHosts
    def initialize(refusal:)
      @refusal = refusal
      @names = PoolFileNames.new(refusal:)
    end

    def read(by_name)
      defaults = by_name[:defaults]&.first
      settings = defaults ? host(defaults).settings : HostSettings.new
      { defaults: settings, hosts: by_name[:host].to_a.map { |node| entry(node, settings) } }
    end

    private def host(node)
      PoolFileHost.new(node:, refusal: @refusal, names: @names)
    end

    private def entry(node, defaults)
      # The entry is resolved only to refuse a host with no budget, and the value is the entry.
      @refusal.checking(node) { host(node).entry.tap { |host| host.resolved(defaults) } }
    end
  end
end

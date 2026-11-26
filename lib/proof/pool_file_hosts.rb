# frozen_string_literal: true

module Proof
  class PoolFileHosts
    def initialize(refusal:)
      @refusal = refusal
      @names = PoolFileNames.new(refusal:)
    end

    def read(by_name)
      defaults = by_name[:defaults]&.first
      settings = defaults ? settings_for(defaults).settings : HostSettings.new
      { defaults: settings, hosts: by_name[:host].to_a.map { |node| entry(node, settings) } }
    end

    private def settings_for(node)
      PoolFileSettings.new(node:, refusal: @refusal)
    end

    private def entry(node, defaults)
      @names.refuse(node, "a host's name", node.arguments.first)
      @names.refuse_children(node, "runner", "a runner's name")
      # The entry is resolved only to refuse a host with no budget, and the value is the entry.
      @refusal.checking(node) { settings_for(node).entry.tap { |host| host.resolved(defaults) } }
    end
  end
end

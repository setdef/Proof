# frozen_string_literal: true

module Proof
  class PoolFileHosts
    BLANK = -> (value) { value.is_a?(String) && value.match?(/\A[[:space:]]*\z/) }
    private_constant(:BLANK)

    def initialize(refusal:)
      @refusal = refusal
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
      refuse_blanks(node)
      # The entry is resolved only to refuse a host with no budget, and the value is the entry.
      @refusal.checking(node) { settings_for(node).entry.tap { |host| host.resolved(defaults) } }
    end

    private def refuse_blanks(node)
      refuse_blank(node, "a host's name", node.arguments.first)
      node.named("runner").each { |child| refuse_blank_in(child, "a runner's name") }
    end

    private def refuse_blank_in(node, what)
      node.arguments.each { |value| refuse_blank(node, what, value) }
    end

    private def refuse_blank(node, what, value)
      @refusal.blank_name(node, what, value) if BLANK.call(value)
    end
  end
end

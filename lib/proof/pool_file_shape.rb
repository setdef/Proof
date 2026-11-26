# frozen_string_literal: true

module Proof
  class PoolFileShape
    USAGES = {
      server: "server port=7443",
      retention: "retention runs=\"90d\" output=\"14d\" artifacts=\"7d\"",
      limits: "limits output=\"1GB\" artifacts=\"16GB\"",
    }.freeze
    PROPERTIES = { server: %i[port], retention: %i[runs output artifacts], limits: %i[output artifacts] }.freeze
    LISTED = lambda do |names|
      # Two names take "and" with no comma, and three or more take a serial comma.
      (names.size < 3) ? names.join(" and ") : "#{names.first(names.size - 1).join(', ')}, and #{names.last}"
    end
    private_constant(:USAGES, :PROPERTIES, :LISTED)

    def initialize(refusal:)
      @refusal = refusal
    end

    def check(node)
      key = node.name.to_sym
      refuse_arguments(node, USAGES[key])
      refuse_stray_property(node, PROPERTIES[key])
      refuse_children(node)
    end

    private def refuse_arguments(node, usage)
      count = node.arguments.size
      @refusal.node_arguments(node, usage, count) if count.nonzero?
    end

    private def refuse_stray_property(node, known)
      stray = node.properties.each_key.find { |name| !known.include?(name.to_sym) }
      @refusal.unknown_property(node, stray, LISTED.call(known)) if stray
    end

    private def refuse_children(node)
      node.children.each { |child| @refusal.no_children(node, child) }
    end
  end
end

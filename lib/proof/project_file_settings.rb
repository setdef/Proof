# frozen_string_literal: true

module Proof
  class ProjectFileSettings
    MEMBERS = {
      cpus: :cpus,
      memory: :megabytes,
      timeout: :time_limit,
      os: :os,
      label: :labels,
      artifact: :artifacts,
      cache: :caches,
    }.freeze
    BUILDERS = {
      cpus: -> (node) { Resources.request(cpus: node.properties["cpus"], memory: "0MB").cpus },
      memory: -> (node) { Resources.request(cpus: 1, memory: node.properties["memory"]).megabytes },
      timeout: -> (node) { TimeLimit.read(node.properties["timeout"]) },
      os: -> (child) { child.arguments.map { |name| OS.new(name:) } },
      label: -> (child) { LabelSet.of(*child.arguments) },
      artifact: -> (child) { child.arguments.map { |path| PathPattern.new(path:) } },
      cache: -> (child) { child.arguments.map { |path| PathPattern.new(path:) } },
    }.freeze
    private_constant(:MEMBERS, :BUILDERS)

    def initialize(refusal:)
      @refusal = refusal
    end

    def read(node)
      # Every value is built and checked here, so TaskSettings has nothing left to refuse.
      TaskSettings.new(**properties_of(node), **children_of(node.children))
    end

    private def properties_of(node)
      # A property's value is refused at the line of its node.
      node.properties.to_h { |name, _value| pair(name, node) }
    end

    private def children_of(children)
      children.to_h { |child| pair(child.name, child) }
    end

    private def pair(name, giver)
      key = name.to_sym
      [MEMBERS[key], @refusal.checking(giver) { BUILDERS[key].call(giver) }]
    end
  end
end

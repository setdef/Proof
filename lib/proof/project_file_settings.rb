# frozen_string_literal: true

module Proof
  class ProjectFileSettings
    PATHS = -> (child) { child.arguments.map { |path| PathPattern.new(path:) } }
    # @type var table: Hash[Symbol, KdlMembers::entry]
    table = {
      cpus: [:cpus, -> (node) { Resources.request(cpus: node.properties["cpus"], memory: "0MB").cpus }],
      memory: [:megabytes, -> (node) { Resources.request(cpus: 1, memory: node.properties["memory"]).megabytes }],
      timeout: [:time_limit, -> (node) { TimeLimit.read(node.properties["timeout"]) }],
      os: [:os, -> (child) { child.arguments.map { |name| OS.new(name:) } }],
      label: [:labels, -> (child) { LabelSet.of(*child.arguments) }],
      artifact: [:artifacts, PATHS],
      cache: [:caches, PATHS],
    }
    TABLE = table.freeze
    private_constant(:PATHS, :TABLE)

    def initialize(refusal:)
      @members = KdlMembers.new(TABLE, refusal:)
    end

    def read(node)
      # Every value is built and checked here, so TaskSettings has nothing left to refuse.
      TaskSettings.new(**@members.of_properties(node), **@members.of_children(node))
    end
  end
end

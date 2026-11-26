# frozen_string_literal: true

module Proof
  class ProjectFileReader
    PATH = ".config/proof.kdl"
    NODES = %w[defaults task].freeze
    public_constant(:PATH)
    private_constant(:NODES)

    def self.read(text, path: PATH)
      new(path:).read(text)
    end

    def initialize(path:)
      @path = path
      @refusal = ProjectFileRefusal.new(path:)
      @settings = ProjectFileSettings.new(refusal: ProjectFileSettingsRefusal.new(path:))
      @tasks = TaskReader.new(refusal: @refusal, settings: @settings)
    end

    def read(text)
      by_name = KdlParser.parse(text, path: @path).group_by(&:name)
      by_name.each { |name, nodes| @refusal.unknown_node(nodes.first) unless NODES.include?(name) }
      ProjectFile.new(defaults: defaults_in(by_name["defaults"]), entries: @tasks.read_all(by_name.fetch("task", [])))
    end

    private def defaults_in(nodes)
      first, second = nodes
      @refusal.repeated_defaults(second, first) if first && second
      first ? defaults_settings(first) : TaskSettings.none
    end

    private def defaults_settings(node)
      @refusal.defaults_arguments(node) unless node.arguments.empty?
      @settings.read(node)
    end
  end
end

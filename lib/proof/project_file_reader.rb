# frozen_string_literal: true

module Proof
  class ProjectFileReader
    PATH = ".config/proof.kdl"
    NODES = %w[defaults task].freeze
    public_constant(:PATH)
    LINK_REASON = "this is a symbolic link, and Proof reads only a regular file there. " \
      "Replace it with a file that holds the project file's text"
    private_constant(:NODES, :LINK_REASON)

    def self.read(text, path: PATH)
      new(path:).read(text)
    end

    def self.read_from(project, id, path: PATH)
      new(path:).read_from(project, id)
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

    def read_from(project, id)
      text = project.file_at(id, @path)
      read(text) if text
    rescue SymbolicLinkError
      # The commit's file at the path is the project file, so a link there is that file's mistake, which a person
      # fixes in the file.
      raise(ProjectFileError.new(path: @path, line: nil, reason: LINK_REASON))
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

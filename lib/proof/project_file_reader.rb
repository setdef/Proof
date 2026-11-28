# frozen_string_literal: true

module Proof
  class ProjectFileReader
    PATH = ".config/proof.kdl"
    public_constant(:PATH)
    LINK_REASON = "this is a symbolic link, and Proof reads only a regular file there. " \
      "Replace it with a file that holds the project file's text"
    private_constant(:LINK_REASON)

    def self.read(text, path: PATH)
      new(path:).read(text)
    end

    def self.read_from(project, id, path: PATH)
      new(path:).read_from(project, id)
    end

    attr_reader(:file)

    def initialize(path:)
      @file = KdlFile.new(path:, error: ProjectFileError, forms: ProjectFileForms, messages: ProjectFileRefusal::MESSAGES)
      @refusal = @file.refusal(ProjectFileRefusal)
      @settings = ProjectFileSettings.new(refusal: @refusal)
    end

    def read(text)
      by_name = @file.nodes_by_name(text, refusal: @refusal)
      ProjectFile.new(defaults: defaults_of(by_name[:defaults]&.first), entries: tasks_of(by_name.fetch(:task, [])))
    end

    def read_from(project, id)
      read_at(project, id, @file.path)
    end

    private def read_at(project, id, path)
      text = project.file_at(id, path)
      read(text) if text
    rescue SymbolicLinkError
      # The commit's file at the path is the project file, so a link there is that file's mistake, which a person
      # fixes in the file.
      raise(@file.error.new(path:, line: nil, reason: LINK_REASON))
    end

    private def defaults_of(node)
      node ? @settings.read(node) : TaskSettings.none
    end

    private def tasks_of(nodes)
      TaskReader.new(refusal: @refusal, settings: @settings).read_all(nodes)
    end

    # @dynamic file
  end
end

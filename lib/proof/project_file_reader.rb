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

    def initialize(path:)
      @path = path
      @refusal = ProjectFileRefusal.new(path:)
      @settings = ProjectFileSettings.new(refusal: @refusal)
    end

    def read(text)
      parsed = KdlParser.parse(text, path: @path, error: ProjectFileError)
      nodes = KdlFormCheck.new(forms: ProjectFileForms, refusal: @refusal).check(parsed)
      by_name = nodes.group_by(&:name)
      ProjectFile.new(defaults: defaults_of(by_name["defaults"]&.first), entries: tasks_of(by_name.fetch("task", [])))
    end

    def read_from(project, id)
      text = project.file_at(id, @path)
      read(text) if text
    rescue SymbolicLinkError
      # The commit's file at the path is the project file, so a link there is that file's mistake, which a person
      # fixes in the file.
      raise(ProjectFileError.new(path: @path, line: nil, reason: LINK_REASON))
    end

    private def defaults_of(node)
      node ? @settings.read(node) : TaskSettings.none
    end

    private def tasks_of(nodes)
      TaskReader.new(refusal: @refusal, settings: @settings).read_all(nodes)
    end
  end
end

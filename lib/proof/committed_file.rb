# frozen_string_literal: true

module Proof
  class CommittedFile
    LINK = "120000"
    LINK_REASON = "this is a symbolic link, and Proof reads only a regular file there. " \
      "Replace it with a file that holds the project file's text"
    private_constant(:LINK, :LINK_REASON)

    def initialize(git:, commit:, path:)
      @git = git
      @commit = commit
      @path = path
    end

    def text
      # ls-tree names the entry's type, so a folder or a submodule at the path is told from a file without reading it.
      mode, type, blob = entry
      # Git stores a link as a blob that holds the link's target, which Proof must not read as the file's text, and
      # the file this class reads is the project file, so a link is that file's mistake.
      raise(ProjectFileError.new(path: @path, line: nil, reason: LINK_REASON)) if mode == LINK

      @git.run("cat-file", "blob", blob.to_s) if type == "blob"
    end

    private def entry
      # A path that names a folder with a slash after it, or "." for the root, makes ls-tree list what is in the folder,
      # so only the line whose name is the path is the entry asked for. -z gives each name as it is stored.
      listed = @git.run("ls-tree", "-z", @commit, "--", @path).split("\0").map { |line| line.split(/[ \t]/, 4) }
      listed.find { |fields| fields.last == @path } || []
    end
  end
end

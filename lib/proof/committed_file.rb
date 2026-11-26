# frozen_string_literal: true

module Proof
  class CommittedFile
    def initialize(git:, commit:, path:)
      @git = git
      @commit = commit
      @path = path
    end

    def text
      # ls-tree names the entry's type, so a folder or a submodule at the path is told from a file without reading it.
      _mode, type, blob = entry
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

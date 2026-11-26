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
      _mode, type, blob = @git.run("ls-tree", @commit, "--", @path).split(/[ \t]/, 4)
      @git.run("cat-file", "blob", blob.to_s) if type == "blob"
    end
  end
end

# frozen_string_literal: true

require "tmpdir"

module Proof
  class WorkingTreeCommit
    IDENTITY = {
      GIT_AUTHOR_NAME: "Proof",
      GIT_AUTHOR_EMAIL: "proof@proof.invalid",
      GIT_COMMITTER_NAME: "Proof",
      GIT_COMMITTER_EMAIL: "proof@proof.invalid",
    }.freeze
    private_constant(:IDENTITY)

    def initialize(git:, head:)
      @git = git
      @head = head
    end

    def id
      Dir.mktmpdir("proof-index") { |folder| commit_tree_of(File.join(folder, "index")) }
    end

    private def commit_tree_of(index)
      # The index lives in a separate file that GIT_INDEX_FILE points to, so the clone's index is never read or
      # written. It starts from HEAD's tree, never empty: git add --all leaves out an ignored file, and an empty
      # index wouldn't know that a tracked file that .gitignore matches is tracked. With no commit there is no
      # HEAD and no tracked file, so it starts empty.
      env = { GIT_INDEX_FILE: index }
      @git.run("read-tree", @head || "--empty", env:)
      @git.run("add", "--all", env:)
      commit(@git.run("write-tree", env:).chomp)
    end

    private def commit(tree)
      parents = [@head].compact.flat_map { |head| ["-p", head] }
      @git.run("commit-tree", tree, *parents, "-m", "Working tree, made by Proof", env: IDENTITY).chomp
    end
  end
end

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
      # index wouldn't know that a tracked file that .gitignore matches is tracked.
      env = { GIT_INDEX_FILE: index }
      @git.run("read-tree", @head, env:)
      stage_working_tree(env)
      tree = @git.run("write-tree", env:).chomp
      @git.run("commit-tree", tree, "-p", @head, "-m", "Working tree, made by Proof", env: IDENTITY).chomp
    end

    private def stage_working_tree(env)
      recorded = submodules(env)
      @git.run("add", "--all", env:)
      pin(recorded, env)
    end

    private def submodules(env)
      entries = @git.run("ls-files", "--stage", "-z", env:).split("\0")
      entries.grep(/\A160000 /).to_h { |entry| [entry.split("\t", 2).last, entry] }
    end

    private def pin(recorded, env)
      # git add --all moves each submodule to whatever commit its checkout is at, which is not a commit the
      # project records, so the submodules still in the index go back to the commit HEAD records.
      lines = recorded.slice(*submodules(env).keys).values.map { |entry| "#{entry}\0" }
      @git.run("update-index", "-z", "--index-info", env:, input: lines.join)
    end
  end
end

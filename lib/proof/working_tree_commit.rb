# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module Proof
  class WorkingTreeCommit
    IDENTITY = {
      GIT_AUTHOR_NAME: "Proof",
      GIT_AUTHOR_EMAIL: "proof@proof.invalid",
      GIT_COMMITTER_NAME: "Proof",
      GIT_COMMITTER_EMAIL: "proof@proof.invalid",
    }.freeze
    CONFIG = [
      %w[GIT_CONFIG_COUNT 2],
      %w[GIT_CONFIG_KEY_0 core.splitIndex],
      %w[GIT_CONFIG_VALUE_0 false],
      %w[GIT_CONFIG_KEY_1 core.fsmonitor],
      %w[GIT_CONFIG_VALUE_1 false],
    ].to_h.transform_keys(&:to_sym).freeze
    private_constant(:IDENTITY, :CONFIG)

    def initialize(git:, head:)
      @git = git
      @head = head
    end

    def id
      Dir.mktmpdir("proof-index") { |folder| commit_tree_of(File.join(folder, "index")) }
    end

    private def commit_tree_of(index)
      # The index lives in a separate file that GIT_INDEX_FILE points to, so the clone's index is never
      # written. It starts as a copy of the clone's index, which knows every tracked file, even one that
      # .gitignore matches, and every file the developer staged, and which holds the files' stat data, so
      # git add --all hashes only what changed. With no index file there is no tracked file, and git add
      # --all makes the index from nothing. The settings keep every file in the clone's .git as it was:
      # core.splitIndex=false makes each command that writes the index write all of it, so the temporary
      # index never refers to a shared index file there, and never adds one; core.fsmonitor=false stops git
      # add from starting a file-system monitor, which would add a socket there and leave a process running.
      env = CONFIG.merge(GIT_INDEX_FILE: index)
      copy_the_clones_index(index)
      @git.run("add", "--all", env:)
      commit(@git.run("write-tree", env:).chomp)
    end

    private def copy_the_clones_index(index)
      clones = @git.run("rev-parse", "--path-format=absolute", "--git-path", "index").chomp
      FileUtils.cp(clones, index) if File.exist?(clones)
    end

    private def commit(tree)
      parents = [@head].compact.flat_map { |head| ["-p", head] }
      @git.run("commit-tree", tree, *parents, "-m", "Working tree, made by Proof", env: IDENTITY).chomp
    end
  end
end

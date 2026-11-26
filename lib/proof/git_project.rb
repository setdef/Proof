# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class GitProject < Data.define(:root, :program)
    # steep:ignore:end
    PARTIAL_SETTING = /^(extensions\.partialclone=.|remote\..+\.promisor=true$)/
    private_constant(:PARTIAL_SETTING)

    def self.find(folder, program: "git")
      raise(NotInRepositoryError.new(folder:)) unless File.directory?(folder)

      new(root: Git.new(folder:, program:).run("rev-parse", "--show-toplevel").chomp, program:)
    rescue GitFailedError => e
      raise(NotInRepositoryError.new(folder:, git_said: e.message))
    end

    def commit_id(revision)
      refuse_a_partial_clone
      resolve(revision)
    end

    def working_tree_commit_id
      refuse_a_partial_clone
      WorkingTreeCommit.new(git:).id
    end

    def file_at(id, path)
      CommittedFile.new(git:, commit: commit_id(id), path:).text
    end

    private def resolve(revision)
      # The ^{commit} after the revision means no revision can read as an option, whatever it starts with.
      git.run("rev-parse", "--verify", "#{revision}^{commit}").chomp
    rescue GitFailedError
      raise(UnknownRevisionError.new(revision:, root:))
    end

    private def git
      Git.new(folder: root, program:)
    end

    private def refuse_a_partial_clone
      # Git 2.54 marks the remote a filtered clone came from with remote.NAME.promisor, and older Git
      # sets extensions.partialclone, so either one means objects are missing.
      return unless git.run("config", "--list").match?(PARTIAL_SETTING)

      raise(PartialCloneError.new(root:))
    end
  end
end

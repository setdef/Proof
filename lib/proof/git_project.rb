# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class GitProject < Data.define(:root, :program)
    # steep:ignore:end
    NOT_A_FOLDER = "%s is not a folder, so no Git repository contains it. Check the folder you named with -C."
    NOT_IN_REPOSITORY = [
      "%s is not inside a Git repository (%s).",
      "Run proof from a folder inside the project, or name the project with -C.",
    ].join(" ")
    UNKNOWN_REVISION = [
      "%s is not a commit in %s.",
      "Check the spelling, or run git fetch if it is a branch or tag that the project's remote has.",
    ].join(" ")
    PARTIAL_CLONE = [
      "%s is a partial clone, so it lacks objects of the commits that Proof sends.",
      "Clone the project again without --filter, and run proof from that clone.",
    ].join(" ")
    PARTIAL_SETTING = /^(extensions\.partialclone=.|remote\..+\.promisor=true$)/
    private_constant(:PARTIAL_SETTING, :NOT_A_FOLDER, :NOT_IN_REPOSITORY, :UNKNOWN_REVISION, :PARTIAL_CLONE)

    def self.find(folder, program: "git")
      raise(NotInRepositoryError, format(NOT_A_FOLDER, folder)) unless File.directory?(folder)

      new(root: Git.new(folder:, program:).run("rev-parse", "--show-toplevel").chomp, program:)
    rescue GitFailedError => e
      raise(NotInRepositoryError, format(NOT_IN_REPOSITORY, folder, e.message))
    end

    def commit_id(revision)
      refuse_a_partial_clone
      # The ^{commit} after the revision means no revision can read as an option, whatever it starts with.
      git.run("rev-parse", "--verify", "#{revision}^{commit}").chomp
    rescue GitFailedError
      raise(UnknownRevisionError, format(UNKNOWN_REVISION, revision, root))
    end

    private def git
      Git.new(folder: root, program:)
    end

    private def refuse_a_partial_clone
      # Git 2.54 marks the remote a filtered clone came from with remote.NAME.promisor, and older Git
      # sets extensions.partialclone, so either one means objects are missing.
      return unless git.run("config", "--list").match?(PARTIAL_SETTING)

      raise(PartialCloneError, format(PARTIAL_CLONE, root))
    end
  end
end

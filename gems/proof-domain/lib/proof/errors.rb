# frozen_string_literal: true

module Proof
  class Error < StandardError
  end

  class InvalidOSError < Error
  end

  class InvalidLabelError < Error
  end

  class InvalidLabelSetError < Error
  end

  class InvalidResourcesError < Error
  end

  class InvalidRunIdError < Error
  end

  class InvalidRandomSourceError < Error
  end

  class GitNotFoundError < Error
  end

  class NotInRepositoryError < Error
    def initialize(folder:, git_said: nil)
      super(
        if git_said
          "#{folder} is not inside a Git repository (#{git_said}). " \
            "Run proof from a folder inside the project, or name the project with -C."
        else
          "#{folder} is not a folder, so no Git repository contains it. Check the folder you named with -C."
        end
      )
    end
  end

  class UnknownRevisionError < Error
    def initialize(revision:, root:)
      super(
        "#{revision} is not a commit in #{root}. " \
          "Check the spelling, or run git fetch if it is a branch or tag that the project's remote has."
      )
    end
  end

  class PartialCloneError < Error
    def initialize(root:)
      super(
        "#{root} is a partial clone, so it lacks objects of the commits that Proof sends. " \
          "Clone the project again without --filter, and run proof from that clone."
      )
    end
  end

  class NoCommitsError < Error
    def initialize(root:)
      super(
        "#{root} has no commits yet, so there is no HEAD to base the working tree on. " \
          "Make a first commit with git commit, and run proof again."
      )
    end
  end

  # steep:ignore:start
  class GitFailedError < Error
    # steep:ignore:end
    attr_reader :status, :error_output

    def initialize(subcommand:, status:, error_output:)
      # The class line is ignored by Steep, which doesn't count attr_reader as defining the readers that
      # the signature declares, and RuboCop rejects a method that only returns an instance variable.
      @status = status
      @error_output = error_output
      super("git #{subcommand} failed (#{status.to_s.sub(/\Apid \d+ /, '')}): #{error_output.strip}")
    end
  end
end

# frozen_string_literal: true

module Proof
  class Error < StandardError
  end

  class InvalidOSError < Error
  end

  class NoSharedOSError < Error
    def initialize(operating_systems:)
      listed = operating_systems.map { |task, systems| "#{task} works on #{systems.sort_by(&:to_s).join(', ')}" }
      super(
        "no operating system is common to these tasks: #{listed.join('; ')}. " \
          "Run them with separate commands, or name one operating system with --os."
      )
    end
  end

  class InvalidPathPatternError < Error
  end

  class InvalidLabelError < Error
  end

  class InvalidLabelSetError < Error
  end

  class InvalidProjectFileError < Error
  end

  class InvalidResourcesError < Error
  end

  class InvalidRunIdError < Error
  end

  class InvalidRunSettingsError < Error
  end

  class InvalidTaskEntryError < Error
  end

  class InvalidTaskSettingsError < Error
  end

  class InvalidTimeLimitError < Error
  end

  class InvalidDurationError < Error
  end

  class InvalidSizeError < Error
  end

  class InvalidRetentionError < Error
  end

  class InvalidLimitsError < Error
  end

  class InvalidHostSettingsError < Error
  end

  class InvalidHostEntryError < Error
  end

  class InvalidResolvedHostError < Error
  end

  class InvalidRepositoryEntryError < Error
  end

  class InvalidPoolFileError < Error
  end

  class InvalidNameError < Error
  end

  class InvalidPortError < Error
  end

  class InvalidRandomSourceError < Error
  end

  class InvalidFactError < Error
  end

  class InvalidRunError < Error
  end

  class InvalidRunnerError < Error
  end

  class InvalidHostError < Error
  end

  class InvalidWaitReasonError < Error
  end

  class InvalidShortfallError < Error
  end

  # steep:ignore:start
  class RunFitsNoHostError < Error
    # steep:ignore:end
    attr_reader :host, :shortfalls

    def initialize(host:, shortfalls:)
      # Each attribute is set here, before the message, which names the host and what it lacks.
      @host = host
      @shortfalls = shortfalls
      super(
        "No host could ever have the CPUs and memory this run requests free. The closest is #{host}, " \
          "which could have #{shortfalls.join(' and ')} requested. Request less, or add a host with more."
      )
    end
  end

  class RunExistsError < Error
    def initialize(id:)
      super("run #{id} is already stored")
    end
  end

  class QueuePositionTakenError < Error
    def initialize(position:)
      super("queue position #{position} is taken by another run")
    end
  end

  class UnknownRunError < Error
    def initialize(id:)
      super("no run #{id} is stored")
    end
  end

  class RunChangedError < Error
    def initialize(id:, version:, read:)
      super("run #{id} has #{version} facts, not the #{read} it had when it was read")
    end
  end

  class RunAlreadyPlacedError < Error
    def initialize(id:)
      super("run #{id} is already placed")
    end
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

  class SymbolicLinkError < Error
    def initialize(path:, commit:)
      super("#{path} at #{commit} is a symbolic link, not a regular file")
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

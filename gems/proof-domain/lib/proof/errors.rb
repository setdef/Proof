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

  class GitFailedError < Error
    def initialize(subcommand:, status:, error_output:)
      super("git #{subcommand} failed (#{status.to_s.sub(/\Apid \d+ /, '')}): #{error_output.strip}")
    end
  end
end

# frozen_string_literal: true

module Usage
  class ExitCode < Data.define(:status, :help)
    # @dynamic status, help, initialize
  end
end

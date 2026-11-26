# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class ExitCode < Data.define(:status, :help)
    # steep:ignore:end
    KEYS = %w[code help].freeze
    private_constant(:KEYS)

    def self.read(object, program)
      reader = Reader.new(object, "an exit code of #{program}", KEYS)
      new(status: reader.number(:code), help: reader.text(:help).to_s)
    end
  end
end

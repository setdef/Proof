# frozen_string_literal: true

module Usage
  module ExitCodeFormat
    KEYS = %w[code help].freeze
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, "an exit code of #{parent}", KEYS)
      ExitCode.new(status: reader.number(:code), help: reader.text(:help).to_s)
    end
  end
end

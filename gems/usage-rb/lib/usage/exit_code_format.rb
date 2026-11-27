# frozen_string_literal: true

require_relative("keys")
module Usage
  module ExitCodeFormat
    KEYS = Keys.new(read: %i[code help])
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, parent.child("an exit code"), KEYS)
      ExitCode.new(status: reader.number(:code), help: reader.text(:help).to_s)
    end
  end
end

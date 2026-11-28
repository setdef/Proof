# frozen_string_literal: true

module Usage
  class CommandLineError < StandardError
    attr_reader :command

    def initialize(command, message)
      @command = command
      super(message)
    end

    # @dynamic command
  end
end

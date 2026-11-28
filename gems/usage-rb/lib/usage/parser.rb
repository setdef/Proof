# frozen_string_literal: true

module Usage
  class Parser
    def initialize(spec, messages: Messages)
      @commands = spec.commands
      @messages = messages
    end

    def parse(words)
      start = Position.new(commands: @commands, command: @commands.root, messages: @messages)
      Line.new(start, words).parsed
    end
  end
end

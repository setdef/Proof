# frozen_string_literal: true

module Usage
  class Position < Data.define(:lineage, :messages)
    def command
      lineage.command
    end

    def flags
      lineage.flags
    end

    def scope
      Scope.new(flags)
    end

    def branch?
      !command.subcommands.empty?
    end

    def descend(word)
      with(lineage: lineage.descendant([word]) || refuse { |said| said.unknown_command(word) })
    end

    def refuse
      raise(CommandLineError.new(command, yield(messages.new(command))))
    end

    # @dynamic lineage, messages, initialize, with
  end
end

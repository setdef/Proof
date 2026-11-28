# frozen_string_literal: true

module Usage
  class Position < Data.define(:commands, :command, :messages)
    def flags
      command.own_flags + commands.global_flags(command.path)
    end

    def scope
      Scope.new(flags)
    end

    def branch?
      !command.subcommands.empty?
    end

    def descend(word)
      with(command: command.subcommand(word) || refuse { |said| said.unknown_command(word) })
    end

    def refuse
      raise(CommandLineError.new(command, yield(messages.new(command))))
    end

    # @dynamic commands, command, messages, initialize, with
  end
end

# frozen_string_literal: true

module Usage
  class Tables
    def initialize(command, global_flags)
      @command = command
      @global_flags = global_flags
    end

    def all
      # The program's subcommands are the commands, and a command's are its subcommands.
      [
        Lists.commands(@command.program? ? "Commands:" : "Subcommands:", @command.subcommands),
        Lists.arguments(@command.args),
        Lists.flags("Flags:", @command.own_flags),
        Lists.flags("Global flags:", @global_flags),
      ]
    end
  end
end

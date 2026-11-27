# frozen_string_literal: true

module Usage
  class Tables
    def initialize(command, global_flags)
      @command = command
      @global_flags = global_flags
    end

    def all
      [
        commands,
        Layout.table("Arguments:", @command.args.map { |arg| [arg.to_s, arg.help.to_s] }),
        Rows.flags("Flags:", @command.own_flags),
        Rows.flags("Global flags:", @global_flags),
      ]
    end

    private def commands
      # The program's subcommands are the commands, and a command's are its subcommands.
      title = @command.program? ? "Commands:" : "Subcommands:"
      Layout.table(title, @command.subcommands.map { |child| [child.name, child.help.to_s] })
    end
  end
end

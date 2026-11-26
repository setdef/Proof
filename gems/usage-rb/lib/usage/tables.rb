# frozen_string_literal: true

module Usage
  class Tables
    def initialize(spec, command, listing)
      @spec = spec
      @command = command
      @listing = listing
    end

    def all
      [
        commands,
        Layout.table("Arguments:", @command.args.map { |arg| [arg.to_s, arg.help.to_s] }),
        Rows.flags("Flags:", @command.own_flags),
        Rows.flags("Global flags:", globals),
      ]
    end

    private def commands
      Layout.table(@listing, @command.subcommands.map { |child| [child.name, child.help.to_s] })
    end

    private def globals
      path = @command.path
      # A flag is global to every command under the one that has it, so the help lists those of each command on the
      # path.
      above = (0..(path.size)).filter_map { |size| @spec.command(path.first(size)) }
      above.flat_map(&:global_flags)
    end
  end
end

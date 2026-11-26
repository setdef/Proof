# frozen_string_literal: true

module Proof
  module CommandLine
    class Tables
      def initialize(command, globals, exit_rows)
        @command = command
        @globals = globals
        @exit_rows = exit_rows
      end

      def sections
        [listing, arguments, flags, globals, exit_codes]
      end

      private def listing
        title = @command.path.empty? ? "Commands:" : "Subcommands:"
        Columns.table(title, @command.subcommands.map { |child| Rows::CommandRow.new(child) })
      end

      private def arguments
        Columns.table("Arguments:", @command.args.map { |arg| Rows::ArgRow.new(arg) })
      end

      private def flags
        Columns.table("Flags:", @command.own_flags.map { |flag| Rows::FlagRow.new(flag) })
      end

      private def globals
        Columns.table("Global flags:", @globals.map { |flag| Rows::FlagRow.new(flag) })
      end

      private def exit_codes
        Columns.table("Exit statuses:", @exit_rows)
      end
    end
  end
end

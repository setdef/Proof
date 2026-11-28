# frozen_string_literal: true

module Usage
  class Lineage < Data.define(:above, :command)
    def commands
      [*above, command]
    end

    def descendant(path)
      word, *rest = path
      word ? child(word)&.descendant(rest) : self
    end

    def global_flags
      # A flag is global to every command under the one that has it, so a command takes those of each command in its
      # lineage, from the program down.
      commands.flat_map(&:flags).select(&:global?)
    end

    def flags
      command.own_flags + global_flags
    end

    def exit_codes
      # usage 7.4.1's `effective_exit_codes`: a Hash keeps the place a status first took, so the program's order holds,
      # the nearest command's meaning replaces it there, and a command's new statuses follow.
      commands.flat_map(&:exit_codes).to_h { |code| [code.status, code] }
        .values
    end

    private def child(word)
      subcommand = command.subcommand(word)
      with(above: commands, command: subcommand) if subcommand
    end

    # @dynamic above, command, initialize, with
  end
end

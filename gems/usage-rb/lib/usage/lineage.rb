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
      commands.flat_map(&:global_flags)
    end

    def flags
      command.own_flags + global_flags
    end

    private def child(word)
      subcommand = command.subcommand(word)
      with(above: commands, command: subcommand) if subcommand
    end

    # @dynamic above, command, initialize, with
  end
end

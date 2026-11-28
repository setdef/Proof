# frozen_string_literal: true

module Usage
  class Command < Data.define(
    :name,
    :path,
    :help,
    :help_long,
    :args,
    :flags,
    :subcommands,
    :groups,
    :examples,
    :exit_codes,
    :subcommand_required
  )
    def program?
      path.empty?
    end

    def subcommand_required?
      subcommand_required
    end

    def subcommand(word)
      subcommands.find { |child| child.name == word }
    end

    def subcommand_names
      subcommands.map(&:name)
    end

    def own_flags
      flags.reject(&:global?)
    end

    # @dynamic name, path, help, help_long, args, flags, subcommands, groups, examples, exit_codes
    # @dynamic subcommand_required, initialize
  end
end

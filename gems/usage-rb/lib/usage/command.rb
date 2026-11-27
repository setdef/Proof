# frozen_string_literal: true

module Usage
  # steep:ignore:start
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
    :subcommand_required
  )
    # steep:ignore:end
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

    def global_flags
      flags.select(&:global?)
    end
  end
end

# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class CommandTree < Data.define(:root)
    # steep:ignore:end
    def find(path)
      path.reduce(root) { |acc, elem| acc&.subcommand(elem) }
    end

    def global_flags(path)
      # A flag is global to every command under the one that has it, so a command takes those of each command on its
      # path, from the program down.
      on(path).flat_map(&:global_flags)
    end

    private def on(path)
      commands = path.reduce([root]) { |acc, elem| [*acc, acc.last&.subcommand(elem)] }
      commands.compact
    end
  end
end

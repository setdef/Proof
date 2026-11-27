# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class CommandTree < Data.define(:root)
    # steep:ignore:end
    def find(path)
      # The program comes first, so the command the whole path names is the one after a command for each word.
      lineage(path)[path.size]
    end

    def global_flags(path)
      # A flag is global to every command under the one that has it, so a command takes those of each command on its
      # path, from the program down.
      lineage(path).flat_map(&:global_flags)
    end

    private def lineage(path, command = root)
      word, *rest = path
      child = command.subcommand(word) if word
      [command, *(child ? lineage(rest, child) : [])]
    end
  end
end

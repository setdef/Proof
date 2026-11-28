# frozen_string_literal: true

module Usage
  class CommandTree < Data.define(:root)
    def at(path)
      program.descendant(path) || raise(KeyError, "no command has the path #{path.inspect}")
    end

    def find(path)
      program.descendant(path)&.command
    end

    private def program
      Lineage.new(above: [], command: root)
    end

    # @dynamic root, initialize
  end
end

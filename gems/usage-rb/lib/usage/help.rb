# frozen_string_literal: true

module Usage
  class Help
    def initialize(spec)
      @spec = spec
    end

    def text(path)
      "#{page(lineage(path)).sections.compact.join("\n\n")}\n"
    end

    private def lineage(path)
      program = @spec.commands.at([])
      # Asking for help never fails, so a path that names no command gives the program's help.
      program.descendant(path) || program
    end

    private def page(lineage)
      lineage.command.program? ? ProgramPage.new(@spec, lineage) : CommandPage.new(@spec, lineage)
    end
  end
end

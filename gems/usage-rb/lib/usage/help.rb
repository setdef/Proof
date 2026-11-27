# frozen_string_literal: true

module Usage
  class Help
    def initialize(spec)
      @spec = spec
    end

    def text(path)
      commands = @spec.commands
      # Asking for help never fails, so a path that names no command gives the program's help.
      command = commands.find(path) || commands.root
      page = command.program? ? Page.new(@spec, command) : CommandPage.new(@spec, command)
      "#{page.sections.compact.join("\n\n")}\n"
    end
  end
end

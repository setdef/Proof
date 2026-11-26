# frozen_string_literal: true

module Usage
  class Help
    def initialize(spec)
      @spec = spec
    end

    def text(path)
      commands = @spec.commands
      command = commands.find(path) unless path.empty?
      page = command ? CommandPage.new(@spec, command) : Page.new(@spec, commands.root)
      "#{page.sections.compact.join("\n\n")}\n"
    end
  end
end

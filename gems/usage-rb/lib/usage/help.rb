# frozen_string_literal: true

module Usage
  class Help
    def initialize(spec)
      @spec = spec
    end

    def text(path)
      command = @spec.command(path) unless path.empty?
      page = command ? CommandPage.new(@spec, command) : Page.new(@spec, @spec.root)
      "#{page.sections.compact.join("\n\n")}\n"
    end
  end
end

# frozen_string_literal: true

require_relative("page")

module Usage
  class CommandPage < Page
    private def about
      command.help.to_s
    end

    private def description
      command.help_long
    end

    private def examples
      command.examples
    end

    private def commands_title
      "Subcommands:"
    end

    private def ending
      []
    end
  end
end

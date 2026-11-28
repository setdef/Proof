# frozen_string_literal: true

require_relative("page")

module Usage
  class ProgramPage < Page
    private def about
      spec.about
    end

    private def description
      spec.about_long
    end

    private def examples
      spec.examples
    end

    private def commands_title
      "Commands:"
    end

    private def ending
      [spec.after_help]
    end
  end
end

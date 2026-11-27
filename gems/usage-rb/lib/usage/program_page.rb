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

    private def ending
      [Rows.exit_statuses(spec.exit_codes), spec.after_help]
    end
  end
end

# frozen_string_literal: true

module DocExamples
  # The marker that skips a block: a line of the form
  # <tt><!-- skip-example: reason --></tt> directly before the fence.
  module Skip
    START = "<!-- skip-example:"
    FINISH = "-->"
    private_constant(:FINISH, :START)

    # The reason in the marker on the line before index +start+ of +lines+, or
    # nil when no marker is there.
    def self.reason(lines, start)
      comment = start.zero? ? "" : lines[start - 1].to_s.strip
      return unless comment.start_with?(START) && comment.end_with?(FINISH)

      comment.delete_prefix(START).delete_suffix(FINISH).strip
    end
  end
end

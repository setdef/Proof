# frozen_string_literal: true

require_relative("span")

module DocExamples
  # Finds the fenced blocks in a list of lines.
  module Spans
    # The fenced blocks in +lines+ from index +from+ on, in order.
    def self.scan(lines, from = 0)
      span = (from...(lines.size)).lazy.map { |index| Span.new(lines, index) }
        .find(&:opens?)
      span ? [span, *scan(lines, span.finish + 1)] : []
    end
  end
end

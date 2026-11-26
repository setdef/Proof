# frozen_string_literal: true

require "prism"
require_relative("block")
require_relative("expression")
require_relative("insertion")
require_relative("statements")

module DocExamples
  # Raised for a block that can't be checked: it has a syntax error, or a
  # +# =>+ comment with nothing to compare.
  class Fault < StandardError
  end

  # Rewrites a block's code so each +# =>+ comment is checked as the block
  # runs.
  #
  # The expression a comment is about is wrapped in a call to the child's
  # checker, which compares its value with the text after the arrow.
  module Instrumenter
    ARROW = "# =>"
    private_constant(:ARROW)

    # The code of +block+ with each +# =>+ comment checked. Raises Fault for
    # code that doesn't parse, and for a comment that has nothing to check.
    def self.call(block)
      code = block.code
      result = Prism.parse(code)
      check_syntax(block, result)
      Insertion.apply(code, edits_in(block, result))
    end

    # Raises Fault with a line for each syntax error in a parsed block.
    def self.check_syntax(block, result)
      return if result.success?

      lines = result.errors.map { |error| "#{block.place(error.location.start_line)}: syntax error: #{error.message}" }
      raise(Fault, lines.join("\n"))
    end
    private_class_method(:check_syntax)

    # The insertions that check every +# =>+ comment in a parsed block.
    def self.edits_in(block, result)
      endings = Statements.endings(result.value)
      arrows = result.comments.select { |comment| comment.slice.start_with?(ARROW) }
      arrows.flat_map { |comment| edits_for(block, comment, endings) }
    end
    private_class_method(:edits_in)

    # The insertions that wrap the statement a comment is about.
    def self.edits_for(block, comment, endings)
      place = block.place(comment.location.start_line)
      expected = comment.slice.delete_prefix(ARROW).strip
      raise(Fault, "#{place}: the value after # => must be one Ruby expression") unless Expression.single?(expected)

      target = Statements.target(comment, endings) or raise(Fault, "#{place}: no expression for this # => to check")
      Insertion.wrap(target, expected, place)
    end
    private_class_method(:edits_for)
  end
end

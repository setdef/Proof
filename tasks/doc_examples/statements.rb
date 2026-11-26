# frozen_string_literal: true

require "prism"

module DocExamples
  # Finds the statement a +# =>+ comment is about.
  #
  # After code on the same line, the comment is about the last statement that
  # ends on that line. On a line of its own, it is about the last statement that
  # ends above it.
  module Statements
    # Each statement in a parsed program, however deep, with where it ends: its
    # last line, its last byte offset, and the statement.
    def self.endings(program)
      statements_in(program).map do |statement|
        location = statement.location
        [location.end_line, location.end_offset, statement]
      end
    end

    # The statement +comment+ is about, from the +endings+ of the program, or
    # nil when there is none.
    def self.target(comment, endings)
      line = comment.location.start_line
      comment.trailing? ? ending_on(endings, line) : ending_above(endings, line)
    end

    # Every statement in a node, however deep, in no particular order.
    def self.statements_in(node)
      deeper = node.compact_child_nodes.flat_map { |child| statements_in(child) }
      node.is_a?(Prism::StatementsNode) ? node.body + deeper : deeper
    end
    private_class_method(:statements_in)

    # The last statement that ends on +line+.
    def self.ending_on(endings, line)
      on_line = endings.select { |last_line, _, _| last_line == line }
      on_line.max_by { |_, offset, _| offset }
        &.last
    end
    private_class_method(:ending_on)

    # The last statement that ends above +line+.
    def self.ending_above(endings, line)
      above = endings.select { |last_line, _, _| last_line < line }
      above.max_by { |last_line, offset, _| [last_line, offset] }
        &.last
    end
    private_class_method(:ending_above)
  end
end

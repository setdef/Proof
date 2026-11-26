# frozen_string_literal: true

require "timeout"

require_relative("support/kdl_parser_helper")

# Checks the faults of the kdl gem that the reader works around: valid KDL 2 that its grammar refuses, and text that
# its tokenizer never finishes reading. These tests fail when the workaround breaks or a release of the gem changes it.
class KdlParserFaultsTest < Minitest::Test
  include KdlParserHelper

  # Project file reference, "Where Proof reads the file": "The file is KDL 2.0", and KDL 2 lets a space, a tab, or a
  # comment follow a block's closing brace before the node ends. The gem's grammar refuses that until the parser drops
  # the space, and the nodes after it keep the lines of their names.
  def test_a_space_or_a_comment_after_a_closing_brace_is_read
    ["} \n", "}\t\n", "} // done\n", "} /* done */\n", "}  \r\n"].each do |ending|
      assert_equal([["task", 1], ["os", 2], ["task", 4]], lines("task a {\n  os linux\n#{ending}task b\n"), ending)
    end
    assert_equal([["task", 1], ["os", 2]], lines("task a {\n  os linux\n}  "))
  end

  # The same, for a space before a `;`, which ends the node as a line break does.
  def test_a_space_between_a_closing_brace_and_a_semicolon_is_read
    assert_equal([["a", 1], ["b", 2], ["c", 3]], lines("a {\n  b\n} ; c\n"))
  end

  # The same, where the space is not the end of the node: another block to skip follows, and a word there is a mistake.
  def test_a_space_after_a_closing_brace_before_more_is_kept
    assert_equal([["a", 1], ["b", 2]], lines("a { } /- { x }\nb\n"))

    error = assert_raises(Proof::ProjectFileError) { lines("a { b } c\n") }

    assert_equal(1, error.line)
  end

  # Project file reference, "Where Proof reads the file": the refusal names "the file, the line, and what's wrong", so
  # a block comment that is never closed is refused, where the gem's tokenizer would read it forever. The timeout turns
  # a reader that hangs into a failing test, and the texts are the ways a comment can be left open: at the start, after
  # a node, nested, and after the `\` that continues a line, which the gem reads with a tokenizer of its own.
  def test_a_block_comment_with_no_end_is_refused
    [["/*", 1], ["a /* b", 1], ["a\n/* b /* c */\n\n", 4], ["a \\\n  /* b", 2]].each do |text, line|
      error = Timeout.timeout(5) { assert_raises(Proof::ProjectFileError, text) { lines(text) } }

      assert_equal(
        [line, "this is not valid KDL 2: Unterminated multi-line comment at column"],
        [error.line, error.reason[/\A.*column/]]
      )
    end
  end

  # The same, for block comments that are closed, which end the text, nest, or run over lines.
  def test_a_block_comment_with_an_end_is_read
    assert_equal([["a", 1]], lines("a /* b */"))
    assert_equal([["a", 3]], lines("/* b\n\nc */ a /* d /* e */ f */"))
  end
end

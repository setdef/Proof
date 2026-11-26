# frozen_string_literal: true

require_relative("../test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../../tasks/doc_examples/block")

# Checks what a block of documentation code says about itself.
class DocExamplesBlockTest < Minitest::Test
  # A block at line 10 of a page, with the given code and skip reason.
  def block(code, skip_reason: nil)
    DocExamples::Block.new(path: "doc/a.md", line: 10, code:, skip_reason:)
  end

  def test_a_block_with_no_skip_reason_is_not_skipped
    refute_predicate(block("1\n"), :skipped?)
  end

  def test_a_block_with_a_skip_reason_is_skipped
    assert_predicate(block("1\n", skip_reason: "a shell transcript"), :skipped?)
  end

  def test_a_skip_reason_that_is_empty_still_skips
    assert_predicate(block("1\n", skip_reason: ""), :skipped?)
  end

  def test_the_error_marker_names_the_error_the_block_raises
    assert_equal("Proof::Error", block("# Wrong: raises Proof::Error\nfoo\n").raises)
  end

  def test_words_after_the_error_name_are_ignored
    assert_equal("ZeroDivisionError", block("# Wrong: raises ZeroDivisionError (divided by 0)\n1 / 0\n").raises)
  end

  def test_a_marker_with_no_name_names_an_empty_error
    assert_equal("", block("# Wrong: raises  \nfoo\n").raises)
  end

  def test_a_block_with_no_marker_raises_nothing
    assert_nil(block("foo # Wrong: raises Foo\n").raises)
  end

  def test_the_marker_counts_only_on_the_first_line
    assert_nil(block("foo\n# Wrong: raises Foo\n").raises)
  end

  def test_an_empty_block_raises_nothing
    assert_nil(block("").raises)
  end

  def test_the_place_of_a_line_counts_from_the_first_line_of_the_code
    assert_equal("doc/a.md:10", block("1\n").place)
    assert_equal("doc/a.md:12", block("1\n2\n3\n").place(3))
  end
end

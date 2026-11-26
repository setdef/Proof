# frozen_string_literal: true

require_relative("../test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../../tasks/doc_examples/instrumenter")

# Checks how the instrumenter finds the expression a +# =>+ comment is about,
# by running the instrumented code.
class DocExamplesInstrumenterTest < Minitest::Test
  # The failures from running the code in a fresh scope, as a block at line 1
  # of "doc/a.md".
  def outcome(code)
    entry = { path: "doc/a.md", line: 1, code: instrumented(code), raises: nil }
    DocExamples::Child.new(Object.new.instance_eval { binding }).run([entry])
  end

  def instrumented(code)
    DocExamples::Instrumenter.call(DocExamples::Block.new(path: "doc/a.md", line: 1, code:, skip_reason: nil))
  end

  def fault(code)
    assert_raises(DocExamples::Fault) { instrumented(code) }
      .message
  end

  def test_code_with_no_arrow_comment_is_unchanged
    assert_equal("1 + 1\n# Adds.\n", instrumented("1 + 1\n# Adds.\n"))
  end

  def test_a_right_value_on_the_same_line_passes
    assert_empty(outcome("1 + 1 # => 2\n"))
  end

  def test_a_wrong_value_on_the_same_line_fails_with_its_place_and_both_values
    assert_equal(["doc/a.md:1: expected 3, but got 2"], outcome("1 + 1 # => 3\n"))
  end

  def test_a_right_value_on_the_next_line_passes
    assert_empty(outcome("1 + 1\n# => 2\n"))
  end

  def test_a_wrong_value_on_the_next_line_fails_at_the_comment
    assert_equal(["doc/a.md:3: expected 3, but got 2"], outcome("x = 1\n1 + 1\n# => 3\n"))
  end

  def test_blank_lines_and_other_comments_may_sit_between_the_expression_and_the_value
    assert_equal(["doc/a.md:4: expected 3, but got 2"], outcome("1 + 1\n\n# A note.\n# => 3\n"))
  end

  def test_a_comment_after_the_last_statement_on_a_line_is_about_that_statement
    assert_equal(["doc/a.md:1: expected 1, but got 2"], outcome("a = 1; b = 2 # => 1\n"))
  end

  def test_an_expression_that_spans_lines_is_checked_whole
    assert_empty(outcome("[1,\n 2].sum\n# => 3\n"))
    assert_equal(["doc/a.md:3: expected 4, but got 3"], outcome("[1,\n 2].sum\n# => 4\n"))
  end

  def test_a_statement_inside_a_block_is_checked_by_its_own_comment
    code = "[1, 2].each do |n|\n  n + 1 # => 5\nend\n"

    assert_equal(["doc/a.md:2: expected 5, but got 2", "doc/a.md:2: expected 5, but got 3"], outcome(code))
  end

  def test_a_comment_after_a_whole_block_is_about_the_block
    assert_equal(["doc/a.md:3: expected [1], but got [1, 2]"], outcome("[1, 2].each do |n|\nend\n# => [1]\n"))
  end

  def test_the_value_may_be_any_ruby_expression_that_can_use_earlier_variables
    assert_empty(outcome("x = 3\nx * 2 # => x + x\n"))
  end

  def test_a_value_the_expression_returns_passes_through_unchanged
    assert_empty(outcome("y = 1 + 1 # => 2\ny # => 2\n"))
  end

  def test_the_offsets_count_bytes_so_multibyte_text_before_the_expression_is_fine
    assert_empty(outcome("s = \"éé\"; s.size # => 2\n"))
    assert_equal(["doc/a.md:1: expected 4, but got 2"], outcome("s = \"éé\"; s.size # => 4\n"))
  end

  def test_a_comment_that_does_not_start_with_the_arrow_and_a_space_is_ignored
    assert_equal("1 +\n  1 #=> 3\n", instrumented("1 +\n  1 #=> 3\n"))
    assert_equal("1\n=begin\nx\n=end\n", instrumented("1\n=begin\nx\n=end\n"))
  end

  def test_code_that_does_not_parse_is_a_fault_at_the_line_of_the_error
    assert_match(%r{\Adoc/a\.md:2: syntax error: }, fault("1\n1 +\n"))
  end

  def test_an_arrow_with_nothing_after_it_is_a_fault
    assert_equal("doc/a.md:1: the value after # => must be one Ruby expression", fault("1 # =>\n"))
  end

  def test_an_arrow_with_no_expression_above_it_is_a_fault
    assert_equal("doc/a.md:1: no expression for this # => to check", fault("# => 1\n"))
  end

  def test_an_arrow_after_part_of_an_expression_is_a_fault
    assert_equal("doc/a.md:2: no expression for this # => to check", fault("foo(1,\n  2 # => 3\n)\n"))
  end

  def test_a_value_that_is_not_one_ruby_expression_is_a_fault
    message = "doc/a.md:1: the value after # => must be one Ruby expression"

    assert_equal(message, fault("nil # => #<Foo>\n"))
    assert_equal(message, fault("1 # => 1; 2\n"))
    assert_equal(message, fault("1 # => [1,\n"))
  end

  def test_a_value_that_names_something_undefined_fails_the_check
    assert_match(
      %r{\Adoc/a\.md:1: can't read Nope as a Ruby value: uninitialized constant},
      outcome("1 # => Nope\n").first
    )
  end
end

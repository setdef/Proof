# frozen_string_literal: true

require_relative("../test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../../tasks/doc_examples/extractor")

# Checks which fenced blocks the extractor takes as examples.
class DocExamplesExtractorTest < Minitest::Test
  # The blocks in Markdown, which start at line 1 of "doc/a.md".
  def markdown(*lines)
    DocExamples::Extractor.markdown(lines.join("\n"), "doc/a.md")
  end

  def test_a_ruby_block_has_its_path_its_first_line_of_code_and_its_code
    block = markdown("# Title", "", "```ruby", "x = 1", "y = 2", "```", "").first

    assert_equal(["doc/a.md", 4, "x = 1\ny = 2\n"], [block.path, block.line, block.code])
  end

  def test_the_first_line_of_a_text_counts_from_the_line_it_is_given
    block = DocExamples::Extractor.markdown("```ruby\nx = 1\n```", "doc/a.md", 20).first

    assert_equal(21, block.line)
  end

  def test_each_ruby_block_is_one_block
    assert_equal(2, markdown("```ruby", "1", "```", "text", "```ruby", "2", "```").size)
  end

  def test_a_block_that_is_not_ruby_is_not_an_example
    assert_empty(markdown("```console", "$ ls", "```", "```", "plain", "```", "```rbs", "x", "```"))
  end

  def test_a_language_after_other_words_still_counts_only_by_its_first_word
    assert_equal(1, markdown("```ruby title=\"a\"", "1", "```").size)
    assert_empty(markdown("``` title ruby", "1", "```"))
  end

  def test_tilde_fences_work_like_backtick_fences
    assert_equal(["1\n"], markdown("~~~ruby", "1", "~~~").map(&:code))
  end

  def test_a_closing_fence_needs_the_same_mark_and_at_least_the_same_length
    block = markdown("````ruby", "```", "~~~~", "1", "```` ", "2").first

    assert_equal("```\n~~~~\n1\n", block.code)
  end

  def test_a_longer_fence_can_show_a_ruby_fence_without_it_running
    assert_empty(markdown("````markdown", "```ruby", "1", "```", "````"))
  end

  def test_a_run_of_backticks_with_more_after_it_on_the_line_is_not_a_fence
    assert_empty(markdown("```ruby``` is code", "1", "```"))
  end

  def test_a_tilde_fence_may_have_backticks_after_its_language
    assert_equal(1, markdown("~~~ruby title=`x`", "1", "~~~").size)
  end

  def test_a_fence_that_is_never_closed_runs_to_the_end_of_the_text
    assert_equal(["1\n2\n"], markdown("```ruby", "1", "2").map(&:code))
  end

  def test_an_unclosed_fence_that_is_not_ruby_yields_nothing
    assert_empty(markdown("```console", "1"))
  end

  def test_an_indented_fence_loses_its_indent_from_each_line_of_code
    block = markdown("- item", "", "  ```ruby", "  x = 1", "    y = 2", "z = 3", "  ```").first

    assert_equal("x = 1\n  y = 2\nz = 3\n", block.code)
  end

  def test_an_empty_block_has_empty_code
    assert_equal([""], markdown("```ruby", "```").map(&:code))
  end

  def test_a_skip_marker_directly_before_a_fence_skips_the_block_with_its_reason
    block = markdown("<!-- skip-example: runs bundle install -->", "```ruby", "1", "```").first

    assert_equal("runs bundle install", block.skip_reason)
  end

  def test_a_skip_marker_may_be_indented
    assert_equal("why", markdown("  <!-- skip-example: why -->", "```ruby", "1", "```").first.skip_reason)
  end

  def test_a_skip_marker_without_a_reason_has_an_empty_reason
    assert_equal("", markdown("<!-- skip-example: -->", "```ruby", "1", "```").first.skip_reason)
  end

  def test_a_block_with_no_marker_before_it_has_no_skip_reason
    assert_nil(markdown("text", "```ruby", "1", "```").first.skip_reason)
  end

  def test_a_block_on_the_first_line_has_no_skip_reason
    assert_nil(markdown("```ruby", "1", "```").first.skip_reason)
  end

  def test_a_marker_with_a_blank_line_before_the_fence_skips_nothing
    assert_nil(markdown("<!-- skip-example: why -->", "", "```ruby", "1", "```").first.skip_reason)
  end

  def test_a_comment_that_is_not_a_skip_marker_skips_nothing
    assert_nil(markdown("<!-- a note -->", "```ruby", "1", "```").first.skip_reason)
    assert_nil(markdown("<!-- skip-example: unfinished", "```ruby", "1", "```").first.skip_reason)
  end

  def test_the_blocks_of_a_file_come_from_its_path
    assert_equal(1, DocExamples::Extractor.blocks("```ruby\n1\n```\n", "a.md").size)
    assert_equal(1, DocExamples::Extractor.blocks("# ```ruby\n# 1\n# ```\n", "a.rbs").size)
  end

  def test_an_rbs_block_is_a_comment_with_the_comment_marks_removed
    text = "module A\n  # Adds.\n  #\n  # ```ruby\n  # A.add(1, 2) # => 3\n  # ```\n  def self.add: () -> void\nend\n"
    block = DocExamples::Extractor.rbs(text, "sig/a.rbs").first

    assert_equal(["sig/a.rbs", 5, "A.add(1, 2) # => 3\n"], [block.path, block.line, block.code])
  end

  def test_an_rbs_comment_keeps_the_indent_of_its_code
    block = DocExamples::Extractor.rbs("# ```ruby\n#   x = 1\n# ```\n", "a.rbs").first

    assert_equal("  x = 1\n", block.code)
  end

  def test_each_run_of_comments_in_an_rbs_file_is_a_text_of_its_own
    text = "# ```ruby\n# 1\ndef a: () -> void\n# 2\n# ```\n"

    assert_equal(["1\n"], DocExamples::Extractor.rbs(text, "a.rbs").map(&:code))
  end

  def test_code_in_an_rbs_file_is_not_an_example
    assert_empty(DocExamples::Extractor.rbs("module A\n  def a: () -> void\nend\n", "a.rbs"))
  end

  def test_a_skip_marker_in_an_rbs_comment_skips_the_block
    block = DocExamples::Extractor.rbs("# <!-- skip-example: why -->\n# ```ruby\n# 1\n# ```\n", "a.rbs").first

    assert_equal("why", block.skip_reason)
  end
end

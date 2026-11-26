# frozen_string_literal: true

require_relative("test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../tasks/doc_examples")
require_relative("doc_examples/project")

# Checks what a whole run says about right and wrong examples, on a project
# made in a temporary folder.
class DocExamplesTest < Minitest::Test
  include DocExamplesProject

  def test_a_page_whose_examples_are_right_passes_and_counts_them
    in_project do |root|
      write(root, "README.md", page("1 + 1 # => 2"))
      write(root, "doc/b.md", page("x = 2", "x * 2", "# => 4"))
      report = DocExamples.check(root)

      assert_predicate(report, :ok?)
      assert_equal(["Examples run: 2. Examples skipped: 0."], report.summary)
    end
  end

  def test_a_wrong_value_on_one_line_fails_naming_the_file_and_line_with_both_values
    in_project do |root|
      write(root, "doc/a.md", page("1 + 1 # => 3"))

      assert_equal(["doc/a.md:4: expected 3, but got 2"], DocExamples.check(root).failures)
    end
  end

  def test_a_wrong_value_on_the_next_line_fails_naming_the_file_and_line
    in_project do |root|
      write(root, "doc/a.md", page("x = 1", "x + 1", "# => 3"))

      assert_equal(["doc/a.md:6: expected 3, but got 2"], DocExamples.check(root).failures)
    end
  end

  def test_a_block_marked_to_raise_that_does_not_raise_fails
    in_project do |root|
      write(root, "doc/a.md", page("# Wrong: raises ZeroDivisionError", "1 + 1"))
      failures = DocExamples.check(root).failures

      assert_equal(["doc/a.md:4: expected ZeroDivisionError to be raised, but nothing was"], failures)
    end
  end

  def test_a_block_marked_to_raise_that_raises_passes
    in_project do |root|
      write(root, "doc/a.md", page("# Wrong: raises ZeroDivisionError", "1 / 0"))

      assert_predicate(DocExamples.check(root), :ok?)
    end
  end

  def test_a_wrong_example_in_an_rbs_comment_fails_naming_the_file_and_line
    in_project do |root|
      write(
        root,
        "sig/a.rbs",
        "module A\n  # Adds.\n  #\n  # ```ruby\n  # 1 + 1 # => 3\n  # ```\n  def x: () -> void\nend\n"
      )

      assert_equal(["sig/a.rbs:5: expected 3, but got 2"], DocExamples.check(root).failures)
    end
  end

  def test_a_wrong_example_in_the_rbs_of_a_gem_fails
    in_project do |root|
      write(root, "gems/g/sig/a.rbs", "# ```ruby\n# 1 + 1 # => 3\n# ```\nmodule A\nend\n")

      assert_equal(["gems/g/sig/a.rbs:2: expected 3, but got 2"], DocExamples.check(root).failures)
    end
  end

  def test_a_project_with_no_examples_runs_none
    in_project do |root|
      write(root, "README.md", "# Nothing to run\n")

      assert_equal(["Examples run: 0. Examples skipped: 0."], DocExamples.check(root).summary)
    end
  end
end

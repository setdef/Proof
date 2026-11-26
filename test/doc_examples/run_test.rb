# frozen_string_literal: true

require_relative("../test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../../tasks/doc_examples")
require_relative("project")

# Checks how each file's examples run: in order, in a Ruby process of its own,
# with the project's load path, and writing only to a temporary folder.
class DocExamplesRunTest < Minitest::Test
  include DocExamplesProject

  def test_the_blocks_of_one_file_share_variables_and_run_in_order
    in_project do |root|
      write(root, "doc/a.md", "#{page('x = 1')}\n#{page('x += 1', 'x # => 2')}")
      report = DocExamples.check(root)

      assert_equal(2, report.ran)
      assert_predicate(report, :ok?)
    end
  end

  def test_one_file_cannot_affect_another
    in_project do |root|
      write(root, "doc/a.md", page("$leak = 1", "class Leak; end"))
      write(root, "doc/b.md", page("$leak # => nil", "defined?(Leak) # => nil"))

      assert_predicate(DocExamples.check(root), :ok?)
    end
  end

  def test_the_project_load_path_includes_lib_and_the_lib_of_each_gem
    in_project do |root|
      write(root, "lib/greeter.rb", "module Greeter\n  def self.hi\n    'hi'\n  end\nend\n")
      write(root, "gems/g/lib/farewell.rb", "module Farewell\n  def self.bye\n    'bye'\n  end\nend\n")
      write(
        root,
        "doc/a.md",
        page("require 'greeter'", "require 'farewell'", "Greeter.hi # => 'hi'", "Farewell.bye # => 'bye'")
      )

      assert_predicate(DocExamples.check(root), :ok?)
    end
  end

  def test_the_libraries_a_run_asks_for_are_required_before_the_first_example
    in_project do |root|
      write(root, "lib/greeter.rb", "module Greeter\n  def self.hi\n    'hi'\n  end\nend\n")
      write(root, "doc/a.md", page("Greeter.hi # => 'hi'"))

      assert_predicate(DocExamples.check(root, %w[greeter]), :ok?)
      refute_predicate(DocExamples.check(root), :ok?)
    end
  end

  def test_an_example_that_writes_a_file_writes_it_in_a_temporary_folder
    in_project do |root|
      write(root, "doc/a.md", page("File.write('note.txt', 'x')"))

      assert_predicate(DocExamples.check(root), :ok?)
      refute_path_exists(File.join(root, "note.txt"))
      refute_path_exists(File.join(Dir.pwd, "note.txt"))
    end
  end

  def test_a_skipped_block_is_counted_and_reported_with_its_place_and_reason
    in_project do |root|
      write(root, "doc/a.md", "# A page\n\n<!-- skip-example: runs bundle install -->\n```ruby\nraise 'no'\n```\n")
      report = DocExamples.check(root)

      assert_predicate(report, :ok?)
      assert_equal(
        ["Examples run: 0. Examples skipped: 1.", "  skipped doc/a.md:5: runs bundle install"],
        report.summary
      )
    end
  end

  def test_a_skip_marker_with_no_reason_fails
    in_project do |root|
      write(root, "doc/a.md", "<!-- skip-example: -->\n```ruby\nraise 'no'\n```\n")
      failures = DocExamples.check(root).failures

      assert_equal(["doc/a.md:3: a skip-example marker needs a reason after the colon"], failures)
    end
  end

  def test_a_block_that_cannot_be_checked_fails_and_the_others_still_run
    in_project do |root|
      write(root, "doc/a.md", "#{page('1 +')}\n#{page('1 + 1 # => 3')}")
      report = DocExamples.check(root)

      assert_equal(2, report.failures.size)
      assert_equal(1, report.ran)
    end
  end

  def test_a_process_that_ends_before_the_examples_finish_fails_with_its_output
    in_project do |root|
      write(root, "doc/a.md", page("warn 'output'", "exit!(3)"))
      failures = DocExamples.check(root).failures

      assert_equal(1, failures.size)
      assert_match(%r{\Adoc/a\.md: Ruby exited with status 3 before it finished the examples:\noutput}, failures.first)
    end
  end
end

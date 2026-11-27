# frozen_string_literal: true

require_relative("../test_helper")
require_relative("project")
require "open3"
require "rbconfig"

# Checks how many files' examples run at once.
class DocExamplesCapTest < Minitest::Test
  include DocExamplesProject

  ROOT = File.expand_path("../..", __dir__.to_s)
  CHECK = 'report = DocExamples.check(ARGV.fetch(0)); abort(report.failures.join("\n")) unless report.ok?'
  private_constant(:ROOT, :CHECK)

  def test_no_more_files_run_at_once_than_parallel_test_processors_says
    assert_equal(1, peak("1"))
    assert_equal(2, peak("2"))
  end

  def test_a_blank_parallel_test_processors_leaves_every_processor_to_the_examples
    assert_operator(peak(""), :>, 1)
  end

  # The most processes that ran an example at the same moment, over four
  # files that each hold their place for a while, when the examples' process
  # reads +processors+ as PARALLEL_TEST_PROCESSORS.
  private def peak(processors)
    in_project do |root|
      Dir.mktmpdir("doc-examples-peak") do |dir|
        4.times { |index| write(root, "doc/f#{index}.md", page(*holding(dir))) }
        run_check(processors, root)
        peaks = Dir.children(dir).grep(/\Apeak-/).map { |name| Integer(File.read(File.join(dir, name)), 10) }
        peaks.max
      end
    end
  end

  # Example code that claims a place in +dir+, waits, records how many places
  # are claimed, and gives its place up.
  private def holding(dir)
    [
      "place = File.join(#{dir.inspect}, \"at-\#{$$}\")",
      "File.write(place, '')",
      "sleep(0.5)",
      "claimed = Dir.children(#{dir.inspect}).grep(/\\Aat-/).size",
      "File.write(File.join(#{dir.inspect}, \"peak-\#{$$}\"), claimed)",
      "File.delete(place)",
    ]
  end

  # Checks the examples of the project at +root+ in a Ruby process of its own.
  private def run_check(processors, root)
    command = [RbConfig.ruby, "-rbundler/setup", "-r./tasks/doc_examples", "-e", CHECK, root]
    output, status = Open3.capture2e({ "PARALLEL_TEST_PROCESSORS" => processors }, *command, chdir: ROOT)

    assert_predicate(status, :success?, output)
  end
end

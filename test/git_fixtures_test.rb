# frozen_string_literal: true

require_relative("git_fixtures")
require "open3"
require "rbconfig"

# Checks that the tests' Git fixtures reach only the repositories they make, whatever runs the tests: `git rebase
# --exec` sets `GIT_DIR` and related variables for the command it runs, and a `git` that inherits them acts on that
# repository.
#
# A test process whose environment names a scratch repository runs every way the tests start git, and this test
# looks for a change in the scratch repository.
class GitFixturesTest < Minitest::Test
  include GitFixtures

  TESTS = File.expand_path(__dir__)
  # Runs in a folder of its own, so its coverage report is not this run's.
  PROBE = <<~RUBY.freeze
    require(#{File.join(TESTS, 'doc_examples', 'project.rb').inspect})
    require(#{File.expand_path('../tasks/doc_examples.rb', TESTS).inspect})

    class FixturesProbe < Minitest::Test
      include DocExamplesProject

      def test_every_way_the_tests_start_git
        commit_file(make_repository("other"), "b.txt", "2")
        git(temporary_folder, "init", "--quiet", "--bare", File.join(temporary_folder, "bare.git"))
        in_project do |root|
          write(root, "doc/a.md", page("1 # => 1"))
          git(root, "add", "doc/a.md")

          assert_equal(["doc/a.md"], DocExamples.files(root))
        end
      end
    end
  RUBY
  private_constant(:TESTS, :PROBE)

  def test_the_tests_leave_a_repository_that_the_git_variables_name_unchanged
    scratch = make_repository("scratch")
    commit_file(scratch)
    before = contents(scratch)

    output, status = Open3.capture2e(redirecting_to(scratch), RbConfig.ruby, "-e", PROBE, chdir: temporary_folder)

    assert_predicate(status, :success?, output)
    assert_equal(before, contents(scratch))
  end

  # Every file under +folder+ with what it holds, read without running git, which could refresh the index.
  private def contents(folder)
    files = Dir.glob("**/*", File::FNM_DOTMATCH, base: folder).select { |path| File.file?(File.join(folder, path)) }
    files.to_h { |path| [path, File.binread(File.join(folder, path))] }
  end

  # The variables that point Git at +repository+, as `git rebase --exec` sets them.
  private def redirecting_to(repository)
    git_dir = File.join(repository, ".git")
    variables(GIT_DIR: git_dir, GIT_WORK_TREE: repository, GIT_INDEX_FILE: File.join(git_dir, "index"))
  end
end

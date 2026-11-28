# frozen_string_literal: true

require_relative("support/release_project")

# Checks the Rake task that stamps a release, +rake release:stamp+, as a person runs it: its exit status and what it
# says. It runs in a throwaway copy of a small project, and never in this checkout.
class ReleaseTaskTest < Minitest::Test
  include ReleaseProject

  TASKS = File.expand_path("../tasks", __dir__)
  private_constant(:TASKS)

  # The output and status of the stamping task, run as +rake release:stamp+ with the +tag+ if there is one, in +root+
  # with a Rakefile of its own so that no other task runs.
  def rake_stamp(root, tag = nil, frozen: false)
    File.write(File.join(root, "Rakefile"), "load(#{File.join(TASKS, 'release.rake').inspect})\n")
    run_in(root, RbConfig.ruby, "-S", "rake", ["release:stamp", tag && "[#{tag}]"].join, frozen:)
  end

  def test_the_task_stamps_the_checkout_it_runs_in
    in_project do |root|
      output, status = rake_stamp(root, "v0.4.0")

      assert_predicate(status, :success?, output)
      assert_agree(root, "0.4.0")
    end
  end

  def test_the_task_locks_when_the_environment_freezes_the_lockfile
    in_project do |root|
      output, status = rake_stamp(root, "v0.4.0", frozen: true)

      assert_predicate(status, :success?, output)
      assert_agree(root, "0.4.0")
    end
  end

  def test_the_task_refuses_a_prerelease_with_status_two_and_says_what_it_takes
    in_project do |root|
      before = files(root)
      output, status = rake_stamp(root, "v0.4.0-rc.1")

      assert_equal(2, status.exitstatus, output)
      assert_includes(output, "three whole numbers")
      assert_equal(before, files(root))
    end
  end

  def test_the_task_refuses_no_tag_with_status_two
    in_project do |root|
      output, status = rake_stamp(root)

      assert_equal(2, status.exitstatus, output)
    end
  end

  def test_the_task_exits_with_status_one_when_it_can_not_stamp
    in_project do |root|
      File.write(File.join(root, "lib", "proof", "version.rb"), "module Proof\nend\n")
      output, status = rake_stamp(root, "v0.4.0")

      assert_equal(1, status.exitstatus, output)
      assert_includes(output, "lib/proof/version.rb")
    end
  end
end

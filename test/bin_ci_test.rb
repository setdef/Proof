# frozen_string_literal: true

require_relative("test_helper")
require "etc"
require "open3"
require "rbconfig"
require "tmpdir"

# Checks bin/ci, the one command for the gate before a push: it refuses a BUNDLE_PATH that RuboCop and REUSE would
# read, and otherwise hands the gate to mise.
class BinCiTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  BIN_CI = File.join(ROOT, "bin", "ci")
  # A mise that prints what it was asked to run, and where, and then fails the way a failing gate does.
  FAKE_MISE = <<~SH
    #!/bin/sh
    echo "mise $*"
    echo "trusted=$MISE_TRUSTED_CONFIG_PATHS"
    echo "dir=$(pwd -P)"
    echo "workers=$PARALLEL_TEST_PROCESSORS"
    echo "nice=$(ps -o ni= -p $$ | tr -d " ")"
    exit 7
  SH
  private_constant(:ROOT, :BIN_CI, :FAKE_MISE)

  # The output and status of bin/ci run from +dir+, in the environment of a shell that has set the +variables+ and
  # has +path+ as its path, which is the one of a person, not the one of this test run's bundle.
  def run_ci(variables, path:, dir: ROOT)
    Bundler.with_unbundled_env do
      Open3.capture2e(variables.merge([["PATH", path]].to_h), RbConfig.ruby, BIN_CI, chdir: dir)
    end
  end

  # The same, with a mise in front of the real one on the path.
  def run_with_fake_mise(variables, dir: ROOT)
    Dir.mktmpdir("bin-ci-test") do |bin|
      File.write(File.join(bin, "mise"), FAKE_MISE, perm: 0o755)
      run_ci(variables, path: [bin, ENV.fetch("PATH")].join(File::PATH_SEPARATOR), dir:)
    end
  end

  def test_an_unset_bundle_path_is_refused
    output, status = run_with_fake_mise([["BUNDLE_PATH", nil]].to_h)

    refute_predicate(status, :success?)
    refute_includes(output, "mise exec")
  end

  def test_an_unset_bundle_path_is_refused_with_what_to_set
    output, = run_with_fake_mise([["BUNDLE_PATH", nil]].to_h)

    assert_includes(output, "bin/ci: BUNDLE_PATH is not set.")
    assert_includes(output, "Set it to a folder outside the repository")
  end

  def test_a_bundle_path_inside_the_repository_is_refused
    ["vendor/bundle", ROOT, File.join(ROOT, "tmp", "gems")].each do |inside|
      output, status = run_with_fake_mise([["BUNDLE_PATH", inside]].to_h)

      refute_predicate(status, :success?, inside)
      assert_includes(output, "bin/ci: BUNDLE_PATH is inside the repository", inside)
    end
  end

  def test_a_link_into_the_repository_does_not_hide_a_bundle_inside_it
    Dir.mktmpdir("bin-ci-link") do |dir|
      File.symlink(ROOT, File.join(dir, "link"))
      output, status = run_with_fake_mise([["BUNDLE_PATH", File.join(dir, "link", "gems-here")]].to_h)

      refute_predicate(status, :success?)
      assert_includes(output, "inside the repository")
    end
  end

  def test_a_bundle_path_outside_the_repository_runs_the_gate_through_mise_and_ends_with_its_status
    Dir.mktmpdir("bin-ci-outside") do |outside|
      output, status = run_with_fake_mise([["BUNDLE_PATH", File.join(outside, "bundle")]].to_h, dir: outside)

      assert_equal(7, status.exitstatus)
      assert_includes(output, "mise exec -- bundle exec rake\n")
    end
  end

  def test_the_gate_runs_in_the_repository_whatever_folder_bin_ci_starts_in
    Dir.mktmpdir("bin-ci-outside") do |outside|
      output, = run_with_fake_mise([["BUNDLE_PATH", File.join(outside, "bundle")]].to_h, dir: outside)

      assert_includes(output, "dir=#{File.realpath(ROOT)}\n")
    end
  end

  def test_mise_trusts_the_configuration_of_the_repository
    Dir.mktmpdir("bin-ci-outside") do |outside|
      output, = run_with_fake_mise([["BUNDLE_PATH", File.join(outside, "bundle")]].to_h, dir: outside)

      assert_includes(output, "trusted=#{File.realpath(ROOT)}\n")
    end
  end

  def test_an_empty_bundle_path_is_refused
    output, status = run_with_fake_mise([["BUNDLE_PATH", ""]].to_h)

    refute_predicate(status, :success?)
    assert_includes(output, "bin/ci: BUNDLE_PATH is not set.")
  end

  def test_the_gate_runs_at_a_lower_priority_than_bin_ci_started_with
    Dir.mktmpdir("bin-ci-outside") do |outside|
      output, = run_with_fake_mise([["BUNDLE_PATH", File.join(outside, "bundle")]].to_h, dir: outside)
      started_with = Process.getpriority(Process::PRIO_PROCESS, 0)

      # The lowest priority is 19 on Linux and 20 on macOS, so a run that already has a low one may end up higher.
      assert_operator(Integer(output[/^nice=(\d+)$/, 1], 10), :>=, [started_with + 10, 19].min)
    end
  end

  def test_a_computer_without_mise_is_told_to_install_it
    Dir.mktmpdir("bin-ci-no-mise") do |empty|
      output, status = run_ci([["BUNDLE_PATH", File.join(empty, "bundle")]].to_h, path: empty)

      refute_predicate(status, :success?)
      assert_includes(output, "mise is not installed.")
    end
  end

  def test_the_gate_starts_half_as_many_test_processes_as_there_are_processors
    Dir.mktmpdir("bin-ci-outside") do |outside|
      output, = run_with_fake_mise([["BUNDLE_PATH", File.join(outside, "bundle")]].to_h, dir: outside)

      assert_includes(output, "workers=#{[Etc.nprocessors / 2, 1].max}\n")
    end
  end

  def test_a_number_of_test_processes_that_is_set_is_kept
    Dir.mktmpdir("bin-ci-outside") do |outside|
      variables = [["BUNDLE_PATH", File.join(outside, "bundle")], %w[PARALLEL_TEST_PROCESSORS 3]].to_h
      output, = run_with_fake_mise(variables)

      assert_includes(output, "workers=3\n")
    end
  end
end

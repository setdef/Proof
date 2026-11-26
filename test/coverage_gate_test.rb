# frozen_string_literal: true

require_relative("test_helper")
require "fileutils"
require "open3"
require "rbconfig"
require "shellwords"
require "tmpdir"

# Checks that every test run reports the coverage of that run alone.
#
# SimpleCov merges the results of runs it names differently, for ten minutes,
# so a run of one test file once reported the lines an earlier run of another
# had covered. The gate would then pass a line no test runs now.
class CoverageGateTest < Minitest::Test
  HELPER = File.expand_path("test_helper.rb", __dir__)
  PROBE = <<~RUBY
    # frozen_string_literal: true

    module Probe
      def self.first
        :first
      end

      def self.second
        :second
      end
    end
  RUBY
  # Each test names a whole run of its own, so no variable of a parallel run reaches it.
  ALONE = %w[TEST_ENV_NUMBER PARALLEL_TEST_GROUPS PARALLEL_PID_FILE].product([nil]).to_h.freeze
  private_constant(:HELPER, :PROBE, :ALONE)

  # The Ruby source of a test process that names its run +name+, starts
  # SimpleCov as the project's test helper does, and calls the +methods+ of
  # the probe.
  def script(name, methods)
    <<~RUBY
      require("simplecov")
      SimpleCov.command_name(#{name.inspect})
      require(#{HELPER.inspect})
      require("./lib/probe")
      class ProbeTest < Minitest::Test
        def test_probe = #{methods.inspect}.each { |method| Probe.public_send(method) }
      end
    RUBY
  end

  # The status and output of that process, run in +root+, a folder with a
  # +lib/probe.rb+.
  def run_probe(root, name, methods)
    File.write(File.join(root, "#{name}.rb"), script(name, methods))
    output, status = Open3.capture2e(ALONE, RbConfig.ruby, "#{name}.rb", chdir: root)
    [status, output]
  end

  # A test file of the probe project that calls the +methods+ of the probe.
  def probe_test(root, name, methods)
    File.write(File.join(root, "test", "#{name}_test.rb"), <<~RUBY)
      class #{name.capitalize}Test < Minitest::Test
        def test_probe = #{methods.inspect}.each { |method| Probe.public_send(method) }
      end
    RUBY
  end

  # The status and output of two parallel workers, each running one of the test files of +root+, a folder with a
  # +lib/probe.rb+ and a +test+ folder.
  def run_workers(root)
    worker = [RbConfig.ruby, "-rbundler/setup", "-r#{HELPER}", "-r./lib/probe"].shelljoin
    command = <<~RUBY
      require("parallel_tests/cli")
      ParallelTests::CLI.new.run(%w[--type test -n 2 test])
    RUBY
    env = ALONE.merge([["PARALLEL_TESTS_EXECUTABLE", worker]].to_h)
    output, status = Open3.capture2e(env, RbConfig.ruby, "-e", command, chdir: root)
    [status, output]
  end

  def test_a_run_does_not_report_the_coverage_of_an_earlier_run_with_another_name
    Dir.mktmpdir("coverage-gate-test") do |root|
      Dir.mkdir(File.join(root, "lib"))
      File.write(File.join(root, "lib", "probe.rb"), PROBE)
      earlier, = run_probe(root, "earlier", %i[first second])
      later, output = run_probe(root, "later", %i[first])

      assert_predicate(earlier, :success?)
      refute_predicate(later, :success?, output)
    end
  end

  def test_a_run_alone_with_every_line_covered_passes
    Dir.mktmpdir("coverage-gate-test") do |root|
      Dir.mkdir(File.join(root, "lib"))
      File.write(File.join(root, "lib", "probe.rb"), PROBE)
      status, output = run_probe(root, "alone", %i[first second])

      assert_predicate(status, :success?, output)
    end
  end

  def test_parallel_workers_that_between_them_cover_every_line_pass
    in_probe_project do |root|
      probe_test(root, "first", %i[first])
      probe_test(root, "second", %i[second])
      status, output = run_workers(root)

      assert_predicate(status, :success?, output)
      assert_includes(output, "Line coverage: 5 / 5 (100.00%)")
    end
  end

  def test_parallel_workers_that_between_them_leave_a_line_uncovered_fail
    in_probe_project do |root|
      probe_test(root, "first", %i[first])
      probe_test(root, "second", [])
      status, output = run_workers(root)

      refute_predicate(status, :success?, output)
      assert_includes(output, "Line coverage: 4 / 5")
    end
  end

  # Yields a folder with a +lib/probe.rb+ and an empty +test+ folder.
  def in_probe_project
    Dir.mktmpdir("coverage-gate-test") do |root|
      FileUtils.mkdir_p([File.join(root, "lib"), File.join(root, "test")])
      File.write(File.join(root, "lib", "probe.rb"), PROBE)
      yield(root)
    end
  end
end

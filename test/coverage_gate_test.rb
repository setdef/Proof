# frozen_string_literal: true

require_relative("support/coverage_probe")
require "open3"
require "rbconfig"
require "shellwords"

# Checks that every test run reports the coverage of that run alone.
#
# SimpleCov merges the results of runs it names differently, for ten minutes,
# so a run of one test file once reported the lines an earlier run of another
# had covered. The gate would then pass a line no test runs now.
class CoverageGateTest < Minitest::Test
  include CoverageProbe

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
end

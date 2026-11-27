# frozen_string_literal: true

require_relative("support/coverage_probe")
require "open3"
require "rbconfig"

# Checks that +rake test:ruby+, the task of the gate, passes when the workers between them cover every line of a probe
# project, and fails when a line stays uncovered.
class CoverageGateTaskTest < Minitest::Test
  include CoverageProbe

  TASKS = File.join(ROOT, "tasks", "shared", "test.rake")
  private_constant(:TASKS)

  # The status and output of +rake test:ruby+ run in +root+, a folder with a +lib/probe.rb+ and a +test+ folder. Its
  # test helper loads the project's test helper and then the probe, as the root's helper loads the code under test.
  def run_gate_task(root)
    File.write(File.join(root, "Rakefile"), "load(#{TASKS.inspect})\n")
    File.write(File.join(root, "test", "test_helper.rb"), "require(#{HELPER.inspect})\nrequire(\"./lib/probe\")\n")
    output, status = Open3.capture2e(ALONE, RbConfig.ruby, "-rbundler/setup", "-S", "rake", "test:ruby", chdir: root)
    [status, output]
  end

  def test_the_gate_task_passes_when_the_workers_between_them_cover_every_line
    in_probe_project do |root|
      probe_test(root, "first", %i[first])
      probe_test(root, "second", %i[second])
      status, output = run_gate_task(root)

      assert_predicate(status, :success?, output)
      assert_includes(output, "Line coverage: 5 / 5 (100.00%)")
    end
  end

  def test_the_gate_task_fails_when_the_workers_between_them_leave_a_line_uncovered
    in_probe_project do |root|
      probe_test(root, "first", %i[first])
      probe_test(root, "second", [])
      status, output = run_gate_task(root)

      refute_predicate(status, :success?, output)
      assert_includes(output, "Line coverage: 4 / 5")
    end
  end
end

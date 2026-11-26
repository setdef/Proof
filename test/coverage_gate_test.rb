# frozen_string_literal: true

require_relative("test_helper")
require "open3"
require "rbconfig"
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
  private_constant(:HELPER, :PROBE)

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
    output, status = Open3.capture2e(RbConfig.ruby, "#{name}.rb", chdir: root)
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
end

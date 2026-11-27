# frozen_string_literal: true

require_relative("../test_helper")
require "fileutils"
require "tmpdir"

# What the tests of the coverage gate share: a probe project in a folder of its own, whose +lib/probe.rb+ has five
# lines of code, and test files that call some of its methods.
module CoverageProbe
  ROOT = File.expand_path("../..", __dir__)
  HELPER = File.join(ROOT, "test", "test_helper.rb")
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
  private_constant(:ROOT, :HELPER, :PROBE, :ALONE)

  # A test file of the probe project that calls the +methods+ of the probe.
  def probe_test(root, name, methods)
    File.write(File.join(root, "test", "#{name}_test.rb"), <<~RUBY)
      class #{name.capitalize}Test < Minitest::Test
        def test_probe = #{methods.inspect}.each { |method| Probe.public_send(method) }
      end
    RUBY
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

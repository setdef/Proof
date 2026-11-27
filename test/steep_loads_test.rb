# frozen_string_literal: true

require_relative("test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../tasks/steep_loads")

# Checks that the gate names each Steep target that fails to load, on projects
# made in a temporary folder.
class SteepLoadsTest < Minitest::Test
  # The Steepfile of two targets, each loading the given libraries.
  def steepfile(libraries)
    targets = libraries.map do |name, loaded|
      lines = loaded.map { |library| "  library \"#{library}\"\n" }
      "target :#{name} do\n  signature \"#{name}/sig\"\n  check \"#{name}/lib\"\n#{lines.join}end\n"
    end
    targets.join("\n")
  end

  # Makes a project of targets a and b in a folder that goes when the block ends. Target b's signature names
  # OptionParser, which Steep loads into target a as well, and +libraries+ says which libraries each target loads.
  def in_project(libraries:, b_signature: "class B < OptionParser\nend\n")
    Dir.mktmpdir("steep-loads-test") do |root|
      write(root, "Steepfile", steepfile(libraries))
      write(root, "a/sig/a.rbs", "class A\n  def n: () -> Integer\nend\n")
      write(root, "a/lib/a.rb", "class A\n  def n = 1\nend\n")
      write(root, "b/sig/b.rbs", b_signature)
      write(root, "b/lib/b.rb", "class B < OptionParser\nend\n")
      yield(root)
    end
  end

  def write(root, path, text)
    full = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, text)
  end

  def test_targets_that_all_load_have_no_failures
    in_project(libraries: { a: ["optparse"], b: ["optparse"] }) do |root|
      assert_empty(SteepLoads.failures(root))
    end
  end

  def test_a_target_that_lacks_a_library_a_signature_names_fails_naming_the_target_and_the_type
    in_project(libraries: { a: [], b: ["optparse"] }) do |root|
      failures = SteepLoads.failures(root)

      assert_equal(1, failures.size)
      assert_match(/\Aa fails to load: .*OptionParser/, failures.first)
    end
  end

  def test_a_failing_target_is_named_by_its_first_diagnostic_and_where_it_is
    in_project(libraries: { a: [], b: ["optparse"] }) do |root|
      assert_match(%r{\(b/sig/b\.rbs:1\)\z}, SteepLoads.failures(root).first)
    end
  end

  def test_each_failing_target_has_a_failure_of_its_own
    in_project(libraries: { a: [], b: [] }) do |root|
      assert_equal(%w[a b], SteepLoads.failures(root).map { |failure| failure.split.first })
    end
  end

  def test_no_signature_that_names_a_missing_library_means_no_failures
    in_project(libraries: { a: [], b: [] }, b_signature: "class B\nend\n") do |root|
      assert_empty(SteepLoads.failures(root))
    end
  end
end

# frozen_string_literal: true

require_relative("support/release_project")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../tasks/release_version")

# Checks that a release's version, stamped from its tag, reaches the version file and the lockfile, and that a tag
# that isn't a release's changes nothing. Each test stamps a throwaway copy of a small project, and never this checkout.
class ReleaseVersionTest < Minitest::Test
  include ReleaseProject

  # What a refused tag is: three plain integers, with an optional leading v, and nothing else.
  REFUSED = {
    a_prerelease: "v0.2.0-rc.1",
    a_build_suffix: "v0.2.0+build.5",
    a_fourth_number: %w[0 2 0 1].join("."),
    two_numbers: "0.2",
    a_leading_zero: "0.02.0",
    an_upper_case_v: "V0.2.0",
    a_name_and_not_a_number: "v0.x.0",
    a_trailing_newline: "v0.2.0\n",
    nothing: "",
  }.freeze
  private_constant(:REFUSED)

  def test_a_tag_with_a_v_gives_the_version_without_it_and_the_lockfile_agrees
    in_project do |root|
      assert_equal("0.2.0", ReleaseVersion.stamp(root, "v0.2.0"))
      assert_agree(root, "0.2.0")
    end
  end

  def test_a_tag_with_no_v_gives_the_same_version
    in_project do |root|
      assert_equal("10.20.30", ReleaseVersion.stamp(root, "10.20.30"))
      assert_agree(root, "10.20.30")
    end
  end

  REFUSED.each do |form, tag|
    define_method("test_#{form}_is_refused_and_nothing_changes") do
      in_project do |root|
        before = files(root)
        error = assert_raises(ReleaseVersion::Refusal) { ReleaseVersion.stamp(root, tag) }

        assert_includes(error.message, "three whole numbers")
        assert_equal(before, files(root))
      end
    end
  end

  def test_no_tag_is_refused
    in_project do |root|
      assert_raises(ReleaseVersion::Refusal) { ReleaseVersion.stamp(root, nil) }
    end
  end

  def test_a_version_file_with_no_version_is_a_failure_that_changes_nothing
    in_project do |root|
      File.write(File.join(root, "lib", "proof", "version.rb"), "module Proof\nend\n")
      before = files(root)

      assert_raises(ReleaseVersion::Failure) { ReleaseVersion.stamp(root, "v0.2.0") }
      assert_equal(before, files(root))
    end
  end

  def test_a_lockfile_that_can_not_be_made_is_a_failure_that_puts_the_version_back
    in_project do |root|
      File.write(File.join(root, "Gemfile"), "gemspec\ngem \"no-such-gem-in-this-project\", path: \"nowhere\"\n")
      before = files(root)
      error = assert_raises(ReleaseVersion::Failure) { ReleaseVersion.stamp(root, "v0.2.0") }

      assert_includes(error.message, "nowhere")
      assert_equal(before, files(root))
    end
  end
end

# frozen_string_literal: true

require_relative("test_helper")

# Checks the version the gem reports.
class UsageVersionTest < Minitest::Test
  # A version is MAJOR.MINOR.PATCH, with no prerelease suffix.
  def test_version_is_a_plain_release
    assert_match(/\A\d+\.\d+\.\d+\z/, Usage::VERSION)
  end
end

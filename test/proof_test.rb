# frozen_string_literal: true

require_relative("test_helper")

# Checks the version Proof reports.
class ProofTest < Minitest::Test
  # Releases are 0.X.Y, with no prerelease suffix such as -rc.1 or .pre.1.
  def test_version_is_a_plain_release_in_the_zero_series
    assert_match(/\A0\.\d+\.\d+\z/, Proof::VERSION)
  end
end

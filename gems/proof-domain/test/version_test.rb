# frozen_string_literal: true

require_relative("test_helper")

# Checks the version the domain gem reports.
class DomainVersionTest < Minitest::Test
  # Releases are 0.X.Y, as Proof's are, with no prerelease suffix.
  def test_version_is_a_plain_release_in_the_zero_series
    assert_match(/\A0\.\d+\.\d+\z/, Proof::Domain::VERSION)
  end
end

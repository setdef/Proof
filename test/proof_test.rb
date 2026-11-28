# frozen_string_literal: true

require_relative("test_helper")

# Checks the version Proof reports.
class ProofTest < Minitest::Test
  # A commit on trunk is a build that isn't a release, so its version is Fledge's default, 0.0.0. A release gets its
  # version in the checkout that builds it, and no commit.
  def test_the_committed_version_is_that_of_a_build_that_is_not_a_release
    assert_equal("0.0.0", Proof::VERSION)
  end
end

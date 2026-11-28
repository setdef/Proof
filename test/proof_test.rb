# frozen_string_literal: true

require_relative("test_helper")

# Checks the version Proof reports.
class ProofTest < Minitest::Test
  LOCKFILE = File.expand_path("../Gemfile.lock", __dir__)
  private_constant(:LOCKFILE)

  # Releases are 0.X.Y, with no prerelease suffix such as -rc.1 or .pre.1, and a build that isn't a release is 0.0.0.
  def test_version_is_a_plain_release_in_the_zero_series
    assert_match(/\A0\.\d+\.\d+\z/, Proof::VERSION)
  end

  # Frozen Bundler refuses a lockfile that differs from the gemspec, in a checkout of trunk and in one that
  # +rake release:stamp+ has stamped alike.
  def test_the_lockfile_locks_the_version_proof_reports
    assert_equal(Proof::VERSION, File.read(LOCKFILE)[/^    proof \(([^)]+)\)$/, 1])
  end
end

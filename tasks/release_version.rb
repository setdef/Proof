# frozen_string_literal: true

require "bundler"
require "open3"

# Stamps the version of a release into the checkout that builds it.
#
# Trunk commits a version of 0.0.0, which is a build that isn't a release. A
# release job stamps the version of its tag into its own checkout, so that
# +proof.gemspec+, +Gemfile.lock+, and +Proof::VERSION+ agree when Fledge
# builds, and nothing is committed. This class writes the version into
# +lib/proof/version.rb+ and then runs +bundle lock+. It checks only the form
# of the tag, and it never runs on the committed tree.
#
# === Examples
#
#   ReleaseVersion.stamp(".", "v0.2.0") # => "0.2.0"
#   ReleaseVersion.stamp(".", "0.2.0-rc.1") # raises ReleaseVersion::Refusal
class ReleaseVersion
  # Raised for a tag that isn't three whole numbers with an optional leading v. Nothing has changed.
  class Refusal < StandardError; end

  # Raised when the checkout can't take the version. Nothing has changed.
  class Failure < StandardError; end

  NUMBER = "(?:0|[1-9]\\d*)"
  TAG = /\Av?(?<version>#{NUMBER}\.#{NUMBER}\.#{NUMBER})\z/
  VERSION_FILE = File.join("lib", "proof", "version.rb")
  ASSIGNMENT = /VERSION = "[^"]+"/
  private_constant(:NUMBER, :TAG, :VERSION_FILE, :ASSIGNMENT)

  # Stamps the checkout in +root+ with the version of +tag+, and returns the version.
  def self.stamp(root, tag)
    new(tag).stamp(root)
  end

  # The release of +tag+, such as +v0.2.0+ or +0.2.0+. Raises Refusal for any other form.
  def initialize(tag)
    match = TAG.match(tag.to_s)
    raise(Refusal, <<~MESSAGE.chomp) unless match
      #{tag.to_s.inspect} is not a release. A release takes three whole numbers with no leading zeros, such as 0.2.0 or v0.2.0, and no suffix.
    MESSAGE

    @version = match[:version]
  end

  # Writes the version into +root+'s version file and locks. When the lock fails, puts the version file back and
  # raises Failure. Returns the version.
  def stamp(root)
    path = File.join(root, VERSION_FILE)
    before = File.read(path)
    raise(Failure, "#{VERSION_FILE} has no VERSION to stamp.") unless before.match?(ASSIGNMENT)

    File.write(path, before.sub(ASSIGNMENT, %(VERSION = "#{@version}")))
    lock(root, path, before)
    @version
  end

  # Runs +bundle lock+ in +root+, with the lockfile unfrozen whatever the environment says, and puts +before+ back in
  # +path+ when it fails.
  private def lock(root, path, before)
    output, status = Bundler.with_unbundled_env do
      Open3.capture2e({ "BUNDLE_FROZEN" => "false" }, "bundle", "lock", chdir: root)
    end
    return if status.success?

    File.write(path, before)
    raise(Failure, "bundle lock failed in #{root}:\n#{output}")
  end
end

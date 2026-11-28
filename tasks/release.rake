# frozen_string_literal: true

require_relative("release_version")

namespace :release do
  desc "Stamp a release's version into this checkout from its tag: rake release:stamp[v0.2.0]"
  task :stamp, [:tag] do |_task, arguments|
    # Rake splits the argument at each comma and would drop a second one, so the whole text goes to be refused.
    version = ReleaseVersion.stamp(Dir.pwd, arguments.to_a.join(","))
    puts("Stamped #{version} into lib/proof/version.rb and Gemfile.lock.")
  rescue ReleaseVersion::Refusal => e
    warn(e.message)
    exit(2)
  rescue ReleaseVersion::Failure => e
    abort(e.message)
  end
end

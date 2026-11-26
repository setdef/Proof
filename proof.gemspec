# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "proof"
  # Bundler evaluates this file before the tests start SimpleCov, so it reads
  # the version as text. Requiring lib/proof/version would run its lines
  # before coverage measures them.
  spec.version = File.read(File.expand_path("lib/proof/version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]
  spec.authors = ["setdef"]
  spec.email = ["kerrick@setdef.com"]
  spec.summary = "Run your project's tests and builds on your spare computers, from your working tree or any commit."
  spec.description = spec.summary
  spec.homepage = "https://github.com/setdef/Proof"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 4.1.0.a"

  # Reads the project file, which is KDL 2. The reader finds each node's line through
  # the parser's private methods, so it takes patch releases of 2.2 only. kdl's own
  # constraints on bigdecimal, base64, and simpleidn come with it.
  spec.add_dependency("kdl", "~> 2.2.0")
  # The durable store of runs: ROM's relations over Sequel and SQLite. They load when the store is built, never
  # with `require "proof"`.
  spec.add_dependency("rom", "~> 5.4")
  spec.add_dependency("rom-sql", "~> 3.7")
  spec.add_dependency("sequel", "~> 5.110")
  spec.add_dependency("sqlite3", "~> 2.10")

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/trunk/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "lib/**/*.json", "sig/**/*.rbs", "README.md", "CHANGELOG.md", "LICENSE"]
  spec.require_paths = ["lib"]
end

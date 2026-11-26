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

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/trunk/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "lib/**/*.json", "sig/**/*.rbs", "README.md", "CHANGELOG.md", "LICENSE"]
  spec.require_paths = ["lib"]
end

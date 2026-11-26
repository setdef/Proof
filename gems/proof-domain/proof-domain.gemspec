# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "proof-domain"
  # Bundler evaluates this file before the tests start SimpleCov, so it reads
  # the version as text. Requiring lib/proof/domain/version would run its lines
  # before coverage measures them.
  spec.version = File.read(File.expand_path("lib/proof/domain/version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]
  spec.authors = ["setdef"]
  spec.email = ["kerrick@setdef.com"]
  spec.summary = "The values and rules Proof's command, server, and runner share, with no dependencies."
  spec.description = spec.summary
  spec.homepage = "https://github.com/setdef/Proof"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 4.1.0.a"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs"]
  spec.require_paths = ["lib"]
end

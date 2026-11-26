# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "usage-rb"
  # Bundler evaluates this file before the tests start SimpleCov, so it reads
  # the version as text. Requiring lib/usage/version would run its lines
  # before coverage measures them.
  spec.version = File.read(File.expand_path("lib/usage/version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]
  spec.authors = ["setdef"]
  spec.email = ["kerrick@setdef.com"]
  spec.summary = "Reads the usage spec of a command-line interface, and prints its help, with no dependencies."
  spec.description = spec.summary
  spec.homepage = "https://github.com/setdef/Proof/tree/trunk/gems/usage-rb"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 4.1.0.a"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end

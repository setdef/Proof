# frozen_string_literal: true

require_relative("lint")

namespace :steep do
  desc "Type-check lib, the gems, and the tasks with Steep"
  task :check do
    sh("bundle exec steep check")
  end

  desc "Forbid 'untyped' in RBS files except approved exceptions"
  task :no_untyped do
    exceptions = File.expand_path("../rbs_exceptions.rb", __dir__)
    abort("tasks/rbs_exceptions.rb missing — re-scaffold to create it") unless File.exist?(exceptions)
    Lint.load(exceptions).enforce!(
      glob: "{sig,gems/*/sig}/**/*.rbs",
      pattern: /\buntyped\b/,
      reject_pattern: /^\s*#/,
      violation_name: "'untyped' in RBS files"
    )
  end
end

desc "Type-check the code with Steep, then fail on any untyped in an .rbs file"
task steep: %w[steep:check steep:no_untyped]

namespace :lint do
  desc "Run RBS linting (no unapproved untyped)"
  task rbs: "steep:no_untyped"
end

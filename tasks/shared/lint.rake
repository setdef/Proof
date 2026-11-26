# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
# SPDX-License-Identifier: MIT
#++

require "inch/rake"
require "rubocop/rake_task"
require "rubycritic/rake_task"
require_relative("reuse_fixer")

RuboCop::RakeTask.new

# Run rubycritic in a shell to prevent it from exiting the rake process
desc "Run RubyCritic"
task :rubycritic do
  sh("bundle exec rubycritic --no-browser lib sig")
end

Inch::Rake::Suggest.new("doc:suggest", "lib/**/*.rb", "sig/**/*.rbs") do |suggest|
  suggest.args << ""
end

namespace :reuse do
  desc "Run the REUSE Tool to confirm REUSE compliance"
  task :lint do
    sh("reuse lint")
  end

  desc "Add SPDX headers to files missing them (per AGENTS.md standards)"
  task :fix do
    ReuseFixer.new.annotate_missing
  end

  desc "Normalize Ruby files: frozen_string_literal at top, SPDX in #--/#++ block"
  task :normalize_ruby do
    ReuseFixer.new.normalize_ruby
  end
end

desc "Run the REUSE Tool to confirm REUSE compliance"
task reuse: "reuse:lint"

namespace :lint do
  desc "Check that every public class and method has RDoc"
  task :safe_rdoc_coverage do
    sh("bundle exec rake rdoc:coverage")
  end

  desc "Run the documentation lints"
  task docs: %w[safe_rdoc_coverage rubycritic reuse:lint]

  desc "Run the code lints"
  task code: %w[rubocop rubycritic]

  desc "Run the license lint"
  task licenses: %w[reuse:lint]

  desc "Run every lint"
  task all: %w[docs code licenses rbs]

  namespace :fix do
    desc "Auto-fix RuboCop offenses (most aggressive)"
    task :rubocop do
      sh("bundle exec rubocop --autocorrect-all")
    end

    desc "Add SPDX headers and normalize Ruby file structure"
    task reuse: %w[reuse:fix reuse:normalize_ruby]

    desc "Run all auto-fix tasks"
    task all: %w[lint:fix:rubocop lint:fix:reuse]
  end
end

desc "Run all lint auto-fix tasks"
task "lint:fix": "lint:fix:all"

# Aliases for convenience
desc "Auto-fix RuboCop offenses (alias of lint:fix:rubocop)"
task "rubocop:autocorrect_all": "lint:fix:rubocop"

desc "Run all lint tasks"
task lint: "lint:all"

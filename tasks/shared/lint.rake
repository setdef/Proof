# frozen_string_literal: true

require "inch/rake"

# RuboCop runs in a process of its own. Its configuration loader changes the working directory of the process that
# loads it, so RuboCop::RakeTask, which runs it inside rake, would send a check running beside it in another thread
# to the wrong folder.
desc "Run RuboCop, every cop on, over the Ruby, the RBS, and the Ruby in the Markdown"
task :rubocop do
  sh("bundle exec rubocop")
end

namespace :rubocop do
  desc "Autocorrect the RuboCop offenses that are safe to autocorrect"
  task :autocorrect do
    sh("bundle exec rubocop --autocorrect")
  end
end

Inch::Rake::Suggest.new("doc:suggest", "{lib,gems/*/lib}/**/*.rb", "{sig,gems/*/sig}/**/*.rbs") do |suggest|
  suggest.args << ""
end

namespace :reuse do
  desc "Fail when a file has no copyright and license that REUSE can read, in the file or in REUSE.toml"
  task :lint do
    sh("reuse lint")
  end
end

desc "Run reuse:lint"
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

    desc "Run all auto-fix tasks"
    task all: %w[lint:fix:rubocop]
  end
end

desc "Run all lint auto-fix tasks"
task "lint:fix": "lint:fix:all"

# Aliases for convenience
desc "Auto-fix RuboCop offenses (alias of lint:fix:rubocop)"
task "rubocop:autocorrect_all": "lint:fix:rubocop"

desc "Run all lint tasks"
task lint: "lint:all"

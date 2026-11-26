# frozen_string_literal: true

require "minitest/test_task"
require "rbconfig"
require "shellwords"

# Clear the default test task created by Minitest::TestTask if it exists
Rake::Task["test"].clear if Rake::Task.task_defined?("test")

desc "Run all tests (the same as test:ruby)"
task test: "test:ruby"

namespace :test do
  # Create a specific Minitest task for Ruby core tests
  Minitest::TestTask.create(:core) do |t|
    t.test_globs = ["test/**/*.rb", "gems/*/test/**/*_test.rb"]
    # The test files load in random order, and SimpleCov starts in test/test_helper.rb. The usage gem's tests load
    # a helper of their own, which knows nothing of SimpleCov, so the root helper loads first.
    t.test_prelude = %(require "test/test_helper")
  end
  # The gate runs test:ruby. This one process is for a debugger, or for TESTOPTS="-n NAME" to run one test.
  Rake::Task["test:core"].clear_comments
  Rake::Task["test:core"].comment = "Run all tests in this one process, with no parallel workers"

  # One process runs a whole slice of files, so a worker's SimpleCov holds only its slice. SimpleCov merges the
  # slices when the last worker ends, and fails the run below 100% of the lines and branches of the whole suite.
  # --group-by found deals the files out one at a time, which spreads the files that start git over the workers.
  # Grouping by file size piles those, the largest files, onto a few workers.
  desc "Run all Ruby tests in parallel processes, and fail below 100% line and branch coverage"
  task :ruby do
    # A resultset an earlier run left would merge into this run's coverage.
    FileUtils.rm_f(Dir.glob("coverage/.resultset.json*"))
    # What each worker's Ruby loads before its test files: Ruby's warnings, the bundle, and the root helper, which
    # starts SimpleCov before the code under test. It goes in the command rather than in RUBYOPT, which every Ruby
    # that a test starts would inherit.
    worker = [RbConfig.ruby, "-w", "-rbundler/setup", "-r./test/test_helper"].shelljoin
    folders = ["test", *Dir.glob("gems/*/test")].shelljoin
    env = [["PARALLEL_TESTS_EXECUTABLE", worker]].to_h
    sh(env, "bundle exec parallel_test --type test --group-by found #{folders}")
  end
end

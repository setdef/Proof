# frozen_string_literal: true

require "minitest/test_task"

# Clear the default test task created by Minitest::TestTask if it exists
Rake::Task["test"].clear if Rake::Task.task_defined?("test")

desc "Run all tests"
task test: "test:ruby"

namespace :test do
  # Create a specific Minitest task for Ruby core tests
  Minitest::TestTask.create(:core) do |t|
    t.test_globs = ["test/**/*.rb", "gems/*/test/**/*_test.rb"]
    # The test files load in random order, and SimpleCov starts in test/test_helper.rb. The usage gem's tests load
    # a helper of their own, which knows nothing of SimpleCov, so the root helper loads first.
    t.test_prelude = %(require "test/test_helper")
  end

  desc "Run all Ruby tests"
  task ruby: ["test:core"]
end

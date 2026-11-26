# frozen_string_literal: true

# SimpleCov starts before anything from lib loads, so it sees every line.
require "simplecov"

SimpleCov.start do
  # A deprecated SimpleCov setting raises instead of warning.
  deprecations(:raise)
  cover("lib/**/*.rb")
  cover("gems/*/lib/**/*.rb")
  cover("tasks/critic_faults.rb")
  cover("tasks/doc_examples.rb")
  cover("tasks/doc_examples/**/*.rb")
  cover("tasks/ruby_doc_comments.rb")
  enable_coverage(:branch)
  minimum_coverage(line: 100, branch: 100)
  coverage(:line) { minimum(100, per: :file) }
  coverage(:branch) { minimum(100, per: :file) }
  # Merging would add the coverage of an earlier run, named differently, to this
  # run's, and report lines no test in this run executes.
  merging(false)
  refuse_coverage_drop
end

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "proof"

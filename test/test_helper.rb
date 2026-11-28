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
  cover("tasks/release_version.rb")
  cover("tasks/steep_loads.rb")
  cover("tasks/doc_examples/**/*.rb")
  cover("tasks/ruby_doc_comments.rb")
  enable_coverage(:branch)
  minimum_coverage(line: 100, branch: 100)
  coverage(:line) { minimum(100, per: :file) }
  coverage(:branch) { minimum(100, per: :file) }
  # Merging would add the coverage of an earlier run, named differently, to this
  # run's, and report lines no test in this run executes. A parallel run is the
  # exception: each worker holds a slice of the suite, so the run's coverage is
  # the merge of the workers' slices. rake test:ruby deletes the earlier
  # resultsets before it starts the workers.
  merging(ENV.key?("TEST_ENV_NUMBER"))
  refuse_coverage_drop
end

require "minitest/autorun"

# Two warnings that Proof's code can't fix, which this drops by their text, so every other warning still shows.
# protocol-http 0.72.1, which Falcon loads, assigns a rescued error to a variable it never reads, and Ruby's -w warns of
# it when the server's HTTPS loads. The fiber scheduler reads files through IO::Buffer, and Ruby warns once that
# IO::Buffer is experimental; Proof::Server.serve turns that warning off, and the tests that serve without it see it.
module IgnoredWarnings
  IGNORED = [
    %r{/protocol-http-[^/]+/lib/protocol/http/body/streamable\.rb:\d+: warning: assigned but unused variable},
    /: warning: IO::Buffer is experimental /,
  ].freeze
  private_constant(:IGNORED)

  def warn(message, ...)
    super unless IGNORED.any? { |pattern| pattern.match?(message) }
  end
end
Warning.singleton_class.prepend(IgnoredWarnings)

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "proof"

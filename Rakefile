# frozen_string_literal: true

require "rdoc/task"

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = ENV.fetch("RDOC_OUTPUT", "tmp/rdoc")
  # The documentation lives in sig/**/*.rbs, which RDoc reads only as input.
  rdoc.rdoc_files.include("lib/**/*.rb", "sig/**/*.rbs", "gems/*/lib/**/*.rb", "gems/*/sig/**/*.rbs")
end

# Import shared quality tasks (owned by ruby_quality) plus per-repo tasks.
Dir.glob("tasks/**/*.rake").each { |r| import(r) }

# Default runs gates only, never fixers. Its checks are independent, so they
# run at once, each on the cores it needs, and the longest one sets the time.
desc "Run every check of the gate at once: tests, RuboCop, Steep, RubyCritic, REUSE, RDoc coverage, docs, CLI spec"
multitask default: %w[
  bundle:frozen
  test:ruby
  rubocop
  rubycritic
  steep
  steep:loads
  reuse:lint
  rdoc:coverage
  docs:placement
  docs:examples
  usage:lint
  usage:references
]

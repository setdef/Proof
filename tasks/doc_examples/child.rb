# frozen_string_literal: true

require "json"
require_relative("comparison")
require_relative("outcome")

module DocExamples
  # Runs the examples of one file, in the process it is called from, and
  # records each one that is wrong.
  #
  # Each block runs in one scope, in order, so a variable a block sets is
  # there for the next. The instrumented code of a block reports each
  # +# =>+ comparison through a local variable of that scope.
  class Child
    LOCAL = :doc_examples_checker
    public_constant(:LOCAL)

    # Runs the blocks that the file at +arguments[0]+ lists, in JSON, and
    # writes the failures, in JSON, to the file at +arguments[1]+. Examples
    # run in +scope+, which is the top level when the child is its own process.
    def self.main(arguments, scope: TOPLEVEL_BINDING)
      blocks_path, results_path = arguments
      entries = JSON.parse(File.read(blocks_path.to_s), symbolize_names: true)
      File.write(results_path.to_s, JSON.generate(new(scope).run(entries)))
    end

    # A child that runs examples in +scope+, a Binding.
    def initialize(scope)
      @scope = scope
      @failures = []
      scope.local_variable_set(LOCAL, self)
    end

    # Runs each block in +entries+, hashes with +path+, +line+, +code+, and
    # +raises+. The failures are one line each, and empty when all pass.
    def run(entries)
      entries.each { |entry| run_block(entry) }
      @failures
    end

    # Compares what an expression returned with the value written after its
    # +# =>+, and records a failure when they differ. Returns +actual+.
    def check(actual, expected_source, where)
      problem = mismatch(actual, expected_source)
      @failures.push("#{where}: #{problem}") if problem
      actual
    end

    # What is wrong with +actual+, or nil when it matches the value that
    # +expected_source+ gives.
    private def mismatch(actual, expected_source)
      Comparison.mismatch(actual, @scope.eval(expected_source))
    rescue ScriptError, StandardError => e
      "can't read #{expected_source} as a Ruby value: #{e.message.lines.first.to_s.strip}"
    end

    # Runs one block and records how it ended.
    private def run_block(entry)
      problem = Outcome.of(@scope, entry)
      @failures.push(problem) if problem
    end
  end
end

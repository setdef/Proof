# frozen_string_literal: true

require "parallel"
require "parallel_tests"
require_relative("extractor")
require_relative("instrumenter")
require_relative("report")
require_relative("subprocess")

module DocExamples
  # Runs the examples of each file, one fresh Ruby process for each, and as many
  # at a time as the tests run in processes: PARALLEL_TEST_PROCESSORS when it is
  # set, else one for each processor of the computer.
  class Runner
    # The entry that runs a block, or nil after adding the fault that keeps the
    # block from running to +faults+.
    def self.entry_for(block, faults)
      { path: block.path, line: block.line, code: Instrumenter.call(block), raises: block.raises }
    rescue Fault => e
      faults.push(e.message)
      nil
    end

    # A runner for the project at +root+. Each process requires +requires+, a
    # list of library names, before its first example.
    def initialize(root, requires)
      @root = root
      @requires = requires
    end

    # The report for the files at +paths+, relative to the root. The failures
    # come in the order of the paths, whichever process finishes first.
    def check(paths)
      # A thread only waits for its process, so threads cost no more than a
      # pool of processes would. The parallel_tests gem reads the variable for
      # the tests, so the examples read it the same way.
      Report.combine(
        Parallel.map(paths, in_threads: ParallelTests.determine_number_of_processes(nil)) do |path|
          check_file(path)
        end
      )
    end

    # Extracts, instruments, and runs the examples of one file.
    private def check_file(path)
      skipped, runnable = blocks_in(path).partition(&:skipped?)
      entries, faults = instrument(runnable)
      failures = faults + skipped.filter_map(&:missing_reason) + Subprocess.new(@root, @requires, path).run(entries)
      Report.new(ran: entries.size, skipped: skipped.map(&:skip_line), failures:)
    end

    # The blocks in the file at +path+.
    private def blocks_in(path)
      Extractor.blocks(File.read(File.join(@root, path), encoding: "UTF-8"), path)
    end

    # The entries to run, and the faults of the blocks that can't be checked.
    private def instrument(blocks)
      # @type var faults: Array[String]
      faults = []
      [blocks.filter_map { |block| self.class.entry_for(block, faults) }, faults]
    end
  end
end

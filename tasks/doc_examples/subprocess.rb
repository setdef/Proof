# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "tmpdir"

module DocExamples
  # Runs the entries of one file in a Ruby process of its own, in a temporary
  # folder, with the libraries of the project on its load path.
  class Subprocess
    CHILD = File.expand_path("child.rb", __dir__.to_s)
    MAIN = "DocExamples::Child.main(ARGV)"
    private_constant(:CHILD, :MAIN)

    # The failure of a process that ran +path+'s examples and ended in
    # +status+ before it finished, with its +output+, or nil when it finished.
    def self.crash(path, status, output)
      return if status.success?

      "#{path}: Ruby exited with status #{status.exitstatus} before it finished the examples:\n#{output}"
    end

    # A process that runs the examples of the file at +path+ in the project at
    # +root+, after it requires +requires+, a list of library names.
    def initialize(root, requires, path)
      @root = root
      @requires = requires
      @path = path
    end

    # The failures the examples report, or one line for a process that ends
    # before it finishes. No entries run no process.
    def run(entries)
      return [] if entries.empty?

      Dir.mktmpdir("doc-examples") { |dir| run_in(dir, entries) }
    end

    # Runs the entries in a process whose working folder is +dir+.
    private def run_in(dir, entries)
      results = File.join(dir, "results.json")
      output, status = spawn_child(dir, entries, results)
      crash = self.class.crash(@path, status, output)
      crash ? [crash] : JSON.parse(File.read(results))
    end

    # Runs the entries in a Ruby process that writes its failures to +results+,
    # and returns its output and exit status.
    private def spawn_child(dir, entries, results)
      blocks = File.join(dir, "blocks.json")
      File.write(blocks, JSON.generate(entries))
      Open3.capture2e(*command(blocks, results), chdir: dir)
    end

    # The command for the process.
    private def command(blocks_path, results_path)
      [RbConfig.ruby, *options, "-r", CHILD, "-e", MAIN, blocks_path, results_path]
    end

    # The options that put the project's libraries on the load path, and
    # require the libraries the process was asked for.
    private def options
      load_path = Dir.glob(File.join(@root, "{lib,gems/*/lib}"))
      load_path.flat_map { |dir| ["-I", dir] } + @requires.flat_map { |name| ["-r", name] }
    end
  end
end

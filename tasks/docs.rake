# frozen_string_literal: true

require_relative("doc_examples")
require_relative("ruby_doc_comments")

Rake::Task["rdoc:coverage"].clear_comments
Rake::Task["rdoc:coverage"].comment = "Fail when a public class, module, constant, or method has no RDoc"

namespace :docs do
  desc "Fail when a comment in lib sits above a definition, where RDoc would take it as documentation"
  task :placement do
    faults = Dir.glob("{lib,gems/*/lib}/**/*.rb").flat_map { |path| RubyDocComments.in_source(File.read(path), path) }
    next puts("No comment in lib sits above a definition.") if faults.empty?

    abort(faults.join("\n"))
  end

  desc "Run the Ruby examples in the Markdown pages and the .rbs comments, and fail on one that is wrong"
  task :examples do
    # The examples of Proof's own classes assume `proof` is loaded, as it is in the app.
    report = DocExamples.check(Dir.pwd, %w[proof])
    puts(report.summary)
    abort(report.failures.join("\n")) unless report.ok?
  end
end

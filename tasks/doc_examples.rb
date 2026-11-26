# frozen_string_literal: true

require "open3"
require_relative("doc_examples/report")
require_relative("doc_examples/runner")

# Runs the Ruby examples in Proof's documentation and fails on each one that
# is wrong.
#
# An example is a fenced +ruby+ block in a Markdown page, or in a comment of an
# +.rbs+ file. Proof documents its API there, and RDoc reads those comments as
# Markdown. A wrong example is documentation that misleads, so the gate runs
# them all.
#
# A block's first line may be +# Wrong: raises ErrorClass+, and then the block
# must raise that error. A line <tt><!-- skip-example: reason --></tt> directly
# before a block skips it, and the run reports each skipped block.
#
# === Examples
#
#   DocExamples.check(Dir.pwd).failures
#   # => ["doc/guides/a.md:12: expected 3, but got 2"]
module DocExamples
  # The pages Git tracks that a tool generates, which no one edits by hand.
  GENERATED = %w[doc/reference/cli.md skills/proof/references/cli.md].freeze
  # What Git lists: tracked files, and untracked files it doesn't ignore.
  LISTING = %w[ls-files -z --cached --others --exclude-standard -- *.md *.rbs].freeze
  private_constant(:GENERATED, :LISTING)

  # The report for the documentation files of the project at +root+, the
  # Markdown pages and +.rbs+ files that Git tracks or would track. Each
  # file's process requires +requires+, a list of library names, before its
  # first example.
  def self.check(root, requires = [])
    Runner.new(root, requires).check(files(root))
  end

  # The paths, relative to +root+, of the files whose examples run: the
  # Markdown pages and +.rbs+ files that Git tracks, and those it doesn't
  # ignore, except the generated pages and the files deleted from the folder.
  def self.files(root)
    listing, = Open3.capture2("git", *LISTING, chdir: root)
    paths = listing.split("\0").sort - GENERATED
    paths.select { |path| File.file?(File.join(root, path)) }
  end
end

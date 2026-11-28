# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative("../git_fixtures")

# Helpers for the tests that run the examples of a project made in a temporary
# folder.
module DocExamplesProject
  include GitFixtures

  # Runs the block with a new Git repository in a temporary folder.
  def in_project
    Dir.mktmpdir("doc-examples-test") do |root|
      git(root, "init", "--quiet")
      yield(root)
    end
  end

  # Writes a file under +root+.
  def write(root, path, text)
    FileUtils.mkdir_p(File.dirname(File.join(root, path)))
    File.write(File.join(root, path), text)
  end

  # A Markdown page with one Ruby block, whose first line of code is line 4.
  def page(*lines)
    "# A page\n\n```ruby\n#{lines.join("\n")}\n```\n"
  end
end

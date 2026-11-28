# frozen_string_literal: true

require_relative("../test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../../tasks/doc_examples")
require_relative("project")

# Checks which files a run takes the examples from.
class DocExamplesFilesTest < Minitest::Test
  include DocExamplesProject

  def test_the_generated_references_are_not_checked
    in_project do |root|
      write(root, "docs/reference/cli.md", page("raise 'no'"))
      write(root, "skills/proof/references/cli.md", page("raise 'no'"))
      write(root, "skills/proof/references/other.md", page("1 # => 1"))

      assert_equal(1, DocExamples.check(root).ran)
    end
  end

  def test_files_that_git_ignores_are_not_checked_and_untracked_ones_are
    in_project do |root|
      write(root, ".gitignore", "tmp/\n")
      write(root, "tmp/a.md", page("raise 'no'"))
      write(root, "doc/a.md", page("1 # => 1"))

      assert_equal(["doc/a.md"], DocExamples.files(root))
    end
  end

  def test_a_file_git_tracks_but_the_folder_no_longer_has_is_not_checked
    in_project do |root|
      write(root, "doc/a.md", page("1 # => 1"))
      _, status = Open3.capture2("git", "add", "doc/a.md", chdir: root)
      File.delete(File.join(root, "doc/a.md"))

      assert_predicate(status, :success?)
      assert_empty(DocExamples.files(root))
    end
  end

  def test_other_files_are_not_checked
    in_project do |root|
      write(root, "lib/a.rb", "# ```ruby\n# raise 'no'\n# ```\n")
      write(root, "notes.txt", page("raise 'no'"))

      assert_empty(DocExamples.files(root))
    end
  end
end

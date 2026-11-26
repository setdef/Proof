# frozen_string_literal: true

require_relative("git_fixtures")

# Checks what the commit of a working tree records for a submodule.
class GitProjectSubmoduleTest < Minitest::Test
  include GitFixtures

  # The ID that the commit's tree records for the path `vendor/sub`, or nil when it records none.
  def recorded_in(folder, commit)
    line = git(folder, "ls-tree", commit, "vendor/sub").lines.first
    line&.split&.values_at(0, 2)
  end

  # Command design, "Which project and which code": "Submodules go at the commits the superproject
  # records; their objects may live in the superproject's `.git/modules/NAME`, not in the submodule's
  # checkout." The submodule's `.git` is a file that points there.
  def test_a_submodule_is_in_the_commit_at_the_commit_the_project_records
    folder, recorded = make_project_with_submodule

    assert_equal(["160000", recorded], recorded_in(folder, working_tree_commit(folder)))
    assert_path_exists(File.join(folder, ".git", "modules", "vendor", "sub"))
    assert_path_exists(File.join(folder, "vendor", "sub", ".git"))
  end

  # The same sentence, for a submodule whose checkout has moved on: a commit made there is not one the
  # project records, so the working-tree commit keeps the commit that the project records.
  def test_a_submodule_checkout_that_has_moved_on_stays_at_the_recorded_commit
    folder, recorded = make_project_with_submodule
    commit_file(File.join(folder, "vendor", "sub"), "lib.txt", "2")
    moved = git(File.join(folder, "vendor", "sub"), "rev-parse", "HEAD").chomp

    refute_equal(recorded, moved)
    assert_equal(["160000", recorded], recorded_in(folder, working_tree_commit(folder)))
  end

  # Command design, "Which project and which code": "Uncommitted changes inside a submodule are not sent."
  def test_uncommitted_changes_inside_a_submodule_are_not_in_the_commit
    folder, recorded = make_project_with_submodule
    write_file(File.join(folder, "vendor", "sub"), "lib.txt", "changed")
    write_file(File.join(folder, "vendor", "sub"), "new.txt", "new")
    commit = working_tree_commit(folder)

    assert_equal([".gitmodules", "a.txt", "vendor/sub"], tree(folder, commit).map(&:first))
    assert_equal(["160000", recorded], recorded_in(folder, commit))
  end

  # The working tree as it is: a submodule removed from it is not in the commit.
  def test_a_submodule_removed_from_the_working_tree_is_not_in_the_commit
    folder, = make_project_with_submodule
    FileUtils.rm_rf(File.join(folder, "vendor", "sub"))

    assert_nil(recorded_in(folder, working_tree_commit(folder)))
  end

  # Command design, "Which project and which code": the clone's index stays as it was, a submodule included.
  def test_the_index_of_a_project_with_a_submodule_is_as_it_was
    folder, = make_project_with_submodule
    commit_file(File.join(folder, "vendor", "sub"), "lib.txt", "2")
    before = File.binread(File.join(folder, ".git", "index"))
    working_tree_commit(folder)

    assert_equal(before, File.binread(File.join(folder, ".git", "index")))
  end
end

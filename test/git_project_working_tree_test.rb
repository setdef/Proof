# frozen_string_literal: true

require_relative("git_fixtures")

# Checks what the commit of a project's working tree holds.
class GitProjectWorkingTreeTest < Minitest::Test
  include GitFixtures

  # Command design, "Which project and which code": "A working-tree run is a synthetic commit made
  # without touching the clone", and the glossary's "working-tree commit". A change not committed is in it.
  def test_the_commit_holds_a_change_that_is_not_committed
    folder = make_repository
    commit_file(folder, "a.txt", "committed")
    write_file(folder, "a.txt", "changed")
    commit = working_tree_commit(folder)

    assert_equal("changed", git(folder, "show", "#{commit}:a.txt"))
  end

  # Command design, "Which project and which code": "`git add -A` with untracked files that aren't ignored".
  def test_an_untracked_file_that_is_not_ignored_is_in_the_commit
    folder = make_repository
    commit_file(folder)
    write_file(folder, "dir/new.txt", "new")

    assert_equal("new", git(folder, "show", "#{working_tree_commit(folder)}:dir/new.txt"))
  end

  # The same sentence: an untracked file that `.gitignore` matches stays out.
  def test_an_untracked_file_that_gitignore_matches_is_left_out
    folder = make_repository
    commit_file(folder, ".gitignore", "*.log\nbuild/\n")
    write_file(folder, "debug.log", "noise")
    write_file(folder, "build/out.o", "object")
    paths = tree(folder, working_tree_commit(folder)).map(&:first)

    assert_equal([".gitignore"], paths)
  end

  # Command design, "Which project and which code": "A tracked file that `.gitignore` matches must
  # still be sent. A working-tree commit built from an index that starts empty drops it".
  def test_a_tracked_file_that_gitignore_matches_is_in_the_commit
    folder = make_repository
    write_file(folder, ".gitignore", "*.log\n")
    write_file(folder, "kept.log", "tracked")
    commit_all_with_ignored(folder)
    write_file(folder, "kept.log", "tracked and changed")
    commit = working_tree_commit(folder)

    assert_equal(
      [[".gitignore", "kept.log"], "tracked and changed"],
      [tree(folder, commit).map(&:first), git(folder, "show", "#{commit}:kept.log")]
    )
  end

  # A file deleted from the working tree is not in the working tree.
  def test_a_deleted_file_is_not_in_the_commit
    folder = make_repository
    commit_file(folder, "gone.txt")
    File.delete(File.join(folder, "gone.txt"))
    write_file(folder, "stays.txt", "1")

    assert_equal(["stays.txt"], tree(folder, working_tree_commit(folder)).map(&:first))
  end

  # Command design, "Which project and which code": "`git commit-tree` with `HEAD` as parent."
  def test_the_commit_has_head_as_its_only_parent
    folder = make_repository
    commit_file(folder, "a.txt", "1")
    head = commit_file(folder, "a.txt", "2")
    commit = working_tree_commit(folder)

    assert_equal(head, git(folder, "rev-list", "--parents", "-n1", commit).split.drop(1).join(" "))
  end

  # How-proof-works, "How your code reaches a runner": "the same files you have, with the same file modes,
  # symbolic links" as Git records them.
  def test_file_modes_and_symbolic_links_are_as_git_records_them
    folder = make_repository
    commit_file(folder)
    write_file(folder, "run.sh", "#!/bin/sh\n")
    File.chmod(0o755, File.join(folder, "run.sh"))
    File.symlink("a.txt", File.join(folder, "link"))

    assert_equal(
      [["a.txt", "100644"], ["link", "120000"], ["run.sh", "100755"]],
      tree(folder, working_tree_commit(folder))
    )
  end
end

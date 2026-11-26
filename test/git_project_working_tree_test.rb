# frozen_string_literal: true

require_relative("git_fixtures")

# Checks what the commit of a project's working tree holds.
class GitProjectWorkingTreeTest < Minitest::Test
  include GitFixtures

  # Command design, "Which project and which code": "A working-tree run uses a working-tree commit made
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

  # A project with no commit yet has no `HEAD` to be the parent, and a run in a new repository is not
  # refused for that: its working-tree commit has no parent, and holds the files that Git doesn't ignore.
  def test_a_project_with_no_commit_gets_a_commit_with_no_parent
    folder = make_repository
    write_file(folder, ".gitignore", "*.log\n")
    write_file(folder, "a.txt", "1")
    write_file(folder, "debug.log", "noise")
    commit = working_tree_commit(folder)

    assert_equal([".gitignore", "a.txt"], tree(folder, commit).map(&:first))
    assert_equal([commit], git(folder, "rev-list", "--parents", "-n1", commit).split)
  end

  # The same sentence, for a project whose first commit is still to come and that has nothing in it.
  def test_a_project_with_no_commit_and_no_file_gets_a_commit_of_an_empty_tree
    folder = make_repository
    commit = working_tree_commit(folder)

    assert_empty(tree(folder, commit))
    assert_equal([commit], git(folder, "rev-list", "--parents", "-n1", commit).split)
  end

  # Command design, "Which project and which code": "A working-tree run works in a project with no commit
  # yet, so a run in a new repository isn't refused." In such a project, "The clone's index, `HEAD`, and
  # branches stay exactly as they were" includes the branch that `HEAD` points to, which stays without a commit.
  def test_making_the_commit_in_a_project_with_no_commit_leaves_the_clone_as_it_was
    folder = make_repository
    write_file(folder, "a.txt", "1")
    git(folder, "add", "a.txt")
    write_file(folder, "a.txt", "2")
    state = -> { [File.binread(File.join(folder, ".git", "index")), File.read(File.join(folder, ".git", "HEAD"))] }
    before = state.call
    working_tree_commit(folder)

    assert_equal(before, state.call)
    assert_equal(["ref: refs/heads/trunk\n", ""], [before.last, git(folder, "for-each-ref")])
  end

  # Only a HEAD with no commit means a commit with no parent. A git that fails some other way, here with
  # status 128 as a damaged repository does, is an error, not a project with no commit.
  def test_a_git_failure_that_is_not_a_missing_commit_is_not_taken_for_a_project_with_no_commit
    program = File.join(temporary_folder, "damaged-git")
    File.write(program, "#!/bin/sh\ncase \"$1\" in config) exit 0 ;; esac\necho 'fatal: damaged' >&2\nexit 128\n")
    File.chmod(0o755, program)
    project = Proof::GitProject.new(root: temporary_folder, program:)
    error = assert_raises(Proof::GitFailedError) { project.working_tree_commit_id }

    assert_equal([128, "fatal: damaged\n"], [error.status.exitstatus, error.error_output])
  end
end

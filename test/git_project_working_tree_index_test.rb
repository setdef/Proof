# frozen_string_literal: true

require_relative("git_fixtures")
require "digest"

# Checks how the commit of a project's working tree treats the clone's index.
class GitProjectWorkingTreeIndexTest < Minitest::Test
  include GitFixtures

  # "Your working tree as it is" to a person who staged a file: a file staged with `git add -f` that
  # `.gitignore` matches, and never committed, goes the way `git commit` would send it.
  def test_a_staged_file_that_gitignore_matches_and_was_never_committed_is_in_the_commit
    folder = make_repository
    commit_file(folder, ".gitignore", "*.log\n")
    write_file(folder, "forced.log", "staged")
    git(folder, "add", "-f", "forced.log")

    assert_equal("staged", git(folder, "show", "#{working_tree_commit(folder)}:forced.log"))
  end

  # Command design, "Which project and which code": "The clone's index, `HEAD`, and branches stay exactly
  # as they were." With a split index and an untracked cache set, Git still adds no shared index file, and
  # no file under `.git` changes, apart from the objects.
  def test_making_the_commit_changes_no_file_in_the_clone_whatever_its_index_settings
    folder = make_clone_with_split_index
    before = digests(File.join(folder, ".git"))
    working_tree_commit(folder)

    assert_equal(before, digests(File.join(folder, ".git")))
    assert_equal(1, before.keys.grep(/sharedindex/).size)
  end

  # The same requirement when the clone sets a file-system monitor: starting one adds a socket to `.git`
  # and leaves a process running, so Proof must not start it. The monitor here is a program that records
  # that Git ran it.
  def test_a_file_system_monitor_set_in_the_clone_is_not_started
    folder = make_repository
    commit_file(folder)
    marker = File.join(temporary_folder, "monitor-ran")
    monitor = File.join(temporary_folder, "monitor")
    File.write(monitor, "#!/bin/sh\ntouch #{marker}\n")
    File.chmod(0o755, monitor)
    git(folder, "config", "core.fsmonitor", monitor)
    write_file(folder, "a.txt", "2")
    working_tree_commit(folder)

    refute_path_exists(marker)
  end

  # A linked worktree has its own index. The commit starts from that one, so a file staged there that
  # `.gitignore` matches is in it, and neither the worktree's folder under `.git` nor the rest changes.
  def test_a_linked_worktree_starts_from_its_own_index_and_changes_no_file_in_the_clone
    main = make_repository
    commit_file(main, ".gitignore", "*.log\n")
    linked = File.join(temporary_folder, "linked")
    git(main, "worktree", "add", "--quiet", "--detach", linked)
    write_file(linked, "forced.log", "staged")
    git(linked, "add", "-f", "forced.log")
    before = digests(File.join(main, ".git"))
    commit = working_tree_commit(linked)

    assert_equal(before, digests(File.join(main, ".git")))
    assert_equal([".gitignore", "forced.log"], tree(linked, commit).map(&:first))
  end

  # A clone whose index another Git process is writing, which shows as `index.lock`, still gets its
  # commit, and the lock, which is that process's, stays exactly as it was.
  def test_a_clone_whose_index_is_locked_by_another_git_process_gets_its_commit_and_keeps_the_lock
    folder = make_repository
    commit_file(folder)
    write_file(folder, "new.txt", "new")
    File.write(File.join(folder, ".git", "index.lock"), "held by another process")
    before = digests(File.join(folder, ".git"))
    commit = working_tree_commit(folder)

    assert_equal(before, digests(File.join(folder, ".git")))
    assert_equal(["a.txt", "new.txt"], tree(folder, commit).map(&:first))
  end

  # A repository with a split index and an untracked cache, and a changed and a new file.
  private def make_clone_with_split_index
    folder = make_repository
    commit_file(folder, "a.txt", "1")
    %w[core.splitIndex core.untrackedCache].each { |setting| git(folder, "config", setting, "true") }
    write_file(folder, "a.txt", "2")
    write_file(folder, "new.txt", "new")
    git(folder, "update-index", "--split-index")
    folder
  end

  # The SHA-256 of each file under +git_dir+ except the objects, which only grow, by path.
  private def digests(git_dir)
    files = Dir.glob("**/*", File::FNM_DOTMATCH, base: git_dir).reject { |path| path.start_with?("objects/") }
    files = files.select { |path| File.file?(File.join(git_dir, path)) }
    files.to_h { |path| [path, Digest::SHA256.file(File.join(git_dir, path)).hexdigest] }
  end
end

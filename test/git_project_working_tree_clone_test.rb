# frozen_string_literal: true

require_relative("git_fixtures")

# Checks what making the commit of a project's working tree leaves alone, and where it refuses.
class GitProjectWorkingTreeCloneTest < Minitest::Test
  include GitFixtures

  COMMIT = <<~RUBY
    project = Proof::GitProject.find(ARGV.fetch(0))
    print(project.working_tree_commit_id)
  RUBY
  private_constant(:COMMIT)

  # What the clone keeps in its index, its `HEAD`, and its branches and tags, as bytes.
  def state_of(folder)
    git_dir = File.join(folder, ".git")
    refs = Dir.glob(File.join(git_dir, "refs", "**", "*")).select { |path| File.file?(path) }
    files = [File.join(git_dir, "index"), File.join(git_dir, "HEAD"), File.join(git_dir, "packed-refs"), *refs]
    files.to_h { |path| [path, File.exist?(path) ? File.binread(path) : nil] }
  end

  # A committed file with a staged change, another change that isn't staged, and an untracked file.
  def stage_a_change(folder)
    commit_file(folder, "a.txt", "1")
    write_file(folder, "a.txt", "2")
    git(folder, "add", "a.txt")
    write_file(folder, "a.txt", "3")
    write_file(folder, "untracked.txt", "u")
  end

  # Command design, "Which project and which code": "The clone's index, `HEAD`, and branches stay
  # exactly as they were."
  def test_the_index_head_and_branches_are_byte_for_byte_as_they_were
    folder = make_repository
    stage_a_change(folder)
    git(folder, "branch", "other")
    git(folder, "tag", "v1")
    before = state_of(folder)
    working_tree_commit(folder)

    assert_equal(before, state_of(folder))
  end

  # The same sentence, as the person sees it: the staged change is still staged, and the untracked file still untracked.
  def test_what_git_reports_afterwards_is_what_it_reported_before
    folder = make_repository
    stage_a_change(folder)
    before = git(folder, "status", "--porcelain=v2", "--branch")
    working_tree_commit(folder)

    assert_equal(before, git(folder, "status", "--porcelain=v2", "--branch"))
  end

  # Command design, "Which project and which code": "Strip `GIT_*` variables inherited from a Git hook
  # before running Git: a hook run inside a linked worktree inherits `GIT_DIR`".
  def test_a_linked_worktree_run_from_a_hook_with_git_dir_set_commits_that_worktree
    main = make_repository
    commit_file(main, "main.txt")
    linked = File.join(temporary_folder, "linked")
    git(main, "worktree", "add", "--quiet", "--detach", linked)
    write_file(linked, "only-in-linked.txt", "x")
    git_dir = git(linked, "rev-parse", "--absolute-git-dir").chomp
    hook = variables(GIT_DIR: git_dir, GIT_INDEX_FILE: File.join(git_dir, "index"), GIT_WORK_TREE: linked)
    commit = printed_in_hook(hook, COMMIT, linked)

    assert_equal(["main.txt", "only-in-linked.txt"], tree(linked, commit).map(&:first))
  end

  # A computer with no Git identity, or a configuration that signs commits, still works: Proof gives the
  # commit an author and a committer, so nothing in the person's configuration can stop it. The process
  # that makes the commit has only the environment this test gives it, and a home folder with no identity
  # and a signing program that fails, so the result doesn't depend on the computer that runs the test.
  def test_the_commit_needs_no_git_identity_and_is_not_signed
    folder = make_repository
    commit_file(folder)
    home = temporary_folder
    File.write(File.join(home, ".gitconfig"), "[commit]\n\tgpgsign = true\n[gpg]\n\tprogram = false\n")
    commit = printed_in_clean_environment(variables(HOME: home, XDG_CONFIG_HOME: home), COMMIT, folder)

    assert_equal("Proof <proof@proof.invalid>", git(folder, "log", "-1", "--format=%an <%ae>", commit).chomp)
    assert_equal("Proof <proof@proof.invalid>", git(folder, "log", "-1", "--format=%cn <%ce>", commit).chomp)
    refute_match(/^gpgsig/, git(folder, "cat-file", "commit", commit))
  end

  # Command design, "Which project and which code": "`git commit-tree` with `HEAD` as parent." A
  # repository with no commit has no `HEAD`, so it is refused, with the cause.
  def test_a_repository_with_no_commit_is_refused
    folder = make_repository
    write_file(folder, "a.txt", "1")
    error = assert_raises(Proof::NoCommitsError) { working_tree_commit(folder) }

    assert_equal(
      [
        "#{folder} has no commits yet, so there is no HEAD to base the working tree on.",
        "Make a first commit with git commit, and run proof again.",
      ].join(" "),
      error.message
    )
  end

  # Command design, "Which project and which code": a partial clone is refused for the working tree too.
  def test_a_partial_clone_is_refused
    assert_raises(Proof::PartialCloneError) { working_tree_commit(make_partial_clone) }
  end

  def test_the_refusal_is_a_proof_error
    assert_operator(Proof::NoCommitsError, :<, Proof::Error)
  end
end

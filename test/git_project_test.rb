# frozen_string_literal: true

require_relative("git_fixtures")

# Checks how Proof finds the project, the Git repository, that a folder is in.
class GitProjectTest < Minitest::Test
  include GitFixtures

  ROOT = "print(Proof::GitProject.find(ARGV.fetch(0)).root)"
  private_constant(:ROOT)

  # Command design, "Which project and which code": "The project is the Git
  # repository containing the current folder, or `-C`'s."
  def test_the_project_of_its_own_folder_is_that_folder
    folder = make_repository

    assert_equal(folder, Proof::GitProject.find(folder).root)
  end

  # The same sentence, for a folder inside the repository.
  def test_the_project_of_a_folder_inside_a_repository_is_the_repository
    folder = make_repository
    write_file(folder, "lib/deep/file.rb", "")

    assert_equal(folder, Proof::GitProject.find(File.join(folder, "lib/deep")).root)
  end

  # Command design, "Which project and which code": "If there is none, refuse; never guess."
  def test_a_folder_in_no_repository_is_refused
    folder = temporary_folder
    error = assert_raises(Proof::NotInRepositoryError) { Proof::GitProject.find(folder) }

    assert_match(
      /\A#{Regexp.escape(folder)} is not inside a Git repository \(git rev-parse failed \(exit 128\): /,
      error.message
    )
    assert_match(/\. Run proof from a folder inside the project, or name the project with -C\.\z/, error.message)
  end

  # The same sentence, for a folder that doesn't exist, as a mistyped `-C` gives.
  def test_a_folder_that_does_not_exist_is_refused
    folder = File.join(temporary_folder, "missing")
    error = assert_raises(Proof::NotInRepositoryError) { Proof::GitProject.find(folder) }

    assert_equal(
      "#{folder} is not a folder, so no Git repository contains it. Check the folder you named with -C.",
      error.message
    )
  end

  # The same sentence, for a bare repository, which has history and no working tree to check.
  def test_a_bare_repository_is_refused
    bare = File.join(temporary_folder, "bare.git")
    git(temporary_folder, "init", "--quiet", "--bare", bare)

    assert_raises(Proof::NotInRepositoryError) { Proof::GitProject.find(bare) }
  end

  # Command design, "Which project and which code": "a hook run inside a linked
  # worktree inherits `GIT_DIR`, which redirects every Git command." Run from
  # a subfolder of the linked worktree, the project is the linked worktree.
  def test_a_linked_worktree_run_from_a_hook_with_git_dir_set_finds_its_own_root
    main = make_repository
    write_file(main, "lib/file.rb", "")
    commit_all(main)
    linked = File.join(temporary_folder, "linked")
    git(main, "worktree", "add", "--quiet", "--detach", linked)
    git_dir = git(linked, "rev-parse", "--absolute-git-dir").chomp
    hook = variables(GIT_DIR: git_dir, GIT_INDEX_FILE: File.join(git_dir, "index"))

    assert_equal(linked, printed_in_hook(hook, ROOT, File.join(linked, "lib")))
  end

  # Architecture, "Git": Proof needs the git program, and says so when the computer has none.
  def test_a_computer_with_no_git_is_reported_not_taken_for_a_missing_repository
    assert_raises(Proof::GitNotFoundError) { Proof::GitProject.find(make_repository, program: "proof-test-no-git") }
  end

  # Both refusals are one error, so a caller rescues one class.
  def test_the_refusal_is_a_proof_error
    assert_operator(Proof::NotInRepositoryError, :<, Proof::Error)
  end
end

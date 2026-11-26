# frozen_string_literal: true

require_relative("git_fixtures")

# Checks the `git` program as Proof runs it.
class GitTest < Minitest::Test
  include GitFixtures

  # Architecture, "Git": "Proof runs the `git` program as a subprocess".
  def test_it_runs_git_in_the_folder_it_is_given
    folder = make_repository

    assert_equal("#{folder}\n", Proof::Git.new(folder:).run("rev-parse", "--show-toplevel"))
  end

  # Architecture, "Git": "with every inherited `GIT_*` variable removed so that a
  # hook or a parent Git process can't redirect it". A program that prints its
  # environment shows what git would inherit from a hook.
  def test_no_git_variable_reaches_the_program
    program = File.join(temporary_folder, "environment-printer")
    File.write(program, "#!/bin/sh\nenv\n")
    File.chmod(0o755, program)
    hook = variables(GIT_DIR: "a", GIT_WORK_TREE: "b", GIT_INDEX_FILE: "c", GIT_X: "d", GITHUB_NOTE: "kept")
    printed = printed_in_hook(hook, temporary_folder, program).lines

    assert_empty(printed.grep(/\AGIT_/))
    assert_includes(printed, "GITHUB_NOTE=kept\n")
  end

  # Command design, "Which project and which code": "a hook run inside a linked
  # worktree inherits `GIT_DIR`, which redirects every Git command". Here it
  # would send git to another repository.
  def test_a_git_dir_that_a_hook_sets_does_not_redirect_git
    folder = make_repository
    other = make_repository("other")
    hook = variables(GIT_DIR: File.join(other, ".git"), GIT_WORK_TREE: other)

    assert_equal(".git\n", printed_in_hook(hook, folder, "git", "rev-parse", "--git-dir"))
  end

  # The same sentence, for a variable given for one run: Proof sets `GIT_INDEX_FILE`
  # itself to make a commit of the working tree, so that variable reaches git.
  def test_a_variable_given_for_one_run_reaches_git
    git = Proof::Git.new(folder: make_repository)

    assert_equal("here\n", git.run("rev-parse", "--git-path", "index", env: { GIT_INDEX_FILE: "here" }))
  end

  # Architecture, "Git" says a subprocess, and the brief says an argument array: no shell reads the arguments.
  def test_arguments_reach_git_with_no_shell_reading_them
    folder = make_repository
    argument = "$(touch shell-ran) ; touch shell-ran"
    output = Proof::Git.new(folder:).run("rev-parse", "--git-path", argument)

    assert_equal(".git/#{argument}\n", output)
    refute_path_exists(File.join(folder, "shell-ran"))
  end

  # Text for git's standard input reaches it, as `git update-index --index-info` needs.
  def test_input_reaches_git
    assert_equal(
      "45b983be36b73c0788dc9cbcb76cbb80fc7bb057\n",
      Proof::Git.new(folder: make_repository).run("hash-object", "--stdin", input: "hi\n")
    )
  end

  # Command design, "Output and exit status": "Errors are rewritten for people";
  # the message gives the command, the status, and what git said, so the command can rewrite it.
  def test_a_failing_git_raises_with_its_status_and_what_it_said
    error = assert_raises(Proof::GitFailedError) { Proof::Git.new(folder: temporary_folder).run("rev-parse", "HEAD") }

    assert_match(/\Agit rev-parse failed \(exit 128\): .*not a git repository/i, error.message)
  end

  # Command design, "Who runs it": agents run `proof` in fresh environments, where `git` may be missing.
  def test_a_computer_with_no_git_raises_its_own_error
    error = assert_raises(Proof::GitNotFoundError) do
      Proof::Git.new(folder: temporary_folder, program: "proof-test-no-such-git").run("--version")
    end

    assert_equal(
      "Proof found no program named proof-test-no-such-git. Install Git, or fix PATH, and run again.",
      error.message
    )
  end

  # A git that a signal ends has no exit status, so the message gives the signal.
  def test_a_git_that_a_signal_ends_is_reported_by_the_signal
    program = File.join(temporary_folder, "killed-git")
    File.write(program, "#!/bin/sh\nkill -9 $$\n")
    File.chmod(0o755, program)
    error = assert_raises(Proof::GitFailedError) { Proof::Git.new(folder: temporary_folder, program:).run("status") }

    assert_match(/\Agit status failed \(SIGKILL \(signal 9\)\):/, error.message)
  end

  # Both are Proof errors, so one rescue catches them.
  def test_its_errors_are_proof_errors
    assert_operator(Proof::GitFailedError, :<, Proof::Error)
    assert_operator(Proof::GitNotFoundError, :<, Proof::Error)
  end
end

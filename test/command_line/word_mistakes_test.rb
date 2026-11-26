# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks the line `proof` prints for a mistake in the commands and words of a command line.
class CommandLineWordMistakesTest < Minitest::Test
  include CommandLineHelper

  # A word that names no command is named, with the commands near it.
  def test_an_unknown_command_is_named_with_the_nearest_commands
    assert_equal(
      "proof: logn isn't a command. Did you mean login or logs? To list the commands, run: proof --help",
      mistake("logn")
    )
  end

  # A word no command is near gets no suggestion.
  def test_an_unknown_command_with_no_near_command_has_no_suggestion
    assert_equal("proof: frob isn't a command. To list the commands, run: proof --help", mistake("frob"))
  end

  # The same for the subcommands of a command.
  def test_an_unknown_subcommand_is_named_with_the_nearest_subcommand
    line = "proof: setpu isn't a subcommand of proof server. Did you mean setup? To list the subcommands, run: " \
      "proof server --help"

    assert_equal(line, mistake("server", "setpu"))
  end

  # proof.usage.kdl: `cmd "server" subcommand_required=#true`.
  def test_a_command_that_needs_a_subcommand_lists_them
    assert_equal(
      "proof: proof server needs a subcommand: setup, upgrade, or uninstall. To list them, run: proof server --help",
      mistake("server")
    )
  end

  # proof.usage.kdl: `group "what" "task" "--script" required=#true`.
  def test_proof_run_with_no_task_and_no_script_is_refused
    assert_equal("proof: proof run needs a task or --script. To see its usage, run: proof run --help", mistake("run"))
  end

  # proof.usage.kdl: the group takes one of the two.
  def test_a_task_with_a_script_is_refused
    assert_equal(
      "proof: a task and --script can't go together; give one. To see its usage, run: proof run --help",
      mistake("run", "test", "--script", "f")
    )
  end

  # proof.usage.kdl: `arg "<run>"` is required.
  def test_a_command_without_a_required_argument_is_refused
    assert_equal("proof: proof watch needs <run>. To see its usage, run: proof watch --help", mistake("watch"))
  end

  # proof.usage.kdl: `arg "<run>..."` is required, and takes many.
  def test_a_command_without_a_required_argument_that_takes_many_is_refused
    assert_equal("proof: proof cancel needs <run...>. To see its usage, run: proof cancel --help", mistake("cancel"))
  end

  # proof.usage.kdl: `watch` takes one run.
  def test_a_word_more_than_a_command_takes_is_refused
    assert_equal(
      "proof: b isn't a word proof watch takes. To see its usage, run: proof watch --help",
      mistake("watch", "a", "b")
    )
  end

  # A command with subcommands takes no words after `--`.
  def test_a_word_after_the_dashes_of_a_command_with_subcommands_is_refused
    assert_equal(
      "proof: x isn't a word proof server takes. To see its usage, run: proof server --help",
      mistake("server", "--", "x")
    )
  end

  # proof.usage.kdl: "The word after `:::` is that task's name".
  def test_the_marker_with_no_name_after_it_is_refused
    assert_equal(
      "proof: ::: needs a task name after it, as in proof run lint ::: test. To see its usage, run: proof run --help",
      mistake("run", "test", ":::")
    )
  end

  # The marker takes the next word as the name, so it can't be followed by another.
  def test_the_marker_followed_by_the_marker_is_refused
    assert_equal(
      "proof: ::: needs a task name after it, as in proof run lint ::: test. To see its usage, run: proof run --help",
      mistake("run", "test", ":::", ":::", "x")
    )
  end

  # proof.usage.kdl: "`:::` starts the next task", so a task has to come first.
  def test_the_marker_with_no_task_before_it_is_refused
    assert_equal(
      "proof: ::: needs a task before it, as in proof run lint ::: test. To see its usage, run: proof run --help",
      mistake("run", ":::", "test")
    )
  end
end

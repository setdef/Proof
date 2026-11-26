# frozen_string_literal: true

require_relative("../test_helper")

# Checks that the command line reads each argument and group from the CLI spec's JSON.
class CommandLineSpecArgTest < Minitest::Test
  SPEC = Proof::CommandLine::Spec.load
  private_constant(:SPEC)

  # proof.usage.kdl: `arg "[task]"` is optional and takes one word.
  def test_an_optional_argument_is_written_in_square_brackets
    task = SPEC.command(%w[run]).args.first

    assert_equal("[task]", task.to_s)
    refute_predicate(task, :required?)
  end

  # proof.usage.kdl: `arg "[args]..."` takes many words.
  def test_an_argument_that_takes_many_words_is_written_with_dots
    words = SPEC.command(%w[run]).args.last

    assert_equal("[args...]", words.to_s)
    assert_predicate(words, :repeatable?)
  end

  # proof.usage.kdl: the `help` of `arg "<run>"` on watch.
  def test_an_argument_has_its_one_line_description
    assert_equal("The run's ID, or its last five characters", SPEC.command(%w[watch]).args.first.help)
  end

  # proof.usage.kdl: `arg "<run>"` is required and takes one word.
  def test_a_required_argument_is_written_in_angle_brackets
    assert_equal("<run>", SPEC.command(%w[watch]).args.first.to_s)
  end

  # proof.usage.kdl: `arg "<run>..."` on cancel is required and takes many words.
  def test_a_required_argument_that_takes_many_words_is_written_with_both
    assert_equal("<run...>", SPEC.command(%w[cancel]).args.first.to_s)
  end

  # proof.usage.kdl: `group "what" "task" "--script" required=#true` on run.
  def test_a_group_names_its_members_and_says_that_one_is_required
    group = SPEC.command(%w[run]).groups.first

    assert_equal(["task", "--script"], group.names)
    assert_predicate(group, :required?)
  end

  # proof.usage.kdl: no other command has a group.
  def test_a_command_without_a_group_has_none
    assert_empty(SPEC.command(%w[watch]).groups)
  end
end

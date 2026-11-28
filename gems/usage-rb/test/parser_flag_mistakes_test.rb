# frozen_string_literal: true

require_relative("test_helper")

# Checks the mistakes the parser finds in the flags of a command line, each with the command it was made at.
class UsageParserFlagMistakesTest < Minitest::Test
  include UsageTestHelper

  # A flag the command doesn't take is a mistake of that command, named as typed.
  def test_a_flag_the_command_lacks_is_a_mistake
    assert_equal("command list has no flag --nope", mistake("list", "--nope"))
    assert_equal("command list has no flag --nope=1", mistake("list", "--nope=1"))
  end

  # usage reads a flag only by its whole name, so the front of one is no flag.
  def test_the_front_of_a_flags_name_is_no_flag
    assert_equal("command list has no flag --js", mistake("list", "--js"))
  end

  # usage checks every letter written together before it reads any, so one it lacks refuses them all.
  def test_letters_written_together_with_one_the_command_lacks_are_refused_whole
    assert_equal("command list has no flag -qx", mistake("list", "-qx"))
    assert_equal("command list has no flag -q-", mistake("list", "-q-"))
    assert_equal("command list has no flag -q=1", mistake("list", "-q=1"))
  end

  # A flag of a command, before the word that names it, is a mistake of the command the words have reached.
  def test_a_flag_before_its_command_is_a_mistake_of_the_command_before_it
    assert_equal("the program has no flag --json", mistake("--json", "list"))
    assert_equal("command remote has no flag --nope", mistake("remote", "--nope", "add", "u"))
  end

  # A command's global flag isn't the program's.
  def test_a_global_flag_of_a_command_is_no_flag_of_the_program
    assert_equal("the program has no flag -n", mistake("-n", "remote", "remove"))
  end

  # A value is missing at the end of the line and before the dashes, and is named as typed.
  def test_a_flag_without_its_value_is_a_mistake
    assert_equal("--sort of command list needs a value", mistake("list", "--sort"))
    assert_equal("-f of command add needs a value", mistake("add", "-f", "--", "x"))
    assert_equal("-f of command add needs a value", mistake("add", "-qf"))
  end

  # usage takes no word that looks like a flag as a value.
  def test_a_word_that_looks_like_a_flag_is_no_value
    assert_equal("--file of command add needs a value, and -q looks like a flag", mistake("add", "-f", "-q"))
  end

  # usage reads `-fq` as `-f -q`, so a letter after one that takes a value is no value either.
  def test_a_letter_after_one_that_takes_a_value_is_no_value
    assert_equal("--file of command add needs a value, and -d looks like a flag", mistake("add", "-fdir"))
  end

  # A strict choice takes only its values, whole.
  def test_a_value_outside_strict_choices_is_a_mistake
    assert_equal("--sort of command list takes one of due, added, not size", mistake("list", "--sort", "size"))
    assert_equal("--sort of command list takes one of due, added, not du", mistake("list", "--sort=du"))
  end

  # `requires` names a flag that has to be given with this one.
  def test_a_flag_without_the_flag_it_requires_is_a_mistake
    assert_equal("--output of command list needs --json", mistake("list", "-o", "out.json"))
    assert_equal("out.json", parse("list", "-o", "out.json", "--json").value("output"))
  end

  # The error says which command the mistake was made at.
  def test_the_error_holds_the_command_the_mistake_was_made_at
    error = assert_raises(Usage::CommandLineError) { parse("remote", "--nope", "add") }

    assert_equal(["remote"], error.command.path)
  end
end

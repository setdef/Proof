# frozen_string_literal: true

require_relative("test_helper")

# Checks how the parser reads the flags of a command line: long and short, written together, with values, and global.
class UsageParserFlagsTest < Minitest::Test
  include UsageTestHelper

  # A flag with no value is given or not, by its long name or its letter.
  def test_a_flag_with_no_value_is_given_by_either_name
    assert_equal([true, false], [parse("list", "--json").given?("json"), parse("list").given?("json")])
    assert(parse("list", "-q").given?("quiet"))
  end

  # usage reads `-qd` as `-q -d`.
  def test_letters_written_together_are_each_a_flag
    parsed = parse("list", "-qd")

    assert_equal([true, true], [parsed.given?("quiet"), parsed.given?("debug")])
  end

  # A value follows its flag as the next word, or after `=`.
  def test_a_value_is_the_next_word_or_follows_an_equals_sign
    parsed = [parse("list", "--sort", "due"), parse("list", "--sort=added")]

    assert_equal(%w[due added], parsed.map { |each| each.value("sort") })
  end

  # A letter that takes a value takes the next word, alone or last among letters written together.
  def test_a_letter_that_takes_a_value_takes_the_next_word
    parsed = parse("add", "-qf", "notes.txt")

    assert_equal([true, "notes.txt"], [parsed.given?("quiet"), parsed.value("file")])
    assert_equal("a.txt", parse("add", "-f", "a.txt").value("file"))
  end

  # usage reads each letter after one that takes a value as a flag, and the next word is the value of the last letter
  # that takes one: `-fd notes.txt` is `-f -d notes.txt`.
  def test_letters_after_one_that_takes_a_value_are_flags_and_leave_it_the_next_word
    parsed = parse("add", "-fd", "notes.txt")

    assert_equal(["notes.txt", true], [parsed.value("file"), parsed.given?("debug")])
  end

  # usage gives an empty value to a letter that takes one when a later letter takes the value.
  def test_the_last_of_two_letters_that_take_a_value_gets_it_and_the_first_gets_an_empty_one
    parsed = Usage::Parser.new(pair_spec).parse(%w[-ab 8])

    assert_equal(["", "8"], [parsed.value("first"), parsed.value("second")])
  end

  # usage reads the letters one by one, so a letter that names no flag after `-h` is never reached: `-hfx` and `-hf-`
  # ask for help.
  def test_help_before_a_letter_that_takes_a_value_leaves_the_letters_after_it_unread
    assert_equal([true, true], [parse("add", "-hfx").help?, parse("add", "-hf-").help?])
  end

  # usage binds the next word to the last letter that takes a value, and the empty value to the earlier ones after it,
  # so one flag written twice together keeps the empty value, and a flag that repeats holds the word first.
  def test_a_flag_written_twice_in_a_word_holds_the_word_and_then_the_empty_value
    each = Usage::Parser.new(pair_spec)

    assert_equal(["", ["8", ""]], [each.parse(%w[-aa 8]).value("first"), each.parse(%w[-bb 8]).values("second")])
  end

  # A flag that repeats keeps every value in order, and one that doesn't keeps the last.
  def test_a_repeated_flag_keeps_every_value_and_another_keeps_the_last
    assert_equal(%w[home work], parse("add", "x", "--tag", "home", "--tag=work").values("tag"))
    assert_equal("added", parse("list", "--sort", "due", "--sort", "added").value("sort"))
  end

  # A flag not given has no value.
  def test_a_flag_not_given_has_no_value
    parsed = parse("add", "x")

    assert_equal([nil, []], [parsed.value("file"), parsed.values("tag")])
  end

  # Choices that aren't strict take any word, and a strict choice takes its values.
  def test_a_value_that_is_one_of_the_choices_or_of_loose_choices_is_kept
    assert_equal(["garden"], parse("add", "x", "--tag", "garden").values("tag"))
    assert_equal("due", parse("list", "--sort", "due").value("sort"))
  end

  # A word that is a single dash is a value, as usage reads it.
  def test_a_single_dash_is_a_value
    assert_equal("-", parse("add", "--file", "-").value("file"))
  end

  # The program's global flags work before a command, between its words, and after them.
  def test_a_global_flag_works_anywhere_before_the_dashes
    words = [%w[-q remote add u], %w[remote -q add u], %w[remote add u -q]]

    assert_equal([true] * 3, words.map { |each| parse(*each).given?("quiet") })
  end

  # A command's global flag reaches every command under it.
  def test_a_global_flag_of_a_command_works_on_its_subcommands
    parsed = [parse("remote", "add", "u", "-n"), parse("remote", "--dry-run", "remove")]

    assert_equal([true, true], parsed.map { |each| each.given?("dry-run") })
  end

  private def pair_spec
    read(<<~JSON)
      {"bin": "pair", "cmd": {"name": "pair", "full_cmd": [], "flags": [
        {"name": "first", "short": ["a"], "arg": {"name": "x"}},
        {"name": "second", "short": ["b"], "var": true, "arg": {"name": "y"}}
      ]}}
    JSON
  end
end

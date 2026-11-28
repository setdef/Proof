# frozen_string_literal: true

require_relative("test_helper")

# Checks how the parser reads the words of a command line: the command they name, its arguments, `--`, and help.
class UsageParserWordsTest < Minitest::Test
  include UsageTestHelper

  # The words name a command, down through its subcommands, and no words name the program.
  def test_the_words_name_the_command
    assert_equal([%w[remote add], []], [parse("remote", "add", "u"), parse].map { |each| each.command.path })
  end

  # Each argument takes a word, in order, and one that repeats takes the rest.
  def test_each_argument_takes_its_words
    assert_equal(["Buy milk"], parse("add", "Buy milk").words("text"))
    assert_equal(%w[1 2 3], parse("done", "1", "2", "3").words("item"))
  end

  # An optional argument with no word has none.
  def test_an_argument_with_no_word_has_none
    assert_empty(parse("add", "--file", "f").words("text"))
  end

  # Flags may come before, among, and after the words of the arguments.
  def test_flags_and_arguments_may_come_in_any_order
    parsed = parse("done", "1", "-q", "2")

    assert_equal([%w[1 2], true], [parsed.words("item"), parsed.given?("quiet")])
  end

  # usage: after `--`, every word is an argument, and a second `--` is a word.
  def test_after_the_dashes_every_word_is_an_argument
    assert_equal(%w[1 -q -- 2], parse("done", "1", "--", "-q", "--", "2").words("item"))
  end

  # The words after `--` are kept apart too, for a program that hands them on as they are.
  def test_the_words_after_the_dashes_are_kept_apart
    assert_equal([%w[-q -- 2], []], [parse("done", "1", "--", "-q", "--", "2"), parse("done", "1")].map(&:separated))
  end

  # A single dash is a word, as usage reads it.
  def test_a_single_dash_is_a_word
    assert_equal(["-"], parse("add", "-").words("text"))
  end

  # `-h` and `--help` ask for the help of the command the words have reached, as usage reads them.
  def test_help_asks_for_the_help_of_the_command_reached
    asked = [parse("list", "-h"), parse("remote", "--help"), parse("-h", "list")]

    assert_equal([true] * 3, asked.map(&:help?))
    assert_equal([["list"], ["remote"], []], asked.map { |each| each.command.path })
  end

  # usage reads `h` among letters written together as help, and reads nothing after it.
  def test_help_among_letters_stops_the_reading
    parsed = parse("done", "-qh", "--nope")

    assert_equal([true, true], [parsed.help?, parsed.given?("quiet")])
  end

  # usage reads no letter after `h` among letters written together.
  def test_help_among_letters_reads_no_letter_after_it
    parsed = parse("list", "-hq")

    assert_equal([true, false], [parsed.help?, parsed.given?("quiet")])
  end

  # Help comes before what the command needs, such as its arguments.
  def test_help_comes_before_what_the_command_needs
    assert_predicate(parse("done", "--help"), :help?)
  end

  # A command line that asks for no help says so.
  def test_a_command_line_without_help_asks_for_none
    refute_predicate(parse("list"), :help?)
  end

  # After `--`, `-h` is a word.
  def test_help_after_the_dashes_is_a_word
    assert_equal(["-h"], parse("add", "--", "-h").words("text"))
  end

  # A command with subcommands that needs none is a command line of its own.
  def test_a_command_with_subcommands_may_stand_alone_unless_it_needs_one
    assert_equal([[], false], [parse("-q").command.path, parse("-q").help?])
  end
end

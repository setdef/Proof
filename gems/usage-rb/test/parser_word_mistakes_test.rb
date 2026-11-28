# frozen_string_literal: true

require_relative("test_helper")

# Checks the mistakes the parser finds in the words of a command line: commands, arguments, and groups.
class UsageParserWordMistakesTest < Minitest::Test
  include UsageTestHelper

  # A word that names no subcommand, where the command has subcommands, is a mistake.
  def test_a_word_that_names_no_command_is_a_mistake
    assert_equal("the program has no subcommand undo", mistake("undo"))
    assert_equal("command remote has no subcommand rm", mistake("remote", "rm"))
  end

  # usage reads a command only by its whole name.
  def test_the_front_of_a_commands_name_is_no_command
    assert_equal("the program has no subcommand lis", mistake("lis"))
  end

  # `subcommand_required` makes a command with no subcommand a mistake.
  def test_a_command_that_needs_a_subcommand_is_a_mistake_without_one
    assert_equal("command remote needs a subcommand: add, remove", mistake("remote", "-q"))
  end

  # After `--`, a command with subcommands takes no word.
  def test_a_word_after_the_dashes_of_a_command_with_subcommands_is_a_mistake
    assert_equal("the program takes no word x", mistake("--", "x"))
  end

  # A required argument needs a word.
  def test_a_required_argument_without_a_word_is_a_mistake
    assert_equal("command done needs <item...>", mistake("done"))
    assert_equal("command remote add needs <url>", mistake("remote", "add"))
  end

  # A word more than the arguments take is a mistake.
  def test_a_word_no_argument_takes_is_a_mistake
    assert_equal("command list takes no word extra", mistake("list", "extra"))
    assert_equal("command remote add takes no word v", mistake("remote", "add", "u", "v"))
  end

  # A required group needs one of its members, an argument or a flag.
  def test_a_required_group_needs_one_of_its_members
    assert_equal("command add needs one of text, --file", mistake("add"))
    assert_equal([["x"], "f"], [parse("add", "x").words("text"), parse("add", "--file", "f").value("file")])
  end

  # A mistake in the flags comes before one in the arguments.
  def test_a_mistake_in_the_flags_comes_first
    assert_equal("command done has no flag --nope", mistake("done", "--nope"))
  end

  # A program can word each mistake its own way.
  def test_the_parser_words_a_mistake_with_the_messages_it_is_given
    messages = Class.new(Usage::Messages) do
      # A word that names no command, in the program's words.
      def unknown_command(word)
        "no #{word} here"
      end
    end
    error = assert_raises(Usage::CommandLineError) { Usage::Parser.new(todo, messages:).parse(["undo"]) }

    assert_equal("no undo here", error.message)
  end

  # A class that isn't a subclass of `Usage::Messages` wouldn't word a kind of mistake that the gem learns later, so
  # the parser refuses it when it is built, not when a mistake is made.
  def test_the_parser_refuses_messages_that_do_not_subclass_the_gems
    error = assert_raises(ArgumentError) { Usage::Parser.new(todo, messages: Class.new) }

    assert_equal("messages must be Usage::Messages or a subclass of it", error.message)
  end
end

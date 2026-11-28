# frozen_string_literal: true

require_relative("test_helper")

# Checks the help written from a spec: its sections, their order, and their layout.
class UsageHelpTest < Minitest::Test
  include UsageTestHelper

  ADD = <<~TEXT
    todo add - Add an item

    Usage: todo add [FLAGS] [text]

    Examples:
      Add an item with a tag
        $ todo add 'Buy milk' --tag home

    Arguments:
      [text]  What to do

    Flags:
      --tag <tag>        Tag the item (such as home, work)
      -f, --file <path>

    Global flags:
      -q, --quiet  Print less
      -d, --debug

    Exit statuses:
      0  It worked.
      2  A mistake.
  TEXT
  private_constant(:ADD)

  # The help of the `todo` command at +path+.
  def help(*path)
    Usage::Help.new(todo).text(path)
  end

  # clig.dev: "Lead with examples", then the tables.
  def test_a_commands_help_has_each_section_in_order
    assert_equal(ADD, help("add"))
  end

  # bettercli.org: "What does your program do?"
  def test_the_programs_help_opens_with_what_it_does_and_its_longer_description
    assert_equal(
      ["todo - Keep a list of things to do", "", "Keeps the list in a file of its own.", "", "Each item has a number."],
      help.lines(chomp: true).first(5)
    )
  end

  # clig.dev: "Provide a support path", and the statuses a script reads.
  def test_the_programs_help_lists_its_commands_its_exit_statuses_and_ends_with_its_closing_text
    lines = help.lines(chomp: true)

    assert_includes(lines, "  remote  Share the list")
    assert_equal(["Exit statuses:", "  0  It worked.", "  2  A mistake.", ""], lines[-5..-2])
    assert_equal("Report a problem: https://example.com/todo/issues", lines.last)
  end

  # `subcommand_required` is `<SUBCOMMAND>`, and otherwise `[COMMAND]`.
  def test_the_usage_line_says_whether_a_subcommand_is_needed
    assert_includes(help.lines, "Usage: todo [FLAGS] [COMMAND]\n")
    assert_includes(help("remote").lines, "Usage: todo remote [FLAGS] <SUBCOMMAND>\n")
  end

  # Only the program's help ends with its closing text.
  def test_a_commands_help_lists_subcommands_and_not_the_closing_text
    text = help("remote")

    assert_includes(text, "Subcommands:\n  add\n  remove\n")
    refute_match(/Report a problem/, text)
  end

  # A command's help ends with the statuses that apply to it, the program's among them, as usage's reference lists them.
  def test_a_commands_help_lists_the_exit_statuses_that_apply_to_it
    spec = read(<<~JSON)
      {"bin": "t", "exit_codes": [{"code": 0, "help": "It worked."}],
       "cmd": {"subcommands": {"push": {"name": "push", "full_cmd": ["push"],
         "exit_codes": [{"code": 75, "help": "The server went away."}]}}}}
    JSON

    assert_equal(
      ["Exit statuses:", "  0   It worked.", "  75  The server went away."],
      Usage::Help.new(spec).text(["push"]).lines(chomp: true).last(3)
    )
  end

  # Strict choices are "one of", and others "such as".
  def test_a_flag_with_strict_choices_lists_them_as_the_values_it_takes
    assert_includes(help("list").lines, "  --sort <key>         Sort by this (one of due, added)\n")
  end

  # Asking for help never fails.
  def test_a_path_that_names_no_command_has_the_programs_help
    assert_equal(help, help("undo"))
  end
end

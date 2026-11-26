# frozen_string_literal: true

require_relative("test_helper")

# Checks how the help wraps long text: the title and descriptions at 100 characters, table cells at 78, and the
# explanation of an example at 70.
class UsageHelpLayoutTest < Minitest::Test
  include UsageTestHelper

  WORDS = ("word " * 40).strip
  private_constant(:WORDS)

  # The lines of the help at +path+ of the spec that +text+ holds.
  def help(text, path = [])
    Usage::Help.new(read(text)).text(path).lines(chomp: true)
  end

  # The title breaks at the last space that keeps a line within 100 characters.
  def test_a_long_title_wraps_at_one_hundred_characters
    lines = help(%({"bin": "t", "about": "#{WORDS}"}))

    assert_equal(["t - #{WORDS[0, 94]}", WORDS[95, 99]], lines.first(2))
  end

  # A spec wraps its own text, so a line within the width stays as it is.
  def test_a_description_keeps_its_lines_and_wraps_only_those_longer_than_the_help
    lines = help(%({"bin": "t", "about": "x", "about_long": "short line\\n#{WORDS}"}))

    assert_equal(["short line", WORDS[0, 99], WORDS[100, 99]], lines[2, 3])
  end

  # A cell continues under its own column.
  def test_a_table_cell_wraps_under_its_column
    lines = help(%({"cmd": {"flags": [{"name": "v", "long": ["v"], "help": "#{WORDS}"}]}}))

    assert_equal(["Flags:", "  --v  #{WORDS[0, 69]}", "       #{WORDS[70, 69]}"], lines[4, 3])
  end

  # A row is 78 characters at most, so a cell that would make it 79 wraps.
  def test_a_table_row_is_seventy_eight_characters_at_most
    long = "x" * 70
    lines = help(%({"cmd": {"flags": [{"name": "v", "long": ["v"], "help": "#{long} y"}]}}))

    assert_equal(["  --v  #{long}", "       y"], lines[5, 2])
  end

  # An example's explanation is indented under its command line.
  def test_an_examples_explanation_wraps_at_seventy_characters
    lines = help(%({"examples": [{"code": "t", "help": "#{WORDS}"}]}))

    assert_equal(["Examples:", "    $ t", "    #{WORDS[0, 69]}"], lines[4, 3])
  end

  # A flag is global to every command under the one that has it.
  def test_global_flags_of_every_command_above_are_listed
    text = <<~JSON
      {"cmd": {"flags": [{"name": "a", "long": ["a"], "global": true}], "subcommands": {"x": {"name": "x",
        "full_cmd": ["x"], "flags": [{"name": "b", "long": ["b"], "global": true}],
        "subcommands": {"y": {"name": "y", "full_cmd": ["x", "y"]}}}}}}
    JSON

    assert_equal(["Global flags:", "  --a", "  --b"], help(text, %w[x y]).last(3))
  end
end

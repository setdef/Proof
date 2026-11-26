# frozen_string_literal: true

require_relative("test_helper")

# Checks how the help wraps long text: the title and descriptions past 100 characters, table rows past 77, and the
# explanation of an example past 69.
class UsageHelpLayoutTest < Minitest::Test
  include UsageTestHelper

  WORDS = ("word " * 40).strip
  private_constant(:WORDS)

  # The lines of the help at +path+ of the spec that +text+ holds.
  def help(text, path = [])
    Usage::Help.new(read(text)).text(path).lines(chomp: true)
  end

  # A spec whose program has one flag, `v`, described as +text+.
  def flag_spec(text)
    %({"cmd": {"flags": [{"name": "v", "long": ["v"], "help": "#{text}"}]}})
  end

  # A spec with one example, `t`, explained as +text+.
  def example_spec(text)
    %({"examples": [{"code": "t", "help": "#{text}"}]})
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

  # A row is 77 characters at most: beside `--v`, a cell of 70 characters fits and one of 71 wraps.
  def test_a_table_row_is_seventy_seven_characters_at_most
    fits = "#{'x' * 68} y"
    wraps = "#{'x' * 69} y"

    assert_equal(["  --v  #{fits}"], help(flag_spec(fits)).drop(5))
    assert_equal(["  --v  #{'x' * 69}", "       y"], help(flag_spec(wraps)).drop(5))
  end

  # Runs of white space, line breaks included, are one space in a cell and in an example's explanation.
  def test_white_space_in_a_cell_and_an_explanation_is_one_space
    flag = help(%({"cmd": {"flags": [{"name": "v", "long": ["v"], "help": "one  two\\nthree"}]}}))
    example = help(%({"examples": [{"code": "t", "help": "one \\t two\\nthree"}]}))

    assert_equal(["  --v  one two three"], flag.drop(5))
    assert_equal(["    one two three"], example.drop(6))
  end

  # An example's explanation is indented under its command line.
  def test_an_examples_explanation_wraps_under_its_command_line
    lines = help(%({"examples": [{"code": "t", "help": "#{WORDS}"}]}))

    assert_equal(["Examples:", "    $ t", "    #{WORDS[0, 69]}"], lines[4, 3])
  end

  # An explanation of 69 characters fits, and one of 70 wraps.
  def test_an_examples_explanation_is_sixty_nine_characters_at_most
    fits = "#{'x' * 67} y"
    wraps = "#{'x' * 68} y"

    assert_equal(["    #{fits}"], help(example_spec(fits)).drop(6))
    assert_equal(["    #{'x' * 68}", "    y"], help(example_spec(wraps)).drop(6))
  end

  # A title of 100 characters stays whole, and one of 101 wraps to a line of 99.
  def test_a_title_of_one_hundred_characters_stays_on_one_line
    fits = %({"bin": "t", "about": "#{'x' * 94} y"})
    wraps = %({"bin": "t", "about": "#{'x' * 95} y"})

    assert_equal(["t - #{'x' * 94} y"], help(fits).first(1))
    assert_equal(["t - #{'x' * 95}", "y"], help(wraps).first(2))
  end

  # A description that wraps breaks at the last space that leaves a line of 99 characters.
  def test_a_description_wraps_to_lines_of_ninety_nine_characters_at_most
    lines = help(%({"bin": "t", "about": "a", "about_long": "#{'x' * 98} y z"}))

    assert_equal(["x" * 98, "y z"], lines[2, 2])
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

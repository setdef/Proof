# frozen_string_literal: true

require_relative("test_helper")

# Checks what a spec reads of each flag, argument, group, and example.
class UsageSpecPartsTest < Minitest::Test
  include UsageTestHelper

  # The flag called +name+ on the `todo` command at +path+.
  def flag(path, name)
    todo.commands.find(path)&.flags&.find { |each| each.name == name } || flunk("no flag #{name}")
  end

  # `short` and `long` give the switches, short ones first.
  def test_a_flag_is_typed_by_each_of_its_names
    assert_equal([%w[-q --quiet], ["--tag"]], [flag([], "quiet").switches, flag(["add"], "tag").switches])
  end

  # `arg` gives a flag its value's name.
  def test_a_flag_takes_a_value_when_the_spec_gives_it_one
    sort = flag(["list"], "sort")
    json = flag(["list"], "json")

    assert_equal(["key", true], [sort.value, sort.takes_value?])
    assert_equal([nil, false], [json.value, json.takes_value?])
  end

  # `choices` are strict unless `strict` is false, and a flag without them has nothing to check.
  def test_choices_are_strict_unless_the_spec_says_otherwise
    sort = flag(["list"], "sort")
    tag = flag(["add"], "tag")
    json = flag(["list"], "json")

    assert_equal([%w[due added], true], [sort.choices, sort.strict?])
    assert_equal([%w[home work], false], [tag.choices, tag.strict?])
    assert_equal([[], true], [json.choices, json.strict?])
  end

  # `var`, `requires`, and `global` are each false or empty unless the spec sets them.
  def test_a_flag_repeats_requires_and_passes_on_only_as_the_spec_says
    assert_equal([true, false], [flag(["add"], "tag").repeatable?, flag(["list"], "sort").repeatable?])
    assert_equal([["--json"], []], [flag(["list"], "output").requires, flag(["list"], "sort").requires])
    assert_equal([true, false], [flag([], "quiet").global?, flag(["list"], "json").global?])
  end

  # `help` and `help_long` are a flag's texts.
  def test_a_flag_has_its_descriptions
    flag = Usage::Flag.read({ name: "x", long: ["x"], help: "One line", help_long: "More" }, "here")

    assert_equal(["One line", "More"], [flag.help, flag.help_long])
  end

  # An argument is `<name>` when required, `[name]` when not, and has `...` when it repeats.
  def test_an_argument_is_written_as_a_usage_line_writes_it
    labels = [["add"], ["done"], %w[remote add]].map { |path| todo.commands.find(path)&.args&.first.to_s }

    assert_equal(["[text]", "<item...>", "<url>"], labels)
  end

  # `required`, `var`, `help`, and `help_long` describe an argument.
  def test_an_argument_has_its_descriptions_and_says_what_it_takes
    item = todo.commands.find(["done"])&.args&.first || flunk

    assert_equal(["The items, by number", nil], [item.help, item.help_long])
    assert_equal([true, true], [item.required?, item.repeatable?])
  end

  # A group names its members, and `required` and `multiple` say what it needs.
  def test_a_group_names_its_members_and_says_what_it_needs
    group = todo.commands.find(["add"])&.groups&.first || flunk

    assert_equal(["source", ["text", "--file"]], [group.name, group.names])
    assert_equal([true, false], [group.required?, group.multiple?])
  end

  # A group is neither required nor multiple unless the spec says so.
  def test_a_group_takes_several_members_only_when_the_spec_says_multiple
    several = Usage::Group.read({ name: "g", members: ["a"], multiple: true }, "here")

    assert_equal([false, true], [several.required?, several.multiple?])
  end

  # An example has its command line, its heading, and its explanation.
  def test_an_example_has_its_line_and_its_heading
    example = todo.commands.find(["add"])&.examples&.first || flunk

    assert_equal(
      ["todo add 'Buy milk' --tag home", "Add an item with a tag", nil],
      [example.code, example.header, example.help]
    )
  end
end

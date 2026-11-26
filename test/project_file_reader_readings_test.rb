# frozen_string_literal: true

require_relative("support/project_file_reader_helper")

# Checks the readings that issue #52 proposes where the project file page leaves a form open, each as the narrowest
# reading, so that widening it later never breaks a file. A reading the owner changes changes its test.
class ProjectFileReaderReadingsTest < Minitest::Test
  include ProjectFileReaderHelper

  # Issue #52, item 5: a duration is a whole number from 1, and then `s`, `m`, or `h`, as `TimeLimit` reads it.
  def test_a_duration_is_a_whole_number_and_a_unit
    assert_equal(
      [90, 1800, 7200],
      %w[90s 30m 2h].map { |text| read("task a timeout=\"#{text}\"\n").entries.first.settings.time_limit.seconds }
    )
  end

  # The same item, for the forms it refuses: a leading zero, a zero, no unit, a space, and two units.
  def test_a_duration_in_another_form_is_refused
    ["01m", "0m", "90", "90 s", "1h30m", "1.5h", "30M"].each do |text|
      assert_refused(
        "task a timeout=\"#{text}\"\n", 1, domain_said(Proof::InvalidTimeLimitError) { Proof::TimeLimit.read(text) }
      )
    end
  end

  # Issue #52, item 1: a path containing `..` is refused, so `v1..2.txt` is refused too, and a path with a single
  # dot or a Windows drive isn't.
  def test_a_path_with_two_dots_inside_a_name_is_refused
    assert_refused(
      "task a {\n  artifact \"v1..2.txt\"\n}\n",
      2,
      domain_said(Proof::InvalidPathPatternError) { Proof::PathPattern.new(path: "v1..2.txt") }
    )
    assert_equal(
      %w[.hidden a.b C:\\x],
      read("task a {\n  artifact .hidden a.b \"C:\\\\x\"\n}\n").entries.first.settings.artifacts.map(&:path)
    )
  end

  # Issue #52, item 2: "refuse `task \"\"`", so a task with a blank name, empty or only spaces, is refused.
  def test_a_blank_task_name_is_refused
    [["", "task \"\"\n"], ["  ", "task \"  \"\n"], ["\t", "task \"\\t\"\n"]].each do |name, text|
      assert_refused(
        "task a\n#{text}",
        2,
        "a task's name is text with at least one character that isn't white space, such as test, not #{name.inspect}"
      )
    end
  end

  # The same item: "refuse a command that is empty or only spaces", with the way to run the mise task instead.
  def test_a_blank_command_is_refused
    ["", "   "].each do |command|
      assert_refused(
        "task a \"#{command}\"\n",
        1,
        "a task's command is not empty and not only spaces, such as \"make docs\", not #{command.inspect}. " \
          "Leave the command out to run the mise task of the same name"
      )
    end
  end

  # Issue #52, item 3: "A child node given twice in one entry, such as two `os` nodes: refuse it, and say to give
  # every value as arguments to one node", at the second one's line.
  def test_a_child_given_twice_is_refused_at_the_second
    assert_refused(
      "task a {\n  os linux\n  label gpu\n  os macos\n}\n",
      4,
      "\"os\" is given twice, and the first is on line 2. Give every value as arguments to one \"os\" node"
    )
  end

  # The same item, for the children of `defaults`, and for `label` on the same line as the first.
  def test_a_child_given_twice_in_defaults_is_refused
    assert_refused(
      "defaults {\n  label a; label b\n}\n",
      2,
      "\"label\" is given twice, and the first is on line 2. Give every value as arguments to one \"label\" node"
    )
  end

  # Issue #52, item 4: "A child node with no arguments, such as a bare `label`: refuse it, since the page says each
  # takes `one or more`."
  def test_a_child_with_no_arguments_is_refused
    %w[os label artifact cache].each do |child|
      assert_refused(
        "task a {\n  #{child}\n}\n", 2, "\"#{child}\" takes one or more arguments, and this one has none"
      )
    end
  end

  # The same item, for a child that has arguments and also a property or a block: the page's table gives each child
  # "Arguments" and nothing else.
  def test_a_child_with_a_property_or_a_block_is_refused
    message = "\"os\" takes arguments only, with no properties and no children"

    assert_refused("task a {\n  os linux x=1\n}\n", 2, message)
    assert_refused("task a {\n  os linux {\n    macos\n  }\n}\n", 2, message)
  end

  # Issue #52, item 3, last words: "give every value as arguments to one node", which is a form that works.
  def test_every_value_as_arguments_to_one_node_works
    assert_equal(entry("a", os: %w[linux macos windows]), read("task a {\n  os linux macos windows\n}\n").entries.first)
  end
end

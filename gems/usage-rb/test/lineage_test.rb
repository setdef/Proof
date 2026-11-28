# frozen_string_literal: true

require_relative("test_helper")

# Checks what a command's lineage answers: the command, the commands above it, and the flags in effect there.
class UsageLineageTest < Minitest::Test
  include UsageTestHelper

  # The lineage of the `todo` command at +path+.
  def at(*path)
    todo.commands.at(path)
  end

  # A lineage runs from the program down to its command.
  def test_a_lineage_holds_the_program_and_each_command_down_to_its_own
    lineage = at("remote", "add")

    assert_equal([[], ["remote"], %w[remote add]], lineage.commands.map(&:path))
    assert_equal(%w[remote add], lineage.command.path)
  end

  # A descendant is longer by a command for each word, and no words give the lineage itself.
  def test_a_descendant_is_the_lineage_of_the_command_its_words_name
    assert_equal(at("remote", "add"), at.descendant(%w[remote add]))
    assert_equal(at("remote"), at("remote").descendant([]))
  end

  # A word that names no subcommand of the command before it leaves the tree, which has no lineage there.
  def test_a_word_that_names_no_subcommand_has_no_descendant
    assert_nil(at("remote").descendant(["undo"]))
    assert_nil(at.descendant(%w[list add]))
  end

  # A command takes its own flags, then the global flags of the program and every command above it, its own last.
  def test_the_flags_of_a_command_are_its_own_then_the_global_ones_in_effect
    assert_equal(%w[quiet debug dry-run], at("remote", "add").global_flags.map(&:name))
    assert_equal(%w[sort json output quiet debug], at("list").flags.map(&:name))
    assert_equal(%w[quiet debug dry-run], at("remote").flags.map(&:name))
  end
end

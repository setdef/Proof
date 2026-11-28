# frozen_string_literal: true

require_relative("test_helper")

# Checks how a spec's commands are found by their paths, and which global flags each command takes there.
class UsageCommandTreeTest < Minitest::Test
  include UsageTestHelper

  TREE = <<~JSON
    {"cmd": {"flags": [{"name": "quiet", "long": ["quiet"], "global": true},
                       {"name": "json", "long": ["json"]}],
             "subcommands": {
               "remote": {"name": "remote", "full_cmd": ["remote"],
                 "flags": [{"name": "dry-run", "long": ["dry-run"], "global": true}],
                 "subcommands": {"add": {"name": "add", "full_cmd": ["remote", "add"],
                   "flags": [{"name": "force", "long": ["force"], "global": true}]}}},
               "status": {"name": "status", "full_cmd": ["status"]}}}}
  JSON
  private_constant(:TREE)

  # The tree of the spec above.
  def tree
    read(TREE).commands
  end

  # The names of the global flags in effect at the command at +path+.
  def globals(path)
    tree.at(path).global_flags.map(&:name)
  end

  # A command takes the global flags of the program and of every command above it, its own last.
  def test_a_command_takes_the_global_flags_of_every_command_above_it
    assert_equal(%w[quiet dry-run force], globals(%w[remote add]))
    assert_equal(%w[quiet dry-run], globals(["remote"]))
  end

  # A command beside the one that has a global flag doesn't take it, and the program takes only its own.
  def test_a_global_flag_reaches_only_the_commands_under_its_command
    assert_equal(["quiet"], globals(["status"]))
    assert_equal(["quiet"], globals([]))
  end

  # The empty path stands at the program, and a path stands at the command it names.
  def test_a_path_gives_the_lineage_of_the_command_it_names
    assert_equal([tree.root], tree.at([]).commands)
    assert_equal(%w[remote add], tree.at(%w[remote add]).command.path)
  end

  # A path that leaves the tree names no command, so it has no lineage to give.
  def test_a_path_that_names_no_command_is_a_key_error
    error = assert_raises(KeyError) { tree.at(%w[remote rm]) }

    assert_equal('no command has the path ["remote", "rm"]', error.message)
    assert_nil(tree.find(%w[undo add]))
  end
end

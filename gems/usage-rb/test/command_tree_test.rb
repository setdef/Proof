# frozen_string_literal: true

require_relative("test_helper")

# Checks how a spec's commands are found by their paths, and which global flags each command takes.
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

  # The names of the global flags that the command at +path+ takes.
  def globals(path)
    read(TREE).commands.global_flags(path).map(&:name)
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

  # A path that leaves the tree gives the global flags of the commands it names before it leaves.
  def test_a_path_that_names_no_command_gives_the_flags_of_the_commands_it_does_name
    assert_equal(%w[quiet dry-run], globals(%w[remote rm]))
    assert_equal(["quiet"], globals(%w[undo add]))
  end
end

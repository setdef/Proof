# frozen_string_literal: true

require_relative("../test_helper")

# Checks that each command of the CLI spec has a value that holds what the command takes, and no other does.
class CommandLineCommandsTest < Minitest::Test
  SPEC = Proof::CommandLine::Spec.load
  private_constant(:SPEC)

  # The commands the spec lists that have no subcommand of their own, which are the ones `proof` runs.
  def leaves(command = SPEC.commands.root)
    command.subcommands.flat_map { |child| child.subcommands.empty? ? [child] : leaves(child) }
  end

  # The class that holds the words and flags of +command+: `runner setup` is RunnerSetupCommand.
  def value_class(command)
    Proof::CommandLine.const_get("#{command.path.map(&:capitalize).join}Command")
  end

  # The names of the members that the spec's arguments give +command+. `proof run` holds its task and the words
  # after it as tasks, and an argument that takes many words is plural.
  def argument_members(command)
    return [:tasks] if command.path == ["run"]

    command.args.map { |arg| arg.repeatable? ? :"#{arg.name}s" : arg.name.to_sym }
  end

  # The names of the members that the spec's flags give +command+, with a hyphen written as an underscore.
  def flag_members(command)
    command.own_flags.map { |flag| flag.name.tr("-", "_").to_sym }
  end

  # proof.usage.kdl: every `cmd` with no `cmd` inside it is a command `proof` runs.
  def test_every_command_the_spec_lists_has_a_value
    leaves.each { |command| value_class(command) }

    assert_equal(22, leaves.size)
  end

  # proof.usage.kdl: each `flag` and `arg` of a command is a member of its value.
  def test_a_value_holds_the_flags_and_arguments_of_its_command
    leaves.each do |command|
      expected = flag_members(command) + argument_members(command)

      assert_equal(expected.to_set, value_class(command).members.to_set, command.path.join(" "))
    end
  end

  # proof.usage.kdl: the flags marked `global=#true` are the members of the global flags.
  def test_the_global_flags_hold_the_flags_marked_global
    expected = SPEC.commands.root.global_flags.map { |flag| flag.name.tr("-", "_").to_sym }

    assert_equal(expected.to_set, Proof::CommandLine::GlobalFlags.members.to_set)
  end

  # No value stands for a command the spec doesn't list.
  def test_no_value_stands_for_a_command_the_spec_lacks
    named = Proof::CommandLine.constants.grep(/Command\z/).to_set
    listed = leaves.to_set { |command| value_class(command).name.split("::").last.to_sym }

    assert_equal(listed, named)
  end

  # A command with nothing to take is still a value, so that code is chosen by its class.
  def test_a_command_with_nothing_to_take_is_equal_to_another_of_its_class
    assert_equal(Proof::CommandLine::LogoutCommand.new, Proof::CommandLine::LogoutCommand.new)
  end

  # Two commands of different classes differ even when both take nothing.
  def test_two_commands_with_nothing_to_take_differ_by_class
    refute_equal(Proof::CommandLine::LogoutCommand.new, Proof::CommandLine::HookUninstallCommand.new)
  end
end

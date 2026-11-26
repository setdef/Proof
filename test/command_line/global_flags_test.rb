# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks the flags that work on every command, and the command lines that ask for help.
class CommandLineGlobalFlagsTest < Minitest::Test
  include CommandLineHelper

  NONE = { quiet: false, debug: false, no_color: false, no_input: false }.freeze
  private_constant(:NONE)

  # proof.usage.kdl: the four flags marked `global=#true`.
  def test_no_global_flag_is_false_for_all_four
    assert_equal(CL::GlobalFlags.new(**NONE), global("status"))
  end

  # proof.usage.kdl: `-q --quiet`, `-d --debug`, `--no-color`, and `--no-input`.
  def test_each_global_flag_is_true_when_given
    assert_equal(
      CL::GlobalFlags.new(quiet: true, debug: true, no_color: true, no_input: true),
      global("status", "-q", "--debug", "--no-color", "--no-input")
    )
  end

  # Global flags work before the command, after it, and between the words that name it.
  def test_a_global_flag_works_before_between_and_after_the_words_of_a_command
    flags = CL::GlobalFlags.new(**NONE, quiet: true)

    assert_equal(
      [flags] * 3,
      [global("-q", "runner", "list"), global("runner", "-q", "list"), global("runner", "list", "-q")]
    )
  end

  # clig.dev: "-h and --help ... Ignore any other flags and arguments that are passed", on every command.
  def test_help_on_any_command_asks_for_that_commands_help
    assert_equal(
      [CL::HelpAsked.new(path: ["run"]), CL::HelpAsked.new(path: %w[runner setup])],
      [parse("run", "test", "--oss", "-h"), parse("runner", "setup", "--help")]
    )
  end

  # proof.usage.kdl: `cmd "server" subcommand_required=#true` still has help.
  def test_help_on_a_command_with_subcommands_asks_for_its_help
    assert_equal(CL::HelpAsked.new(path: ["server"]), parse("server", "-h"))
  end

  # clig.dev: "Display concise help text by default" when `proof` is run with no arguments.
  def test_proof_alone_asks_for_its_help
    assert_equal([CL::HelpAsked.new(path: []), CL::HelpAsked.new(path: [])], [parse, parse("-q")])
  end

  # A cluster that holds h asks for help too.
  def test_help_in_a_cluster_asks_for_help
    assert_equal(CL::HelpAsked.new(path: ["status"]), parse("status", "-qh"))
  end

  # command.md, "The interface": the words after `--` aren't flags, so `-h` there goes to the task.
  def test_help_after_the_dashes_goes_to_the_task
    assert_equal([task("test", "-h")], command("run", "test", "--", "-h").tasks)
  end
end

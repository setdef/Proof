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

  # OptionParser reads -q=1 as -q, -=, and -1, so after the command the word typed is named. Before it, the same.
  def test_a_short_global_flag_with_an_equals_sign_before_the_command_is_named_as_typed
    words = %w[-q=1 -qd=1 -h=1 -q=]

    assert_equal(
      words.map { |word| "proof: #{word} isn't a flag of proof. To list the flags, run: proof --help" },
      words.map { |word| mistake(word, "status") }
    )
  end

  # proof.usage.kdl: the four global flags and --help take no value, before the command as after it.
  def test_a_long_global_flag_with_a_value_before_the_command_is_refused
    flags = %w[--quiet --debug --no-color --no-input --help]
    lines = flags.map { |flag| "proof: #{flag} takes no value. To see its usage, run: proof --help" }

    assert_equal(
      [lines, lines],
      [flags.map { |flag| mistake("#{flag}=1", "status") }, flags.map { |flag| mistake("#{flag}=", "status") }]
    )
  end

  # A value between the words that name a command is a mistake of the command the words have reached.
  def test_a_global_flag_with_a_value_between_the_words_of_a_command_is_refused
    assert_equal(
      "proof: --quiet takes no value. To see its usage, run: proof runner --help",
      mistake("runner", "--quiet=1", "list")
    )
  end

  # A flag proof doesn't have is named without its value, as it is after the command.
  def test_an_unknown_flag_with_a_value_before_the_command_is_named_without_the_value
    assert_equal(
      [
        "proof: --quite isn't a flag of proof. Did you mean --quiet? To list the flags, run: proof --help",
        "proof: -x isn't a flag of proof. To list the flags, run: proof --help",
      ],
      [mistake("--quite=1", "status"), mistake("-x=1", "status")]
    )
  end
end

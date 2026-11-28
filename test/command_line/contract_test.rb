# frozen_string_literal: true

require_relative("../support/command_line_cases")
require_relative("../support/command_line_parsed")
require_relative("../support/command_line_usage")
require_relative("../test_helper")

# Checks that `proof`'s parser and `usage explain` agree on every command line the CLI spec defines: whether it is
# accepted, which command it runs, and what each word binds to, with each `--` that is a word kept and each one that
# separates the task's words from the flags left out. The lines include the front of every flag, command, and choice,
# which usage refuses, and each flag before its command, which usage refuses too.
#
# usage can't say five things the parser does, so the unit tests check them alone: a task given with `--script`
# (word_mistakes_test.rb), the nearest flag in the line for an unknown flag (flag_names_test.rb), the words of every
# other line (word_mistakes_test.rb), `:::` with no task before it or no name after it (word_mistakes_test.rb), and the
# help that `proof` alone prints (global_flags_test.rb), where usage accepts it as a command line with nothing in it.
class CommandLineContractTest < Minitest::Test
  SPEC = Proof::CommandLine::Spec.load
  CASES = CommandLineContract::Cases.new(SPEC).all
  private_constant(:SPEC, :CASES)

  # proof.usage.kdl: the command lines the spec's flags, arguments, groups, choices, `requires`, and examples
  # define, made from the spec, so a change to the spec adds cases by itself.
  def test_the_parser_and_usage_agree_on_every_command_line_the_spec_defines
    usage = CommandLineContract::Usage.new(SPEC)
    parsed = CommandLineContract::Parsed.new(SPEC)
    disagreements = CASES.reject { |argv| agree?(usage.outcome(argv), parsed.outcome(argv), argv) }

    assert_empty(
      disagreements.map do |argv|
        "proof #{argv.join(' ')}: usage #{usage.outcome(argv).kind}, parser #{parsed.outcome(argv).kind}"
      end
    )
  end

  # Whether the two outcomes are one, or the line is a task with `--script`, which usage accepts and Proof refuses.
  def agree?(from_usage, from_parser, argv)
    return true if from_usage == from_parser

    from_parser == CommandLineContract::REFUSED && !argv.include?("--") && task_and_script?(from_usage)
  end

  def task_and_script?(outcome)
    outcome.command == ["run"] && outcome.flags.key?("script") && outcome.args.key?("task")
  end

  # Proof reads two rules stricter than usage's, through usage-rb's `Usage::StrictValueRules`, so these lines are
  # accepted by usage and refused by the parser: a value given with `=` to a flag that takes none, a value that looks
  # like a flag after `=`, and a negative number as the value that a flag requires.
  def test_the_parser_refuses_what_usage_accepts_by_the_two_stricter_rules
    lines = [%w[run test --empty=1], %w[run test --label=--x], %w[run test --project=-5], %w[run test --project -5]]
    usage = CommandLineContract::Usage.new(SPEC)
    parsed = CommandLineContract::Parsed.new(SPEC)

    assert_equal(
      [[:accepted] * lines.size, [:refused] * lines.size],
      [lines.map { |argv| usage.outcome(argv).kind }, lines.map { |argv| parsed.outcome(argv).kind }]
    )
  end

  # The contract names every switch the spec gives a flag, in each of the spec's commands.
  def test_the_cases_use_every_switch_of_every_command
    commands = SPEC.commands.root.subcommands.flat_map { |command| [command, *command.subcommands] }
    switches = (commands.flat_map(&:own_flags) + SPEC.commands.root.global_flags).flat_map(&:switches)

    assert_empty(switches - CASES.flatten)
  end

  # The contract has a line for every command, in full.
  def test_the_cases_use_every_command
    paths = SPEC.commands.root.subcommands.flat_map { |command| [command, *command.subcommands].map(&:path) }

    assert_empty(paths.reject { |path| CASES.any? { |argv| argv.first(path.size) == path } })
  end
end

# frozen_string_literal: true

require_relative("../support/command_line_cases")
require_relative("../support/command_line_parsed")
require_relative("../support/command_line_usage")
require_relative("../test_helper")

# Checks that `proof`'s parser and `usage explain` agree on every command line the CLI spec defines: whether it is
# accepted, which command it runs, and what each word binds to.
class CommandLineContractTest < Minitest::Test
  SPEC = Proof::CommandLine::Spec.load
  CASES = CommandLineContract::Cases.new(SPEC).all
  private_constant(:SPEC, :CASES)

  # proof.usage.kdl: the command lines the spec's flags, arguments, groups, choices, `requires`, and examples
  # define, made from the spec, so a change to the spec adds cases by itself.
  def test_the_parser_and_usage_agree_on_every_command_line_the_spec_defines
    usage = CommandLineContract::Usage.new(SPEC)
    parsed = CommandLineContract::Parsed.new(SPEC)
    disagreements = CASES.reject { |argv| usage.outcome(argv) == parsed.outcome(argv) }

    assert_empty(
      disagreements.map do |argv|
        "proof #{argv.join(' ')}: usage #{usage.outcome(argv).kind}, parser #{parsed.outcome(argv).kind}"
      end
    )
  end

  # The contract has enough command lines to mean something: at least one for each flag of each command.
  def test_the_cases_cover_every_flag_of_every_command
    flags = SPEC.root.subcommands.flat_map { |command| command.own_flags + command.subcommands.flat_map(&:own_flags) }

    assert_operator(CASES.size, :>, flags.size * 10)
  end
end

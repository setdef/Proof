# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks that every line `proof` prints for a mistake follows the style guide.
class CommandLineMessageStyleTest < Minitest::Test
  include CommandLineHelper

  LINES = [
    %w[run test --oss],
    %w[--quite status],
    %w[logn],
    %w[server],
    %w[run],
    %w[watch a b],
    %w[run test :::],
    %w[run test --os beos],
    %w[run test --os],
    %w[run test --empty=1],
    %w[run test -o d],
    %w[run --script],
  ].freeze
  private_constant(:LINES)

  # style-guide.md, "What Proof prints": the lines begin with `proof:`, and use ASCII only.
  def test_each_line_begins_with_proof_and_is_ascii
    lines = LINES.map { |words| mistake(*words) }

    assert(lines.all? { |line| line.start_with?("proof: ") && line.ascii_only? })
  end

  # command.md, "Output and exit status": errors "end with the command to run next", and `AGENTS.md` wants one line.
  def test_each_line_is_one_line_that_ends_with_the_command_to_run_next
    lines = LINES.map { |words| mistake(*words) }

    assert(lines.all? { |line| line.match?(/\A[^\n]+ proof( [a-z]+)* --help\z/) })
  end

  # proof.usage.kdl: "exit_code 2 ... the command line or the project file has a mistake".
  def test_a_mistake_exits_with_status_two
    assert_equal(2, CL::Mistake::STATUS)
  end
end

# frozen_string_literal: true

require_relative("../test_helper")

# Short names for the tests of the command line: parse words, and read what they parse to or the mistake they raise.
module CommandLineHelper
  CL = Proof::CommandLine
  NO_FLAGS = {
    script: nil,
    os: [],
    label: [],
    commit: nil,
    project: nil,
    cpus: nil,
    memory: nil,
    timeout: nil,
    empty: false,
    keep: [],
    input: [],
    input_file: [],
    download: false,
    output: nil,
    detach: false,
    json: false,
  }.freeze
  public_constant(:CL, :NO_FLAGS)

  # The parsed command line or help request that the words parse to.
  def parse(*argv)
    CL.parse(argv)
  end

  # The command value the words parse to.
  def command(*argv)
    parse(*argv).command
  end

  # The global flags the words parse to.
  def global(*argv)
    parse(*argv).global
  end

  # The line printed for the mistake in the words.
  def mistake(*argv)
    assert_raises(CL::Mistake) { parse(*argv) }
      .message
  end

  # A task with words, as `proof run` holds it.
  def task(name, *words)
    CL::TaskWords.new(name:, words:)
  end

  # A run command with nothing but its tasks, and the flags in +flags+.
  def run_command(tasks, **flags)
    CL::RunCommand.new(tasks:, **NO_FLAGS, **flags)
  end
end

# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks the help `proof` prints, which is written from the CLI spec.
class CommandLineHelpTest < Minitest::Test
  include CommandLineHelper

  SPEC = CL::Spec.load
  PATHS = [[], *SPEC.root.subcommands.flat_map { |command| [command, *command.subcommands].map(&:path) }].freeze
  private_constant(:SPEC, :PATHS)

  # The help for the command at +path+, as lines.
  def help(*path)
    CL.help(path).lines.map(&:chomp)
  end

  # clig.dev, "Help": the help says what the program does, and bettercli.org: "What does your program do?"
  def test_the_programs_help_begins_with_its_name_and_what_it_does
    line = "proof - Run your project's tests and builds on your spare computers, from your working tree or any"

    assert_equal(line, help.first)
  end

  # clig.dev: "Provide a support path for feedback and issues", and "link to the web version of the documentation".
  def test_the_programs_help_ends_with_where_to_read_and_report
    assert_equal(
      [
        "Documentation: https://github.com/setdef/Proof/tree/trunk/doc",
        "Report a problem: https://github.com/setdef/Proof/issues",
      ],
      help.last(2)
    )
  end

  # proof.usage.kdl: the thirteen commands, each with its one line.
  def test_the_programs_help_lists_each_command_with_its_one_line
    assert_includes(help, "  run       Run a task or a script on one or more runners")
    assert_empty(SPEC.root.subcommands.reject { |command| help.any? { |line| line.start_with?("  #{command.name} ") } })
  end

  # proof.usage.kdl: `exit_code` nodes, which the help lists with the statuses.
  def test_the_programs_help_lists_the_exit_statuses
    assert_includes(help, "  130  You interrupted Proof with Ctrl-C.")
  end

  # clig.dev: "Lead with examples."
  def test_the_programs_help_shows_its_examples_with_their_text
    assert_includes(help, "    $ proof watch m3d8q")
  end

  # proof.usage.kdl: `flag "--os <os>"` with choices.
  def test_a_flag_is_listed_with_its_value_and_its_choices
    assert_includes(help("run"), "                        several in parallel (one of linux, macos, windows,")
  end

  # proof.usage.kdl: `arg "[task]"` and `arg "[args]..."`.
  def test_the_usage_line_shows_the_arguments_as_the_spec_writes_them
    assert_includes(help("run"), "Usage: proof run [FLAGS] [task] [args...]")
  end

  # proof.usage.kdl: `cmd "server" subcommand_required=#true`.
  def test_a_command_that_needs_a_subcommand_lists_them
    assert_equal(["Usage: proof server [FLAGS] <SUBCOMMAND>"], help("server").grep(/\AUsage/))
  end

  # proof.usage.kdl: a subcommand's one line.
  def test_a_commands_help_lists_its_subcommands
    assert_includes(help("hook"), "  uninstall  Remove the pre-push hook that Proof installed in this clone")
  end

  # proof.usage.kdl: `long_help` of `run`, written as the spec wraps it.
  def test_a_commands_long_description_is_printed_as_the_spec_wraps_it
    assert_includes(
      help("run"),
      "`:::` starts the next task, before or after `--`, as it does for `mise run`. The word after `:::`"
    )
  end

  # proof.usage.kdl: the flags marked `global=#true` work on every command, so every help lists them.
  def test_every_commands_help_lists_the_global_flags
    assert_includes(help("status"), "  -q, --quiet  Print only the task's output and the result lines")
  end

  # The help has to give every flag and argument of every command a line of its own in a table, so a change to the
  # spec adds to it, and a name in the usage line or an example doesn't stand for a line that is missing.
  def test_each_commands_help_lists_each_of_its_flags_and_arguments
    missing = PATHS.flat_map { |path| lines_missing_from(path) }

    assert_empty(missing)
  end

  # The flags and arguments of the command at +path+ that no line of its help begins with.
  def lines_missing_from(path)
    lines = help(*path)
    labels(SPEC.command(path)).filter_map do |label|
      "#{path.join(' ')}: #{label}" unless lines.any? { |line| line.start_with?("  #{label}") }
    end
  end

  # How the spec writes the flags and arguments of +command+, which is how the help's tables begin each line.
  def labels(command)
    flags = command.own_flags.map { |flag| [flag.switches.join(", "), (" <#{flag.value}>" if flag.takes_value?)].join }
    flags + command.args.map(&:to_s)
  end

  # style-guide.md, "Output in examples": "Use ASCII only ... in what Proof prints".
  def test_every_commands_help_is_ascii
    assert(PATHS.all? { |path| CL.help(path).ascii_only? })
  end

  # style-guide.md: help is for a terminal, so no line is wider than the spec's own.
  def test_no_line_of_help_is_wider_than_one_hundred_characters
    assert(PATHS.all? { |path| CL.help(path).lines.all? { |line| line.chomp.length <= 100 } })
  end

  # A path that names no command has the program's help, so asking for help never fails.
  def test_help_for_a_path_that_names_no_command_is_the_programs
    assert_equal(CL.help([]), CL.help(["frobnicate"]))
  end

  # A request for help names the command whose help to print.
  def test_a_request_for_help_gives_the_path_of_the_help_to_print
    assert_equal(CL.help(%w[runner setup]), CL.help(parse("runner", "setup", "-h").path))
  end
end

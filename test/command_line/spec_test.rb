# frozen_string_literal: true

require_relative("../test_helper")

# Checks that the command line reads the program and its commands from the CLI spec's JSON.
class CommandLineSpecTest < Minitest::Test
  SPEC = Proof::CommandLine::Spec.load
  private_constant(:SPEC)

  # proof.usage.kdl: `bin "proof"`.
  def test_the_program_is_proof
    assert_equal("proof", SPEC.bin)
  end

  # proof.usage.kdl: `about` is the program's one line.
  def test_the_program_has_its_one_line_description
    assert_equal(
      "Run your project's tests and builds on your spare computers, from your working tree or any commit",
      SPEC.about
    )
  end

  # proof.usage.kdl: `long_about` and `after_long_help` are the text before and after the commands.
  def test_the_program_has_a_long_description_and_text_for_the_end_of_the_help
    assert_includes(SPEC.about_long, "each begins with \"proof:\".")
    assert_includes(SPEC.after_help, "Report a problem: https://github.com/setdef/Proof/issues")
  end

  # proof.usage.kdl: the thirteen top-level `cmd` nodes, in the order the spec writes them.
  def test_the_commands_are_the_ones_the_spec_lists_in_its_order
    names = %w[run watch logs cancel download status login logout verify skill server runner hook]

    assert_equal(names, SPEC.root.subcommands.map(&:name))
  end

  # proof.usage.kdl: each `exit_code` node, with its status.
  def test_the_exit_codes_are_the_nine_the_spec_lists
    assert_equal([0, 2, 75, 78, 124, 130, 137, 141, 143], SPEC.exit_codes.map(&:status))
  end

  # proof.usage.kdl: each `exit_code` node, with its meaning.
  def test_an_exit_code_has_its_meaning
    assert_equal(
      "The run was canceled: you interrupted Proof with Ctrl-C, or someone else, or the pool, canceled it. " \
        "The result line says who canceled it.",
      SPEC.exit_codes.find { |code| code.status == 130 }
      .help
    )
  end

  # proof.usage.kdl: the four flags marked `global=#true`.
  def test_the_global_flags_are_the_four_the_spec_marks
    assert_equal(%w[no-color no-input quiet debug], SPEC.root.global_flags.map(&:name))
  end

  # proof.usage.kdl: no top-level `flag` lacks `global=#true`.
  def test_the_program_has_no_flag_of_its_own
    assert_empty(SPEC.root.own_flags)
  end

  # proof.usage.kdl: `cmd "server" subcommand_required=#true` has setup, upgrade, and uninstall.
  def test_a_command_with_subcommands_says_whether_it_needs_one
    assert_predicate(SPEC.command(%w[server]), :subcommand_required?)
    assert_equal(%w[setup upgrade uninstall], SPEC.command(%w[server]).subcommands.map(&:name))
  end

  # proof.usage.kdl: `cmd "run"` has no subcommand_required.
  def test_a_command_without_the_setting_needs_no_subcommand
    refute_predicate(SPEC.command(%w[run]), :subcommand_required?)
  end

  # proof.usage.kdl: the `long_help` of `login`.
  def test_a_command_has_its_long_description_when_the_spec_gives_one
    assert_includes(SPEC.command(%w[login]).help_long, "Proof never takes a secret as an argument.")
  end

  # proof.usage.kdl: the `help` of `logout`.
  def test_a_command_has_its_one_line_description
    assert_equal(
      "Sign out of the pool's server from this computer, and delete the token Proof kept",
      SPEC.command(%w[logout]).help
    )
  end

  # proof.usage.kdl: the words `runner setup` name the `setup` command inside `runner`.
  def test_a_command_is_found_by_the_words_that_name_it
    assert_equal(%w[runner setup], SPEC.command(%w[runner setup]).path)
    assert_equal("setup", SPEC.command(%w[runner setup]).name)
  end

  # The program itself has no name, so no words name it.
  def test_no_words_name_the_program_itself
    assert_equal(SPEC.root, SPEC.command([]))
  end

  # A word that names no command finds none, so a typo is the caller's to handle.
  def test_a_word_that_names_no_command_finds_none
    assert_nil(SPEC.command(%w[frobnicate]))
    assert_nil(SPEC.command(%w[run frobnicate]))
    assert_nil(SPEC.command(%w[frobnicate more]))
  end

  # proof.usage.kdl: each `example` node, with its `header` and `help` when it has them.
  def test_an_example_has_its_command_line_and_the_text_the_spec_gives_it
    example = SPEC.command(%w[run]).examples.find { |each| each.code == "proof run test -- --seed 1234" }

    assert_equal("Give the task a flag", example.header)
    assert_equal("The words after -- go to the task, as for cargo run and npm run.", example.help)
  end

  # proof.usage.kdl: the program's own `example` nodes, which the help shows first.
  def test_the_program_has_the_four_examples_the_spec_gives_it
    assert_equal(
      [
        "proof run test",
        "proof run package --os linux --os windows --download",
        "proof run --script bench.sh --os linux",
        "proof watch m3d8q",
      ],
      SPEC.examples.map(&:code)
    )
  end

  # proof.usage.kdl: `example "proof watch m3d8q"` has no header.
  def test_an_example_without_a_header_has_none
    assert_nil(SPEC.command(%w[watch]).examples.first.header)
  end

  # A key the JSON leaves out reads as empty, so help the spec doesn't write is not an error.
  def test_a_document_with_an_empty_cmd_reads_as_a_program_with_no_commands
    spec = Proof::CommandLine::Spec.parse('{"cmd": {}}')

    assert_empty(spec.root.subcommands)
    assert_nil(spec.root.help)
    assert_equal("", spec.bin)
  end

  # A document with no `cmd` reads as an empty program.
  def test_a_document_with_no_cmd_reads_as_an_empty_program
    assert_empty(Proof::CommandLine::Spec.parse("{}").root.args)
  end
end

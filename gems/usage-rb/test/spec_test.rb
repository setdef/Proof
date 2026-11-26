# frozen_string_literal: true

require_relative("test_helper")

# Checks what a spec reads from usage's JSON: the program, its commands, and each command's flags.
class UsageSpecTest < Minitest::Test
  include UsageTestHelper

  # `bin`, `about`, `about_long`, and `after_help_long` are the program's name and its texts.
  def test_the_program_has_its_name_its_descriptions_and_its_closing_text
    spec = todo

    assert_equal(["todo", "Keep a list of things to do"], [spec.bin, spec.about])
    assert_equal("Keeps the list in a file of its own.\n\nEach item has a number.", spec.about_long)
    assert_equal("Report a problem: https://example.com/todo/issues", spec.after_help)
  end

  # `examples` and `exit_codes` keep the spec's order.
  def test_the_program_has_its_examples_and_exit_statuses_in_order
    spec = todo
    examples = spec.examples.map { |each| [each.code, each.header, each.help] }

    assert_equal([["todo list", nil, "Lists every item."]], examples)
    assert_equal([[0, "It worked."], [2, "A mistake."]], spec.exit_codes.map { |code| [code.status, code.help] })
  end

  # A command is found by its path, and no words find the program.
  def test_a_command_is_found_by_the_words_that_name_it
    spec = todo

    assert_equal(%w[remote add], spec.commands.find(%w[remote add])&.path)
    assert_equal(spec.commands.root, spec.commands.find([]))
  end

  # A typo finds nothing, so the caller decides what to do.
  def test_words_that_name_no_command_find_none
    spec = todo

    assert_equal([nil, nil], [spec.commands.find(["undo"]), spec.commands.find(%w[remote undo])])
    assert_nil(spec.commands.find(%w[undo add]))
  end

  # `subcommands` keep the spec's order, and `subcommand_required` says whether one must follow.
  def test_a_command_lists_its_subcommands_in_the_specs_order
    remote = todo.commands.find(["remote"])

    assert_equal(%w[add remove], remote&.subcommand_names)
    assert_predicate(remote, :subcommand_required?)
    refute_predicate(todo.commands.root, :subcommand_required?)
  end

  # `global` marks the flags a command passes on.
  def test_a_command_tells_its_own_flags_from_the_ones_it_passes_on
    root = todo.commands.root

    assert_equal(%w[quiet debug], root.global_flags.map(&:name))
    assert_empty(root.own_flags)
    assert_equal(%w[sort json output], todo.commands.find(["list"])&.own_flags&.map(&:name))
  end

  # `unknown_env` names a prefix and the variables with it to allow.
  def test_the_environment_to_check_is_the_prefix_and_the_names_allowed
    spec = todo

    assert_equal(["TODO_", ["TODO_HOME"]], [spec.env_prefix, spec.env_allowed])
  end

  # A key the JSON leaves out takes usage's default.
  def test_a_document_with_no_keys_reads_as_an_empty_program
    spec = read("{}")

    assert_equal(["", "", nil, nil], [spec.bin, spec.about, spec.about_long, spec.after_help])
    assert_equal([[], [], [], nil], [spec.commands.root.subcommands, spec.examples, spec.exit_codes, spec.env_prefix])
  end

  # `effect` says what a command does for tools that act for a person, and changes nothing the gem does.
  def test_the_effect_of_a_command_is_accepted
    spec = read('{"cmd": {"subcommands": {"rm": {"name": "rm", "full_cmd": ["rm"], "effect": "destructive"}}}}')

    assert_equal(["rm"], spec.commands.find(["rm"])&.path)
  end
end

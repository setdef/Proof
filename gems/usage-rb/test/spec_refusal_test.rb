# frozen_string_literal: true

require_relative("test_helper")

# Checks that a spec using anything the gem doesn't act on is refused when it is read, naming what it uses.
class UsageSpecRefusalTest < Minitest::Test
  include UsageTestHelper

  # A spec whose program has one flag, `v`, with the JSON members in +members+ added to its object.
  def with_flag(members)
    %({"cmd": {"flags": [{"name": "v", "long": ["v"], #{members}}]}})
  end

  # A spec whose program has the subcommand `rm`, with the JSON members in +members+ added to its object.
  def with_command(members)
    %({"cmd": {"subcommands": {"rm": {"name": "rm", "full_cmd": ["rm"], #{members}}}}})
  end

  # A key the gem doesn't read could change what the spec means, so it is named.
  def test_a_key_the_gem_does_not_read_is_refused_by_name
    assert_equal("the program has before_help, which usage-rb doesn't support", refusal('{"before_help": "x"}'))
    assert_equal(
      "flag v of the program has count, which usage-rb doesn't support",
      refusal(with_flag('"count": true'))
    )
  end

  # A key the gem accepts only at usage's default is named with the value it has.
  def test_a_value_other_than_the_one_the_gem_accepts_is_refused_with_the_value
    assert_equal(
      'command rm sets aliases to ["del"], which usage-rb doesn\'t support',
      refusal(with_command('"aliases": ["del"]'))
    )
    assert_equal(
      "flag v of the program sets hide to true, which usage-rb doesn't support",
      refusal(with_flag('"hide": true'))
    )
  end

  # `strict` is true or false, so any other value is named.
  def test_strict_choices_are_true_or_false
    flag = '"arg": {"name": "x", "choices": {"choices": ["a"], "strict": %s}}'

    assert_predicate(read(with_flag(flag % "true")).commands.root.flags.first&.choices, :strict?)
    assert_equal(
      "flag v of the program, in arg, in choices sets strict to \"no\", which usage-rb doesn't support",
      refusal(with_flag(flag % '"no"'))
    )
  end

  # A spec that needs a newer usage than the one whose specs the gem reads may use what the gem has never seen.
  def test_a_spec_that_needs_a_newer_usage_is_refused
    assert_equal(
      'the program sets min_usage_version to "7.5.0", which usage-rb doesn\'t support: it reads specs of usage 7.4.1',
      refusal('{"min_usage_version": "7.5.0"}')
    )
    assert_equal("the program has min_usage_version that isn't a version", refusal('{"min_usage_version": "two"}'))
  end

  # A spec for the usage the gem reads, or an older one, is read.
  def test_a_spec_for_the_same_or_an_older_usage_is_read
    specs = %w[7.4.1 2.0.0 7.4.1-rc.1].map { |each| %({"bin": "t", "min_usage_version": "#{each}"}) }

    assert_equal(%w[t t t], specs.map { |text| read(text).bin })
  end

  # usage writes these defaults into every spec's JSON.
  def test_the_defaults_usage_writes_are_accepted
    defaults = '"hide": false, "aliases": [], "mounts": [], "unknown_flags": null, "args_override_self": true'

    assert_equal(["rm"], read(with_command(defaults)).commands.root.subcommand_names)
    assert_equal("t", read('{"bin": "t", "unknown_flags": "error", "usage": "", "complete": {}}').bin)
  end

  # usage writes `null` for a key it has no value for, and a null reads as the key left out.
  def test_a_null_reads_as_the_key_left_out
    spec = read('{"about": null, "cmd": {"help": null, "flags": [{"name": "v", "long": ["v"], "help": null}]}}')

    assert_equal(["", nil, nil], [spec.about, spec.commands.root.help, spec.commands.root.flags.first&.help])
  end

  # A flag whose value may be left out reads the next word differently.
  def test_a_value_a_flag_may_leave_out_is_refused
    assert_equal(
      "flag v of the program, in arg sets required to false, which usage-rb doesn't support",
      refusal(with_flag('"arg": {"name": "x", "required": false}'))
    )
  end

  # usage counts a yes-or-no flag that repeats, and the gem has no count to give.
  def test_a_yes_or_no_flag_that_repeats_is_refused
    assert_equal(
      "flag v of the program repeats with no value, which usage-rb doesn't support",
      refusal(with_flag('"var": true'))
    )
  end

  # An argument with its own rules for `--` takes its words from elsewhere on the line.
  def test_an_argument_with_its_own_rules_for_the_dashes_is_refused
    assert_equal(
      'argument x of command rm sets double_dash to "Required", which usage-rb doesn\'t support',
      refusal(with_command('"args": [{"name": "x", "double_dash": "Required"}]'))
    )
  end

  # A word after such a command could be either.
  def test_a_command_with_both_arguments_and_subcommands_is_refused
    spec = '{"cmd": {"name": "todo", "args": [{"name": "file"}], "subcommands": {"add": {"name": "add"}}}}'

    assert_equal("the program has both arguments and subcommands, which usage-rb doesn't support", refusal(spec))
  end

  # Configuration files, a warning for unknown flags, and a language for an example all change what the program does.
  def test_settings_of_the_program_that_the_gem_does_not_act_on_are_refused
    config = '{"config": {"props": {"a": {}}, "sources": {}, "files": []}}'
    example = '{"examples": [{"code": "x", "lang": "sh"}]}'

    assert_match(/\Athe program sets config to /, refusal(config))
    assert_match(/\Athe program sets unknown_flags to "warn"/, refusal('{"unknown_flags": "warn"}'))
    assert_match(/\Aan example of the program sets lang to "sh"/, refusal(example))
  end

  # The gem reads the JSON `usage generate json` writes, and nothing else.
  def test_a_text_that_is_not_json_or_not_an_object_is_refused
    assert_match(/\Aa usage spec is JSON, and this text isn't: /, refusal("{"))
    assert_equal("a usage spec is a JSON object, as usage generate json writes it", refusal("[]"))
  end
end

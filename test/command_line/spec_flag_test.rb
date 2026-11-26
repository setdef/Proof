# frozen_string_literal: true

require_relative("../test_helper")

# Checks that the command line reads each flag from the CLI spec's JSON.
class CommandLineSpecFlagTest < Minitest::Test
  SPEC = Proof::CommandLine::Spec.load
  private_constant(:SPEC)

  # The flag called +name+ on the command at +path+.
  def flag(path, name)
    SPEC.command(path).flags.find { |each| each.name == name }
  end

  # proof.usage.kdl: `-q --quiet` is two names for one flag.
  def test_a_flag_is_typed_by_each_of_its_names
    assert_equal(%w[-q --quiet], flag([], "quiet").switches)
    assert_equal(%w[-C --project], flag(%w[run], "project").switches)
  end

  # proof.usage.kdl: `--os` has no short name.
  def test_a_flag_with_no_short_name_has_one_switch
    assert_equal(["--os"], flag(%w[run], "os").switches)
  end

  # proof.usage.kdl: `flag "--os <os>"` takes a value, named `os`.
  def test_a_flag_takes_a_value_when_the_spec_gives_it_one
    assert_predicate(flag(%w[run], "os"), :takes_value?)
    assert_equal("os", flag(%w[run], "os").value)
  end

  # proof.usage.kdl: `flag "--empty"` takes no value.
  def test_a_flag_takes_no_value_when_the_spec_gives_none
    refute_predicate(flag(%w[run], "empty"), :takes_value?)
    assert_nil(flag(%w[run], "empty").value)
  end

  # proof.usage.kdl: `--os`, `--label`, `--keep`, `--input`, and `--input-file` are `var=#true`.
  def test_a_flag_repeats_only_when_the_spec_says_var
    repeating = SPEC.command(%w[run]).flags.filter_map { |each| each.name if each.repeatable? }

    assert_equal(%w[os label keep input input-file], repeating)
  end

  # proof.usage.kdl: `choices "linux" "macos" "windows" "any" "all"` refuses any other value.
  def test_choices_are_strict_by_default
    assert_equal(%w[linux macos windows any all], flag(%w[run], "os").choices)
    assert_predicate(flag(%w[run], "os"), :strict?)
  end

  # proof.usage.kdl: `choices strict=#false "gpu" ...` accepts a label it doesn't list.
  def test_choices_are_not_strict_when_the_spec_says_strict_false
    assert_equal(%w[gpu kvm desktop sound podman xcode], flag(%w[run], "label").choices)
    refute_predicate(flag(%w[run], "label"), :strict?)
  end

  # proof.usage.kdl: a flag with no `choices` has nothing to check.
  def test_a_flag_without_choices_has_none_and_nothing_to_check
    assert_empty(flag(%w[run], "commit").choices)
    assert_predicate(flag(%w[run], "commit"), :strict?)
  end

  # proof.usage.kdl: a yes-or-no flag takes no value, so it has no choices.
  def test_a_flag_that_takes_no_value_has_no_choices
    assert_empty(flag(%w[run], "empty").choices)
    assert_predicate(flag(%w[run], "empty"), :strict?)
  end

  # proof.usage.kdl: `flag "-o --output <dir>" requires="--download"`.
  def test_a_flag_names_the_switches_it_requires
    assert_equal(["--download"], flag(%w[run], "output").requires)
  end

  # proof.usage.kdl: `download`'s `-o --output <dir>` requires nothing.
  def test_a_flag_without_the_setting_requires_nothing
    assert_empty(flag(%w[download], "output").requires)
  end

  # proof.usage.kdl: the `help` of `--os`.
  def test_a_flag_has_its_one_line_description
    assert_equal("Run on this operating system; repeat to run on several in parallel", flag(%w[run], "os").help)
  end

  # proof.usage.kdl: the five flags marked `global=#true`.
  def test_a_global_flag_is_marked_global_and_another_is_not
    assert_predicate(flag([], "debug"), :global?)
    refute_predicate(flag(%w[status], "json"), :global?)
  end
end

# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks the line `proof` prints for a mistake in the flags of a command line.
class CommandLineFlagMistakesTest < Minitest::Test
  include CommandLineHelper

  # proof.usage.kdl, `run`'s long help: "Proof names it, suggests the nearest flag it has, and exits 2".
  def test_an_unknown_flag_is_named_with_the_nearest_flag
    assert_equal(
      "proof: --oss isn't a flag of proof run. Did you mean --os? To list the flags, run: proof run --help",
      mistake("run", "test", "--oss", "linux")
    )
  end

  # A flag with a value is named without it.
  def test_an_unknown_flag_written_with_a_value_is_named_without_the_value
    assert_equal(
      "proof: --oss isn't a flag of proof run. Did you mean --os? To list the flags, run: proof run --help",
      mistake("run", "test", "--oss=linux")
    )
  end

  # A flag no flag is near gets no suggestion.
  def test_an_unknown_flag_with_no_near_flag_has_no_suggestion
    assert_equal(
      "proof: --zzzzzz isn't a flag of proof run. To list the flags, run: proof run --help",
      mistake("run", "test", "--zzzzzz")
    )
  end

  # A short flag is named, and no suggestion follows, because one letter is near every other.
  def test_an_unknown_short_flag_is_named_with_no_suggestion
    assert_equal(
      "proof: -x isn't a flag of proof status. To list the flags, run: proof status --help",
      mistake("status", "-x")
    )
  end

  # An abbreviation is a mistake, as OptionParser's require_exact refuses it.
  def test_an_abbreviation_of_a_flag_is_refused_with_the_flag
    assert_equal(
      "proof: --js isn't a flag of proof status. Did you mean --json? To list the flags, run: proof status --help",
      mistake("status", "--js")
    )
  end

  # The flags before the command are the global flags, so another flag there is a mistake of `proof`.
  def test_an_unknown_flag_before_the_command_is_a_mistake_of_proof
    assert_equal(
      "proof: --quite isn't a flag of proof. Did you mean --quiet? To list the flags, run: proof --help",
      mistake("--quite", "status")
    )
  end

  # A flag of a command is not one of `proof`.
  def test_a_flag_of_a_command_before_the_command_is_a_mistake_of_proof
    assert_equal(
      "proof: --os isn't a flag of proof. To list the flags, run: proof --help",
      mistake("--os", "linux", "run", "test")
    )
  end

  # proof.usage.kdl: `flag "--os <os>"` takes a value.
  def test_a_flag_without_its_value_is_refused
    assert_equal("proof: --os needs a value. To see its usage, run: proof run --help", mistake("run", "test", "--os"))
  end

  # A short flag is named as typed.
  def test_a_short_flag_without_its_value_is_named_as_typed
    assert_equal("proof: -C needs a value. To see its usage, run: proof run --help", mistake("run", "test", "-C"))
  end

  # proof.usage.kdl: usage takes the next word as the value of a flag, unless it looks like a flag.
  def test_a_flag_followed_by_a_flag_is_refused
    assert_equal(
      "proof: --os needs a value, and --label looks like a flag. To see its usage, run: proof run --help",
      mistake("run", "test", "--os", "--label", "gpu")
    )
  end

  # usage refuses `-Cdir`, which it reads as `-C -d -i -r`.
  def test_a_short_flag_with_its_value_attached_is_refused
    assert_equal(
      "proof: --project needs a value, and -d looks like a flag. To see its usage, run: proof run --help",
      mistake("run", "test", "-Cdir")
    )
  end

  # proof.usage.kdl: `flag "--empty"` is yes or no.
  def test_a_yes_or_no_flag_with_a_value_is_refused
    assert_equal(
      "proof: --empty takes no value. To see its usage, run: proof run --help",
      mistake("run", "test", "--empty=1")
    )
  end

  # proof.usage.kdl: `choices "linux" "macos" "windows" "any" "all"`.
  def test_a_value_outside_the_choices_is_refused_with_the_allowed_values
    assert_equal(
      "proof: --os takes one of linux, macos, windows, any, or all, not beos. To see its usage, run: proof run --help",
      mistake("run", "test", "--os", "beos")
    )
  end

  # proof.usage.kdl: `flag "-o --output <dir>" requires="--download"`.
  def test_a_flag_without_the_flag_it_requires_is_refused
    assert_equal(
      "proof: --output needs --download. To see its usage, run: proof run --help",
      mistake("run", "test", "-o", "dist")
    )
  end
end

# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks the line `proof` prints for a mistake in a flag's value, or in the flags a flag requires.
class CommandLineFlagMistakesTest < Minitest::Test
  include CommandLineHelper

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

  # proof.usage.kdl: usage refuses `-Cdir`, which it reads as `-C -d` and then a letter that names no flag.
  def test_a_short_flag_with_its_value_attached_is_refused
    assert_equal(
      "proof: -i isn't a flag of proof run. To list the flags, run: proof run --help",
      mistake("run", "test", "-Cdir")
    )
  end

  # usage reads `-Cd` as `-C -d`, which leaves `-C` the next word, and none follows.
  def test_a_short_flag_followed_by_flags_at_the_end_has_no_value
    assert_equal("proof: -C needs a value. To see its usage, run: proof run --help", mistake("run", "test", "-Cd"))
  end

  # proof.usage.kdl: `flag "--empty"` is yes or no.
  def test_a_yes_or_no_flag_with_a_value_is_refused
    assert_equal(
      "proof: --empty takes no value. To see its usage, run: proof run --help",
      mistake("run", "test", "--empty=1")
    )
  end

  # Proof reads the stricter rules of usage-rb: a value that looks like a flag is refused after `=` too, where usage
  # takes it.
  def test_a_value_that_looks_like_a_flag_is_refused_after_an_equals_sign
    assert_equal(
      "proof: --label needs a value, and --x looks like a flag. To see its usage, run: proof run --help",
      mistake("run", "test", "--label=--x")
    )
  end

  # Proof reads the stricter rules of usage-rb: a negative number is no value, where usage takes it.
  def test_a_negative_number_is_refused_as_a_value
    expected = "proof: --project needs a value, and -5 looks like a flag. To see its usage, run: proof run --help"

    assert_equal(
      [expected, expected],
      [mistake("run", "test", "--project=-5"), mistake("run", "test", "--project", "-5")]
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

# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks how the line `proof` prints for a flag it lacks names the flag, and the flag it suggests.
class CommandLineFlagNamesTest < Minitest::Test
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

  # issue #51: a cluster with a letter Proof lacks is named by that letter, before the command as after it, since that
  # letter is the part to fix. It gets no suggestion, since one letter is near every other.
  def test_an_unknown_cluster_of_short_flags_is_named_by_its_unknown_letter
    before = "proof: -x isn't a flag of proof. To list the flags, run: proof --help"

    assert_equal([before, before], [mistake("-qx", "status"), mistake("-qxy", "status")])
    assert_equal(
      "proof: -x isn't a flag of proof status. To list the flags, run: proof status --help",
      mistake("status", "-qx")
    )
  end

  # usage refuses -q=1 whole, since "=" is no letter of a flag, and the word that was typed is what the person needs
  # to see.
  def test_a_cluster_of_short_flags_with_an_equals_sign_is_named_as_typed
    assert_equal(
      "proof: -q=1 isn't a flag of proof status. To list the flags, run: proof status --help",
      mistake("status", "-q=1")
    )
  end

  # usage refuses a dash among letters written together, and a dash is no letter of a flag, so the word is named as
  # typed.
  def test_a_dash_among_short_flags_is_named_as_typed
    assert_equal(
      "proof: -q- isn't a flag of proof run. To list the flags, run: proof run --help",
      mistake("run", "test", "-q-", "--json")
    )
  end

  # The word that was typed is named after other words too.
  def test_a_cluster_with_an_equals_sign_after_other_words_is_named_as_typed
    assert_equal(
      "proof: -q=1 isn't a flag of proof run. To list the flags, run: proof run --help",
      mistake("run", "test", "--os", "linux", "-q=1")
    )
  end

  # usage reads a flag only by its whole name, so an abbreviation is a mistake.
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
end

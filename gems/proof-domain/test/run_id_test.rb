# frozen_string_literal: true

require_relative("test_helper")

# Checks what a run ID is made of, and how it is written.
class RunIdTest < Minitest::Test
  # A run ID of the glossary's minute, 03:36 on 25 November 2026, UTC, and
  # these characters.
  def run_id(characters = "m3d8q", minute: Time.utc(2026, 11, 25, 3, 36))
    Proof::RunId.new(minute:, characters:)
  end

  # Glossary, "run": "A run ID is the minute the run was created, in UTC, then
  # five random characters: `20261125-0336-k7q2w`."
  def test_an_id_is_the_minute_in_utc_then_five_characters_with_hyphens
    assert_equal("20261125-0336-k7q2w", run_id("k7q2w").to_s)
  end

  # Glossary, "run": "the minute the run was created, in UTC", so a moment in
  # another zone is the same minute in UTC.
  def test_a_minute_in_another_zone_is_written_in_utc
    id = run_id(minute: Time.new(2026, 11, 24, 22, 36, 0, "-05:00"))

    assert_equal("20261125-0336-m3d8q", id.to_s)
    assert_predicate(id.minute, :utc?)
  end

  # Glossary, "run": "the minute the run was created", so the seconds are dropped.
  def test_the_seconds_of_the_moment_are_dropped
    id = run_id(minute: Time.utc(2026, 11, 25, 3, 36, 59, 999_999))

    assert_equal(Time.utc(2026, 11, 25, 3, 36), id.minute)
    assert_equal("20261125-0336-m3d8q", id.to_s)
  end

  # Glossary, "run": a run ID is one minute and five characters, and a value
  # that names a run can't change.
  def test_the_minute_is_frozen
    assert_predicate(run_id.minute, :frozen?)
  end

  # Glossary, "run": "five random characters", so four or six are not an ID.
  def test_the_characters_are_five
    %w[m3d8 m3d8qx].each do |characters|
      assert_raises(Proof::InvalidRunIdError) { run_id(characters) }
    end
  end

  # Glossary, "run": the characters come from "Crockford's Base32, which has no
  # `i`, `l`, `o`, or `u`", so a `u` is not one.
  def test_a_u_is_not_one_of_the_characters
    assert_raises(Proof::InvalidRunIdError) { run_id("m3d8u") }
    assert_raises(Proof::InvalidRunIdError) { run_id("M3D8U") }
  end

  # Glossary, "run": the characters come from Crockford's Base32, so nothing
  # outside its alphabet is one.
  def test_a_character_outside_the_alphabet_is_refused
    ["m3d8-", "m3 8q", "m3d8é", "m3d8\n"].each do |characters|
      assert_raises(Proof::InvalidRunIdError) { run_id(characters) }
    end
  end

  # Glossary, "run": "Proof reads a typed `o` as `0` and an `i` or `l` as `1`."
  def test_a_typed_o_i_or_l_is_read_as_zero_or_one
    assert_equal("m3081", run_id("M3O8L").characters)
    assert_equal("m3081", run_id("m3o8i").characters)
  end

  # Glossary, "run": two spellings of the same five characters are one ID.
  def test_two_spellings_of_one_id_are_equal
    assert_equal(run_id("m3081"), run_id("M3O8L"))
  end

  # Glossary, "run": "five random characters", so a value that is not text
  # is not five characters.
  def test_characters_that_are_not_text_are_refused
    [nil, 12_345, :m3d8q, %w[m3d8q]].each do |characters|
      assert_raises(Proof::InvalidRunIdError) { run_id(characters) }
    end
  end

  # Glossary, "run": "the minute the run was created", so a minute is a time.
  def test_a_minute_that_is_not_a_time_is_refused
    [nil, "20261125-0336", 1_795_000_000].each do |minute|
      assert_raises(Proof::InvalidRunIdError) { run_id(minute:) }
    end
  end

  # Glossary, "run": the example `20261125-0336-k7q2w` has a year of four
  # digits, so a year of three or five digits can't be written that way.
  def test_a_year_of_other_than_four_digits_is_refused
    [Time.utc(999, 12, 31, 23, 59), Time.utc(10_000, 1, 1)].each do |minute|
      assert_raises(Proof::InvalidRunIdError) { run_id(minute:) }
    end
  end

  # The years at the ends of the four-digit range are IDs.
  def test_the_first_and_last_four_digit_years_are_allowed
    assert_equal("10000101-0000-m3d8q", run_id(minute: Time.utc(1000, 1, 1)).to_s)
    assert_equal("99991231-2359-m3d8q", run_id(minute: Time.utc(9999, 12, 31, 23, 59)).to_s)
  end

  # The message says what the minute is and what it got.
  def test_the_message_for_a_minute_names_the_value
    error = assert_raises(Proof::InvalidRunIdError) { run_id(minute: nil) }

    assert_equal("the minute of a run ID is a Time in the years 1000 to 9999, not nil", error.message)
  end

  # The message says what the characters are and what they got.
  def test_the_message_for_characters_names_the_value
    error = assert_raises(Proof::InvalidRunIdError) { run_id("m3d8u") }

    assert_equal('a run ID ends in five Crockford Base32 characters, not "m3d8u"', error.message)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidRunIdError, :<, Proof::Error)
  end
end

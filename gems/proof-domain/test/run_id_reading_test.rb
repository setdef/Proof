# frozen_string_literal: true

require_relative("test_helper")

# Checks how a run ID is read from text, and what text names a run.
class RunIdReadingTest < Minitest::Test
  # A run ID of the glossary's minute, 03:36 on 25 November 2026, UTC, and
  # these characters.
  def run_id(characters = "m3d8q")
    Proof::RunId.new(minute: Time.utc(2026, 11, 25, 3, 36), characters:)
  end

  # Style guide, "Names in examples": "A run ID | `20261125-0336-m3d8q`".
  def test_the_example_id_of_the_style_guide_reads_and_writes_back
    id = Proof::RunId.parse("20261125-0336-m3d8q")

    assert_equal([Time.utc(2026, 11, 25, 3, 36), "m3d8q", "20261125-0336-m3d8q"], [id.minute, id.characters, id.to_s])
  end

  # Glossary, "run": a run ID is "the minute ... then five random characters:
  # `20261125-0336-k7q2w`", and the text reads back as the same ID.
  def test_an_id_written_out_reads_back_as_the_same_id
    id = run_id("k7q2w")

    assert_equal(id, Proof::RunId.parse(id.to_s))
  end

  # Glossary, "run": the characters read "a typed `o` as `0`", in a full ID too.
  def test_a_full_id_is_read_with_the_same_rules_as_its_characters
    assert_equal("20261125-0336-m3081", Proof::RunId.parse("20261125-0336-M3O8L").to_s)
  end

  # Glossary, "run": a run ID is "the minute the run was created, in UTC, then
  # five random characters: `20261125-0336-k7q2w`", so text with another
  # number of digits or characters is not one.
  def test_text_of_another_length_is_refused
    %w[m3d8q 20261125-0336 2026112-0336-m3d8q 20261125-336-m3d8q 20261125-0336-m3d8].each do |text|
      assert_raises(Proof::InvalidRunIdError, text) { Proof::RunId.parse(text) }
    end
  end

  # Glossary, "run": a run ID is "the minute ... then five random characters:
  # `20261125-0336-k7q2w`", so text with other separators, or with anything
  # around it, is not one.
  def test_text_with_other_separators_or_surroundings_is_refused
    ["", " 20261125-0336-m3d8q", "20261125-0336-m3d8q\n", "20261125-0336-m3d8q-", "20261125_0336_m3d8q"].each do |text|
      assert_raises(Proof::InvalidRunIdError, text) { Proof::RunId.parse(text) }
    end
  end

  # Glossary, "run": the five characters come from Crockford's Base32, which
  # "has no `i`, `l`, `o`, or `u`", so a full ID with a `u` is not an ID.
  def test_a_full_id_with_a_character_outside_the_alphabet_is_refused
    assert_raises(Proof::InvalidRunIdError) { Proof::RunId.parse("20261125-0336-m3d8u") }
  end

  # Glossary, "run": "the minute the run was created" is a minute that exists.
  def test_a_minute_that_does_not_exist_is_refused
    %w[20261325-0336 20261100-0336 20260230-0336 20261125-2400 20261125-0360 20261125-2460].each do |minute|
      assert_raises(Proof::InvalidRunIdError, minute) { Proof::RunId.parse("#{minute}-m3d8q") }
    end
  end

  # A leap day is a minute that exists, in a leap year only.
  def test_a_leap_day_exists_in_a_leap_year_only
    assert_equal("20280229-0000-m3d8q", Proof::RunId.parse("20280229-0000-m3d8q").to_s)
    assert_raises(Proof::InvalidRunIdError) { Proof::RunId.parse("20270229-0000-m3d8q") }
  end

  # Glossary: each word names an idea, and the reading of an ID's text is part
  # of what a run ID is, so it adds no name of its own to the domain.
  def test_the_reading_of_an_ids_text_is_not_a_public_name
    refute_includes(Proof.constants, :RunIdText)
    assert_raises(NameError) { Proof::RunIdText.itself }
  end

  # A byte string that isn't valid text, as a command line can hold, is not an
  # ID, and raises the ID's error, not Ruby's.
  def test_text_with_invalid_bytes_is_refused
    assert_raises(Proof::InvalidRunIdError) { Proof::RunId.parse("20261125-0336-m3d\xFF8") }
  end

  # The message says what an ID looks like and what it got.
  def test_the_message_for_text_names_the_value
    error = assert_raises(Proof::InvalidRunIdError) { Proof::RunId.parse("m3d8q") }

    assert_equal('a run ID looks like 20261125-0336-m3d8q, not "m3d8q"', error.message)
  end

  # A value that is not text is not an ID either.
  def test_a_value_that_is_not_text_is_refused_when_read
    assert_raises(Proof::InvalidRunIdError) { Proof::RunId.parse(nil) }
  end

  # Glossary, "run": "Wherever Proof asks for a run's ID, the five characters
  # alone work".
  def test_the_five_characters_alone_identify_the_run
    assert(run_id.identified_by?("m3d8q"))
  end

  # Glossary, "run": the five characters are read as Crockford's Base32, "so
  # Proof reads a typed `o` as `0` and an `i` or `l` as `1`".
  def test_five_characters_typed_with_an_o_an_i_or_an_l_identify_the_run
    assert(run_id("m3081").identified_by?("M3o8L"))
    assert(run_id("m3081").identified_by?("m3o8i"))
  end

  # Glossary, "run": the full ID names the run too.
  def test_the_full_id_identifies_the_run
    assert(run_id.identified_by?("20261125-0336-m3d8q"))
    assert(run_id("m3081").identified_by?("20261125-0336-M3O8L"))
  end

  # Other characters, or another minute, name another run.
  def test_other_characters_or_another_minute_do_not_identify_the_run
    refute(run_id.identified_by?("k7q2w"))
    refute(run_id.identified_by?("20261125-0336-k7q2w"))
    refute(run_id.identified_by?("20261125-0337-m3d8q"))
  end

  # Text that is not an ID names no run, and is not an error.
  def test_text_that_is_not_an_id_identifies_no_run
    %w[m3d8 m3d8qx m3d8u 20261125-0336 20260230-0336-m3d8q m3d8q-].each do |text|
      refute(run_id.identified_by?(text), text)
    end
  end

  # Empty text names no run.
  def test_empty_text_identifies_no_run
    refute(run_id.identified_by?(""))
  end
end

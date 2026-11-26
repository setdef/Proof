# frozen_string_literal: true

require_relative("test_helper")

# Checks what is not a size, and what Proof says about it.
class SizeRefusedTest < Minitest::Test
  # The message of the refusal of this text, for the setting `name`.
  def refusal(text, name: "budget")
    error = assert_raises(Proof::InvalidSizeError) { Proof::Size.read(text, name:) }
    error.message
  end

  # Each text that has to be refused, as the test names it.
  def assert_refused(texts)
    texts.each { |text| assert_raises(Proof::InvalidSizeError, text.inspect) { Proof::Size.read(text, name: "budget") } }
  end

  # Pool file reference, "Sizes and labels", first table: `budget "400G"` is "Refused: `G` isn't a unit", and the
  # project file reference refuses `"8"`, which needs a unit, and `"8 gigabytes"`.
  def test_a_unit_that_is_not_in_the_list_or_is_missing_is_refused
    assert_refused(["400G", "8", "8 gigabytes", "400K", "400B", "400PB", "MB"])
  end

  # The same table: `budget 400GB` is refused because KDL reads it as the number 400 followed by `GB`, so a number
  # reaches the size and is refused as not text.
  def test_a_number_is_refused
    assert_refused([400, 1.5, nil, :"400GB", ["400GB"]])
  end

  # The same table: `keep-free "25 GB "` is "Refused: at most one space, between the number and the unit."
  def test_a_space_that_is_not_the_one_between_the_number_and_the_unit_is_refused
    assert_refused(["25 GB ", " 25GB", "25GB ", "25  GB", "25\tGB", "25GB\n"])
  end

  # Project file reference, "Sizes": a decimal "has digits on both sides of a point", and there is "no exponent and no
  # sign", so each of those forms is refused.
  def test_a_decimal_without_digits_on_both_sides_and_a_sign_and_an_exponent_are_refused
    assert_refused(%w[1,5GB .5GB 5.GB 1e3MB -1GB +1GB])
  end

  # A digit that isn't an ASCII digit is not a number.
  def test_a_digit_that_is_not_ascii_is_refused
    assert_refused(["٣GB"])
  end

  # A byte string that isn't valid text, and a string in an encoding that isn't ASCII-compatible, raise the size's
  # error, not Ruby's.
  def test_a_text_that_is_not_valid_or_not_ascii_compatible_is_refused
    assert_refused(["4\xFFGB", "4GB".encode(Encoding::UTF_16LE)])
  end

  # Pool file reference, "Sizes and labels": a size that breaks its rule is refused "with the forms that work in the
  # message", so the message names the setting, the forms, and what it got.
  def test_the_message_names_the_setting_the_forms_that_work_and_the_value
    assert_equal(
      "budget is a size: a number, whole or decimal, an optional space, and MB, GB, TB, MiB, GiB, or TiB in any " \
        "case, such as \"512MB\", \"8 GB\", \"1.5gib\", or \"0.5TB\", not \"400G\"",
      refusal("400G")
    )
    assert_equal(
      "limits output is a size: a number, whole or decimal, an optional space, and MB, GB, TB, MiB, GiB, or TiB " \
        "in any case, such as \"512MB\", \"8 GB\", \"1.5gib\", or \"0.5TB\", not 400",
      refusal(400, name: "limits output")
    )
  end

  # A size built from megabytes holds a whole number from 0.
  def test_megabytes_built_directly_are_a_whole_number_from_zero
    [-1, 1.5, "60", nil].each do |megabytes|
      assert_raises(Proof::InvalidSizeError, megabytes.inspect) { Proof::Size.new(megabytes:) }
    end
    assert_equal(0, Proof::Size.new(megabytes: 0).megabytes)
  end

  # The message for megabytes says what they are and what it got.
  def test_the_message_for_megabytes_names_the_value
    error = assert_raises(Proof::InvalidSizeError) { Proof::Size.new(megabytes: -1) }

    assert_equal("a size is a whole number of megabytes from 0, not -1", error.message)
  end

  # A size is equal only to a size of the same number of megabytes, and the error is a Proof::Error.
  def test_a_size_is_not_equal_to_a_number
    refute_equal(Proof::Size.new(megabytes: 1), 1)
    assert_operator(Proof::InvalidSizeError, :<, Proof::Error)
  end
end

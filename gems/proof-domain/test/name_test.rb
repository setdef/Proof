# frozen_string_literal: true

require_relative("test_helper")

# Checks the rule for a name: text with at least one character that isn't white space.
class NameTest < Minitest::Test
  TEXT = "text with at least one character that isn't white space"
  private_constant(:TEXT)

  # Pool file reference, "What happens when the file has a mistake": a name is refused when it is empty or only
  # spaces, so any other text is a name, one with a space in the middle too.
  def test_text_with_a_character_that_is_not_white_space_is_a_name
    ["nuc", "nuc-linux", "a", "my host", " nuc ", "lint:ruby", "v1..2", "é"].each do |text|
      assert(Proof::Name.valid?(text), "#{text.inspect} is a name")
    end
  end

  # The same sentence: a name that is empty or only white space is refused, and white space is more than the space,
  # so a tab, a line break, and the no-break and ideographic spaces count too.
  def test_empty_text_and_text_of_only_white_space_are_not_names
    ["", " ", "   ", "\t", "\n", " \t\n", " ", "　"].each do |text|
      refute(Proof::Name.valid?(text), text.inspect)
    end
  end

  # A name is text, so no other value is one.
  def test_a_value_that_is_not_text_is_not_a_name
    [nil, :nuc, 5, ["nuc"], 1.5, true].each { |value| refute(Proof::Name.valid?(value), value.inspect) }
  end

  # Text that can't be searched for white space is not a name: one with a byte that isn't valid, and one in an encoding
  # such as UTF-16 that ASCII-compatible patterns can't read. Neither raises.
  def test_text_that_cannot_be_read_is_not_a_name
    unreadable = ["\xFF", "nuc\xFF", "nuc".encode(Encoding::UTF_16LE)]

    unreadable.each { |text| refute(Proof::Name.valid?(text), text.inspect) }
  end

  # The message says whose name it is, what a name is, and gives a name that works, with a place for what was given.
  def test_the_message_says_what_a_name_is_and_gives_one_that_works
    assert_equal("a host's name is #{TEXT}, such as nuc, not %p", Proof::Name.message("a host's name", "nuc"))
  end

  # Reading a name gives it back, and a name that isn't one is refused with the message for that kind of name and the
  # value, as `p` shows it.
  def test_reading_a_name_gives_the_name_and_refuses_a_blank_one_with_the_message
    assert_equal("nuc", Proof::Name.read("nuc", what: "a host's name", example: "nuc").text)

    [[" ", "\" \""], ["", "\"\""], [nil, "nil"], [:nuc, ":nuc"]].each do |value, shown|
      error = assert_raises(Proof::InvalidNameError) do
        Proof::Name.read(value, what: "a runner's name", example: "nuc-linux")
      end

      assert_equal("a runner's name is #{TEXT}, such as nuc-linux, not #{shown}", error.message)
    end
  end

  # A name built from text holds a frozen copy of the text, so a change to the string it was given doesn't rename it.
  def test_a_name_holds_a_frozen_copy_of_its_text
    given = +"nuc"
    name = Proof::Name.new(text: given)
    given << "x"

    assert_equal("nuc", name.text)
    assert_predicate(name.text, :frozen?)
  end

  # A name built directly is checked with a message of its own, since nothing says whose name it is.
  def test_a_name_built_directly_is_refused_when_it_is_blank
    error = assert_raises(Proof::InvalidNameError) { Proof::Name.new(text: " ") }

    assert_equal("a name is #{TEXT}, such as nuc, not \" \"", error.message)
  end

  # Two names of the same text are equal.
  def test_names_of_one_text_are_equal
    assert_equal(Proof::Name.new(text: "nuc"), Proof::Name.new(text: "nuc"))
    refute_equal(Proof::Name.new(text: "nuc"), Proof::Name.new(text: "NUC"))
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidNameError, :<, Proof::Error)
  end
end

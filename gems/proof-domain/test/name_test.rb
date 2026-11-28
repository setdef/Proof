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

  # Reading a name gives back a frozen copy of its text, so a change to the string it was given doesn't rename it.
  def test_reading_a_name_gives_back_a_frozen_copy_of_its_text
    given = +"nuc"
    name = Proof::Name.read(given, what: "a host's name", example: "nuc")
    given << "x"

    assert_equal("nuc", name)
    assert_predicate(name, :frozen?)
  end

  # A name that isn't one is refused with the message for that kind of name and the value, as `p` shows it.
  def test_reading_a_value_that_is_not_a_name_is_refused_with_the_message
    [[" ", "\" \""], ["", "\"\""], [nil, "nil"], [:nuc, ":nuc"]].each do |value, shown|
      error = assert_raises(Proof::InvalidNameError) do
        Proof::Name.read(value, what: "a runner's name", example: "nuc-linux")
      end

      assert_equal("a runner's name is #{TEXT}, such as nuc-linux, not #{shown}", error.message)
    end
  end

  # Glossary, "name": Proof compares the names of hosts, runners, and repositories without regard to case, so `nuc` and
  # `NUC` are one name.
  def test_names_that_differ_only_in_case_are_the_same_name
    [%w[nuc NUC], %w[NUC nuc], %w[Nuc nUC], %w[nuc nuc]].each do |one, other|
      assert(Proof::Name.same?(one, other), "#{one} and #{other}")
    end
  end

  # Names that differ in more than case are two names, whatever their length.
  def test_names_that_differ_in_more_than_case_are_not_the_same_name
    [%w[nuc nuc-linux], %w[nuc pc], ["nuc", "nuc "], ["a", ""]].each do |one, other|
      refute(Proof::Name.same?(one, other), "#{one.inspect} and #{other.inspect}")
    end
  end

  # The comparison folds the case of letters beyond ASCII, as `String#casecmp?` does and `String#casecmp` does not.
  def test_names_that_differ_only_in_the_case_of_an_accented_letter_are_the_same_name
    assert(Proof::Name.same?("Ünal", "ünal"))
    assert(Proof::Name.same?("Édith", "édith"))
  end

  # A list of names is an Array of one or more names with none written twice, so names that differ in case are still a
  # list.
  def test_an_array_of_names_with_none_written_twice_is_a_list
    [["a"], %w[a b], %w[a A], %w[é É]].each { |names| assert(Proof::Name.list?(names), "#{names.inspect} is a list") }
  end

  # Whatever else is given is not a list: an empty Array, a name written twice, a member that isn't a name, a Set, and
  # a single name.
  def test_anything_else_is_not_a_list
    [[], %w[a a], ["a", 1], [nil], ["", "a"], [["a"]], Set["a"], "a", nil].each do |value|
      refute(Proof::Name.list?(value), value.inspect)
    end
  end

  # Names that differ only in case are one name, so a list that has two is not a distinct list.
  def test_a_list_of_names_that_all_differ_without_regard_to_case_is_a_distinct_list
    assert(Proof::Name.distinct_list?(%w[a b]))
    refute(Proof::Name.distinct_list?(%w[a A]))
    refute(Proof::Name.distinct_list?(%w[é É]))
  end

  # Whatever is not a list is not a distinct list.
  def test_whatever_is_not_a_list_is_not_a_distinct_list
    [[], %w[a a], ["a", 1], Set["a"], "a", nil].each { |value| refute(Proof::Name.distinct_list?(value), value.inspect) }
  end

  # Glossary, "name": names compare without regard to case, so the first name that repeats an earlier one is found
  # wherever the two are in the list, and the earlier one is the first that it repeats.
  def test_the_first_repeat_is_the_first_name_that_an_earlier_name_repeats
    assert_equal([1, 3], Proof::Name.first_repeat(%w[a b c B a]))
    assert_equal([0, 2], Proof::Name.first_repeat(%w[Nuc pc nuc NUC]))
    assert_equal([0, 1], Proof::Name.first_repeat(%w[Ünal ünal]))
  end

  # A list in which no name repeats an earlier one has no first repeat.
  def test_a_list_of_names_that_differ_has_no_repeat
    assert_nil(Proof::Name.first_repeat(%w[nuc pc nuc-linux]))
    assert_nil(Proof::Name.first_repeat([]))
  end

  # A value that isn't text, which the domain refuses elsewhere, is one name only with an equal value, so `5` and `"5"`
  # are two.
  def test_a_value_that_is_not_text_repeats_only_an_equal_value
    assert_nil(Proof::Name.first_repeat(["5", 5, :nuc, "nuc"]))
    assert_equal([1, 2], Proof::Name.first_repeat(["5", 5, 5]))
    assert_equal([0, 1], Proof::Name.first_repeat([nil, nil]))
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidNameError, :<, Proof::Error)
  end
end

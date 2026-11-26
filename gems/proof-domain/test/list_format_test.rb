# frozen_string_literal: true

require_relative("test_helper")

# Checks the English list a message writes its choices in: "and" or "or" before the last item, with a serial comma.
class ListFormatTest < Minitest::Test
  # Style guide, "Write American English: ... the serial comma." Three items or more take a comma after each but the
  # last, and the word before the last.
  def test_three_or_more_items_take_a_serial_comma
    assert_equal("runs, output, and artifacts", Proof::ListFormat.conjunction(%w[runs output artifacts]))
    assert_equal("s, m, or h", Proof::ListFormat.disjunction(%i[s m h]))
    assert_equal("a, b, c, or d", Proof::ListFormat.disjunction(%w[a b c d]))
  end

  # Two items take the word between them and no comma.
  def test_two_items_take_the_word_and_no_comma
    assert_equal("output and artifacts", Proof::ListFormat.conjunction(%w[output artifacts]))
    assert_equal("m or h", Proof::ListFormat.disjunction(%i[m h]))
  end

  # One item is itself, and no items are nothing, as `Intl.ListFormat` formats them.
  def test_one_item_is_itself_and_none_is_empty
    assert_equal(%w[port d], [Proof::ListFormat.conjunction(["port"]), Proof::ListFormat.disjunction([:d])])
    assert_equal(["", ""], [Proof::ListFormat.conjunction([]), Proof::ListFormat.disjunction([])])
  end

  # An item is written as its text, so a quoted example stays quoted.
  def test_each_item_is_written_as_its_text
    assert_equal("\"30m\" or \"2h\"", Proof::ListFormat.disjunction(["\"30m\"", "\"2h\""]))
  end
end

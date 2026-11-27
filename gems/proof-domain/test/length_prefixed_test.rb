# frozen_string_literal: true

require_relative("test_helper")

# Checks the salt fields of a slow tag, each written after its length, so no two lists of fields give one salt.
class LengthPrefixedTest < Minitest::Test
  # Architecture, "Certificates": "Every salt field is length-prefixed." Fields whose boundaries shift give different
  # bytes, where joined alone they would give one.
  def test_fields_whose_boundary_shifts_give_different_bytes
    refute_equal(Proof::LengthPrefixed.join("ab", "c"), Proof::LengthPrefixed.join("a", "bc"))
  end

  # An empty field is a field, so a list that ends in one differs from the list without it.
  def test_an_empty_field_differs_from_no_field
    refute_equal(Proof::LengthPrefixed.join("proof join"), Proof::LengthPrefixed.join("proof join", ""))
  end

  # Each field is its length in 8 bytes, most significant first, then its bytes.
  def test_each_field_is_its_length_in_eight_bytes_then_its_bytes
    expected = ["0000000000000005", "proof".unpack1("H*"), "0000000000000000", "0000000000000002ff01"].join

    assert_equal(expected, Proof::LengthPrefixed.join("proof", "", "\xFF\x01".b).unpack1("H*"))
  end

  # A length counts bytes, not characters, and the result is bytes whatever the fields' encoding.
  def test_a_length_counts_bytes_and_the_result_is_binary
    joined = Proof::LengthPrefixed.join("é")

    assert_equal("\x00\x00\x00\x00\x00\x00\x00\x02\xC3\xA9".b, joined)
    assert_equal(Encoding::BINARY, joined.encoding)
  end

  # No fields join to no bytes.
  def test_no_fields_join_to_empty_bytes
    joined = Proof::LengthPrefixed.join

    assert_equal("".b, joined)
    assert_equal(Encoding::BINARY, joined.encoding)
  end
end

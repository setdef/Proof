# frozen_string_literal: true

require_relative("test_helper")

# Checks that the reader of KDL text raises the error class its caller names, for every way a text can be refused, so
# the pool file's reader raises the pool file's error and the project file's reader raises the project file's.
class KdlParserErrorTest < Minitest::Test
  # The error a caller names for the mistakes in its own kind of file.
  class OtherFileError < Proof::FileError
  end
  private_constant(:OtherFileError)

  # Raises the error that parsing this text with this error class raises, and checks that it is that class.
  def refusal(text, error: OtherFileError)
    assert_raises(error) { Proof::KdlParser.parse(text, path: "other.kdl", error:) }
  end

  # Project file reference, "Where Proof reads the file": the file's own mistakes in KDL are refused with the line, so a
  # text that isn't KDL 2 raises the caller's error, naming the caller's file.
  def test_a_text_that_is_not_kdl_raises_the_callers_error
    error = refusal("a b=\n")

    assert_equal(["other.kdl", 1], [error.path, error.line])
  end

  # The same sentence, for a byte that isn't UTF-8, which is refused at its line.
  def test_a_byte_that_is_not_utf8_raises_the_callers_error
    error = refusal("a\nb \"\xFF\"\n")

    assert_equal(2, error.line)
  end

  # The same sentence, for a string that a backslash ends the text in, which is refused at the last line.
  def test_a_string_that_ends_in_a_backslash_raises_the_callers_error
    error = refusal("a\nb \"x\\")

    assert_equal(2, error.line)
  end

  # Reading a text with no mistake gives its nodes, whatever error class the caller names.
  def test_a_text_with_no_mistake_gives_its_nodes
    nodes = Proof::KdlParser.parse("server port=7443\n", path: "other.kdl", error: OtherFileError)

    assert_equal(["server"], nodes.map(&:name))
  end
end

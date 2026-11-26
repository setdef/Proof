# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the text of a pool file as KDL, and the path an error names.
class PoolFileReaderKdlTest < Minitest::Test
  include PoolFileReaderHelper

  # Pool file reference, "What happens when the file has a mistake": the mistake is shown "with its line", and the pool
  # file is "KDL 2.0", so text that is not KDL 2 is refused at its line, with the pool file's error.
  def test_text_that_is_not_kdl_is_refused_at_its_line
    error = assert_raises(Proof::PoolFileError) { read("server port=7443\nretention runs=\n") }

    assert_equal(["pool.kdl", 2], [error.path, error.line])
  end

  # The same sentence: "a size such as `4GB` needs quotes", so a size written without them is refused as text that is
  # not KDL, with the quotes that work.
  def test_an_unquoted_size_is_refused_with_the_way_to_quote_it
    assert_refused(
      "limits output=1GB\n",
      1,
      "this is not valid KDL 2: unexpected IDENT \"GB\" at column 16. If a value starts with a digit and continues " \
        "with letters, put it in quotes, as in budget \"400GB\" or limits output=\"1GB\""
    )
  end

  # The same sentence: "KDL 2.0", so a text that is KDL 1 and not KDL 2 is refused, and never read as KDL 1.
  def test_text_that_is_kdl_1_and_not_kdl_2_is_refused
    assert_raises(Proof::PoolFileError) { read("server port=7443 true\n") }
    assert_raises(Proof::PoolFileError) { read("/- kdl-version 1\nserver port=7443\n") }
  end

  # Pool file reference, "The pool file is `~/.config/proof/pool.kdl`": an error names the file, which is that path
  # unless the caller reads another.
  def test_an_error_names_the_file_it_read
    default = assert_raises(Proof::PoolFileError) { Proof::PoolFileReader.read("server 1\n") }
    other = assert_raises(Proof::PoolFileError) { Proof::PoolFileReader.read("server 1\n", path: "other.kdl") }

    assert_equal(["~/.config/proof/pool.kdl", "other.kdl"], [default.path, other.path])
  end

  # Every mistake is one error type, so a caller rescues it once: a mistake in the text, a node the page doesn't list,
  # and a value the domain refuses.
  def test_every_mistake_is_one_error_type
    ["server port=\n", "cluster\n", "server port=0\n"].each do |text|
      assert_raises(Proof::PoolFileError, text) { read(text) }
    end
    assert_operator(Proof::PoolFileError, :<, Proof::FileError)
  end

  # The reader takes text and a path and reads nothing else, so it is the same as `ProjectFileReader.read` in that.
  def test_reading_the_same_text_twice_gives_equal_pool_files
    text = "server port=8443\nretention output=\"30d\"\n"

    assert_equal(read(text), read(text))
  end
end

# frozen_string_literal: true

require_relative("test_helper")

# Checks the error that every mistake in a file Proof reads raises, which the project file's error and the pool file's
# error share.
class FileErrorTest < Minitest::Test
  # Project file reference, "Where Proof reads the file": a refusal names "the file, the line, and what's wrong".
  def test_the_message_names_the_file_the_line_and_the_reason
    error = Proof::FileError.new(path: "pool.kdl", line: 7, reason: "a label has no space")

    assert_equal("pool.kdl:7: a label has no space", error.message)
  end

  # A mistake with no line, such as a file that is a symbolic link, names the file and the reason.
  def test_a_mistake_with_no_line_leaves_the_line_out
    error = Proof::FileError.new(path: "pool.kdl", line: nil, reason: "this is a symbolic link")

    assert_equal("pool.kdl: this is a symbolic link", error.message)
  end

  # The file, the line, and the reason are each readable, so a caller can show them apart.
  def test_the_file_the_line_and_the_reason_are_readable
    error = Proof::FileError.new(path: "pool.kdl", line: 7, reason: "a label has no space")

    assert_equal(["pool.kdl", 7, "a label has no space"], [error.path, error.line, error.reason])
  end

  # Every error the code around the domain raises on purpose is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::FileError, :<, Proof::Error)
  end

  # The project file's error is a file error, with the same message, so a caller that rescues file errors catches it.
  def test_the_project_file_error_is_a_file_error
    error = Proof::ProjectFileError.new(path: ".config/proof.kdl", line: 2, reason: "a task has a name")

    assert_equal([true, ".config/proof.kdl:2: a task has a name"], [error.is_a?(Proof::FileError), error.message])
  end
end

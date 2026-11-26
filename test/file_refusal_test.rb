# frozen_string_literal: true

require_relative("test_helper")

# Checks what every class that refuses a file's nodes shares: the file's path, the error class it raises, and its
# messages.
class FileRefusalTest < Minitest::Test
  # The error a kind of file raises.
  class OtherFileError < Proof::FileError
  end

  # A refusal with one message of its own, as the project file's and the pool file's refusals have.
  class OddRefusal < Proof::FileRefusal
    MESSAGES = { odd: "a node here has %d arguments, and %p is odd" }.freeze
    private_constant(:MESSAGES)

    def initialize(path:)
      super(path:, error: OtherFileError, messages: MESSAGES)
    end

    def odd(node, count)
      say(node, :odd, count, node.name)
    end
  end
  private_constant(:OtherFileError, :OddRefusal)

  # The node on line 3 of this text.
  def node
    Proof::KdlNode.new(name: "host", arguments: [], properties: {}, children: [], line: 3)
  end

  # Project file reference, "Where Proof reads the file": a refusal names the file, the line of the node, and what's
  # wrong, as the error its kind of file raises.
  def test_a_refusal_raises_its_error_with_the_path_the_node_line_and_the_message
    error = assert_raises(OtherFileError) { OddRefusal.new(path: "pool.kdl").odd(node, 5) }

    assert_equal(
      ["pool.kdl", 3, "a node here has 5 arguments, and \"host\" is odd"], [error.path, error.line, error.reason]
    )
  end

  # What the domain refuses while a block builds a value is refused at the line of the node it builds from.
  def test_what_the_domain_refuses_is_refused_at_the_line_of_the_node
    error = assert_raises(OtherFileError) do
      OddRefusal.new(path: "pool.kdl").checking(node) { Proof::Label.new(name: "nvidia gpu") }
    end

    domain = assert_raises(Proof::InvalidLabelError) { Proof::Label.new(name: "nvidia gpu") }

    assert_equal(["pool.kdl", 3, domain.message], [error.path, error.line, error.reason])
  end

  # An error that already names a file and a line, as a block that reads a child node raises, passes through, so the
  # line of the child is not replaced by the line of its parent.
  def test_an_error_that_names_a_file_and_a_line_passes_through
    inner = OtherFileError.new(path: "pool.kdl", line: 4, reason: "a child went wrong")
    error = assert_raises(OtherFileError) { OddRefusal.new(path: "pool.kdl").checking(node) { raise(inner) } }

    assert_same(inner, error)
  end

  # A block that builds its value with no refusal gives the value.
  def test_a_block_with_no_refusal_gives_its_value
    assert_equal("gpu", OddRefusal.new(path: "pool.kdl").checking(node) { Proof::Label.new(name: "gpu").name })
  end
end

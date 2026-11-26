# frozen_string_literal: true

require_relative("../test_helper")
require "json"

# Checks that a node of the spec's JSON answers each question with one type.
class CommandLineSpecNodeTest < Minitest::Test
  NODE = Proof::CommandLine::Spec::Node.new(
    JSON.parse('{"a": 1, "b": "x", "c": [1, "y"], "d": {}, "e": false, "f": true}')
  )
  private_constant(:NODE)

  # A key that holds a number is no text.
  def test_a_key_that_holds_another_type_reads_as_no_text
    assert_nil(NODE.text("a"))
    assert_equal("x", NODE.text("b"))
  end

  # A key that holds no Array reads as an empty list, and an Array keeps only its Strings.
  def test_texts_keep_only_the_strings_of_an_array
    assert_empty(NODE.texts("b"))
    assert_equal(["y"], NODE.texts("c"))
  end

  # A key that holds no number reads as 0.
  def test_a_key_that_holds_another_type_reads_as_zero
    assert_equal(1, NODE.whole_number("a"))
    assert_equal(0, NODE.whole_number("b"))
  end

  # A key that holds no object reads as no node.
  def test_a_key_that_holds_no_object_reads_as_no_node
    assert_nil(NODE.node("b"))
    assert_instance_of(Proof::CommandLine::Spec::Node, NODE.node("d"))
  end

  # A key that holds no list or object reads as an empty list.
  def test_a_key_that_holds_another_type_reads_as_an_empty_list_of_values
    assert_empty(NODE.read_all("b", Proof::CommandLine::Spec::Flag))
    assert_empty(NODE.read_members("b", Proof::CommandLine::Spec::Flag))
  end

  # A list that holds no objects reads as an empty list.
  def test_a_list_of_other_types_reads_as_empty
    assert_empty(NODE.read_all("c", Proof::CommandLine::Spec::Flag))
  end

  # An object's values that aren't objects are left out.
  def test_an_object_of_other_types_reads_as_empty
    assert_empty(Proof::CommandLine::Spec::Node.new(JSON.parse('{"m": {"x": 1}}')).read_members("m", Proof::CommandLine::Spec::Flag))
  end

  # A key set to true is true, and any other is not.
  def test_true_is_only_the_value_true
    assert(NODE.true?("f"))
    refute(NODE.true?("e"))
    refute(NODE.true?("b"))
  end

  # A key set to false differs from an absent key.
  def test_a_key_set_to_false_differs_from_an_absent_key
    assert(NODE.false?("e"))
    refute(NODE.false?("absent"))
  end
end

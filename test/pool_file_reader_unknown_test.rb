# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the shape of a pool file: nodes, properties, and children that the page doesn't list, a node
# given twice, and the arguments of a node.
class PoolFileReaderUnknownTest < Minitest::Test
  include PoolFileReaderHelper

  UNKNOWN_PROPERTIES = [
    ["server host=\"nuc\"\n", 1, "a \"server\" node has no property \"host\". Its only property is port"],
    [
      "\nretention days=\"90d\"\n",
      2,
      "a \"retention\" node has no property \"days\". Its properties are runs, output, and artifacts",
    ],
    ["limits max=\"1GB\"\n", 1, "a \"limits\" node has no property \"max\". Its properties are output and artifacts"],
  ].freeze
  ARGUMENTS = [
    ["server 7443\n", "a \"server\" node takes no arguments, as in server port=7443, and this one has 1"],
    [
      "retention \"90d\" \"14d\"\n",
      "a \"retention\" node takes no arguments, as in retention runs=\"90d\" output=\"14d\" artifacts=\"7d\", " \
        "and this one has 2",
    ],
    [
      "limits \"1GB\"\n",
      "a \"limits\" node takes no arguments, as in limits output=\"1GB\" artifacts=\"16GB\", and this one has 1",
    ],
  ].freeze
  private_constant(:UNKNOWN_PROPERTIES, :ARGUMENTS)

  # Project file reference, "Mistakes Proof catches", which the pool file reference points to: "a node or property
  # isn't one this page lists", for a node.
  def test_an_unknown_node_is_refused
    assert_refused(
      "server port=7443\n\nlimit output=\"1GB\"\n",
      3,
      "there is no node \"limit\" in a pool file. A pool file has \"server\", \"retention\", \"limits\", " \
        "\"defaults\", \"host\", and \"repository\" nodes"
    )
  end

  # The same bullet, for a property of `server`, `retention`, and `limits`.
  def test_an_unknown_property_is_refused
    UNKNOWN_PROPERTIES.each do |text, line, reason|
      assert_refused(text, line, reason)
    end
  end

  # The same bullet, for a child of a node that has properties only.
  def test_a_child_of_a_node_that_has_properties_only_is_refused
    assert_refused(
      "server port=7443 {\n  tls yes\n}\n", 2, "a \"server\" node has no child \"tls\". It has no children"
    )
  end

  # Pool file reference, "`server`": a node is given once, so `server` twice is refused at the second, and the
  # refusal names the first, as the project file's does for `defaults`.
  def test_a_node_given_twice_is_refused_at_the_second
    %w[server retention limits].each do |name|
      assert_refused(
        "#{name}\n\n#{name}\n",
        3,
        "a pool file has at most one \"#{name}\" node, and the first is on line 1. Merge them into one"
      )
    end
  end

  # Pool file reference, "`server`": `server port=7443` has properties and no arguments, so an argument is refused,
  # and so is one on `retention` and `limits`.
  def test_arguments_on_a_node_that_takes_properties_are_refused
    ARGUMENTS.each do |text, reason|
      assert_refused(text, 1, reason)
    end
  end
end

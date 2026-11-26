# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the shape of a `defaults` or `host` node: its arguments, its properties, and its children.
class PoolFileReaderChildrenTest < Minitest::Test
  include PoolFileReaderHelper

  HOST_USAGE = "host nuc { runner nuc-linux; budget \"400GB\" }"
  HOST = "a \"host\" node has no child"
  HOST_CHILDREN = "Its children are runner, budget, keep-free, share, active-for, and withhold"
  DEFAULTS_CHILDREN = "Its children are budget, keep-free, share, active-for, and withhold"
  UNKNOWN_CHILDREN = [
    ["host nuc {\n  runner nuc-linux\n  gpu yes\n}\n", 3, "#{HOST} \"gpu\". #{HOST_CHILDREN}"],
    ["host a {\n  host b\n}\n", 2, "#{HOST} \"host\". #{HOST_CHILDREN}"],
    [
      "defaults {\n  runner nuc-linux\n}\n",
      2,
      "a \"defaults\" node has no child \"runner\". #{DEFAULTS_CHILDREN}",
    ],
  ].freeze
  NAMES = [
    ["host {\n  budget \"1GB\"\n}\n", 1, "a \"host\" node takes one argument, as in #{HOST_USAGE}, and this one has 0"],
    ["host a b\n", 1, "a \"host\" node takes one argument, as in #{HOST_USAGE}, and this one has 2"],
    [
      "defaults \"x\"\n",
      1,
      "a \"defaults\" node takes no arguments, as in defaults { budget \"100GB\" }, and this one has 1",
    ],
  ].freeze
  BLANKS = [
    ["host \"\" {\n  runner a\n}\n", 1, "a host's name is not empty and not only spaces, not \"\""],
    ["host \"  \" {\n  runner a\n}\n", 1, "a host's name is not empty and not only spaces, not \"  \""],
    ["host a {\n  runner b \" \"\n}\n", 2, "a runner's name is not empty and not only spaces, not \" \""],
  ].freeze
  private_constant(:HOST_USAGE, :HOST, :HOST_CHILDREN, :DEFAULTS_CHILDREN, :UNKNOWN_CHILDREN, :NAMES, :BLANKS)

  # Project file reference, "Mistakes Proof catches", which the pool file reference points to: "a node or property isn't
  # one this page lists", for a child of `host` and of `defaults`. `defaults` "takes the same children as a `host`,
  # except `runner`", so `runner` in `defaults` is refused.
  def test_an_unknown_child_is_refused
    assert_refusals(UNKNOWN_CHILDREN)
  end

  # Pool file reference, "`host`": `host NAME` has one argument, its name, so a host with none or two is refused, and
  # "`defaults`" takes children and no arguments.
  def test_a_host_with_no_name_or_two_names_and_defaults_with_an_argument_are_refused
    assert_refusals(NAMES)
  end

  # Project file reference, "Mistakes Proof catches" and issue #52: "a blank name", so `host ""` and a name of only
  # spaces are refused, and so is a blank runner.
  def test_a_blank_host_name_or_runner_is_refused
    assert_refusals(BLANKS)
  end

  # Pool file reference, "`host`": the children are children, not properties, so `budget="1GB"` on the host is refused
  # with the way to write it, as the project file's reader does for `os=linux`.
  def test_a_child_written_as_a_property_is_refused_with_the_way_to_write_it
    assert_refused(
      "host nuc budget=\"1GB\"\n",
      1,
      "\"budget\" is a child node, not a property. Put it in the node's block, with every value as an argument"
    )
  end

  # The same page: a property that is not one of the host's children is refused, because a host has no properties.
  def test_an_unknown_property_of_a_host_is_refused
    assert_refused("host nuc os=\"linux\"\n", 1, "a \"host\" node has no property \"os\". It has no properties")
  end

  # Pool file reference, "`host`": the `runner` child is "Written by `proof runner approve`", and a host with none has
  # nothing to run, so a host with no `runner` is refused at the host's line.
  def test_a_host_with_no_runner_is_refused
    assert_refused(
      "host a {\n  budget \"1GB\"\n}\n",
      1,
      "a \"host\" node needs the child \"runner\", as in host nuc { runner nuc-linux; budget \"400GB\" }"
    )
  end

  # Pool file reference, "`server`": `port` is a property, so one written as a child is refused at the child's line,
  # with the form that works.
  def test_a_property_written_as_a_child_is_refused_with_the_form_that_works
    assert_refused(
      "server {\n  port 7443\n}\n",
      2,
      "\"port\" is a property, not a child node. Write it on the line of the node, as in server port=7443"
    )
  end
end

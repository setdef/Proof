# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in how often a child is given and how many arguments it takes, from issue #52's readings of
# the project file's rules, applied to the children of `defaults` and `host`.
class PoolFileReaderRepeatsTest < Minitest::Test
  include PoolFileReaderHelper

  TWICE = "is given twice, and the first is on line"
  USAGES = [
    ["budget", "budget \"100GB\""], ["keep-free", "keep-free \"25GB\""], ["active-for", "active-for \"5m\""]
  ].freeze
  NONE = [
    [
      "host a {\n  runner\n}\n",
      2,
      "a \"runner\" node takes one or more arguments, as in runner nuc-linux, and this one has 0",
    ],
    [
      "defaults {\n  withhold\n}\n",
      2,
      "a \"withhold\" node takes one or more arguments, as in withhold gpu desktop, and this one has 0",
    ],
    [
      "defaults {\n  budget\n}\n",
      2,
      "a \"budget\" node takes one argument, as in budget \"100GB\", and this one has 0",
    ],
  ].freeze
  MORE = [
    ["defaults {\n  budget \"1GB\" size=1\n}\n", 2, "a \"budget\" node has no property \"size\". It has no properties"],
    ["defaults {\n  withhold gpu {\n    x\n  }\n}\n", 3, "a \"withhold\" node has no child \"x\". It has no children"],
    ["host a {\n  runner r {\n    x\n  }\n}\n", 3, "a \"runner\" node has no child \"x\". It has no children"],
  ].freeze
  private_constant(:TWICE, :USAGES, :NONE, :MORE)

  # The refusal of this child given twice, as a list of lines `first` and `second` in `defaults`, at the second.
  def twice(name, first, second)
    reason = "\"#{name}\" #{TWICE} 2. Give every value as arguments to one \"#{name}\" node"

    ["defaults {\n  #{first}\n  #{second}\n}\n", 3, reason]
  end

  # Issue #52, "a child node given twice": "refuse it, and say to give every value as arguments to one node", for each
  # child that is a single setting, and not for `runner`, which the page's example gives twice.
  def test_a_single_setting_given_twice_is_refused_at_the_second
    assert_refusals(USAGES.map { |name, _usage| twice(name, "#{name} \"1m\"", "#{name} \"2m\"") })
  end

  # The same sentence, for `withhold`, a list, and for `share`, which takes properties.
  def test_a_list_and_a_share_given_twice_are_refused_at_the_second
    assert_refusals(
      [
        twice("withhold", "withhold gpu", "withhold kvm"),
        twice("share", "share cpus=1 memory=\"1GB\"", "share cpus=2 memory=\"2GB\""),
      ]
    )
  end

  # Issue #52, "a child node with no arguments": "refuse it, since the page says each takes one or more", for a list,
  # and for a child that takes one argument.
  def test_a_child_with_no_arguments_is_refused
    assert_refusals(NONE)
  end

  # The same page: `budget "SIZE"`, `keep-free "SIZE"`, and `active-for "DURATION"` take one argument, so two are
  # refused.
  def test_a_child_with_too_many_arguments_is_refused
    USAGES.each do |name, usage|
      assert_refused(
        "defaults {\n  #{name} \"1m\" \"2m\"\n}\n",
        2,
        "a \"#{name}\" node takes one argument, as in #{usage}, and this one has 2"
      )
    end
  end

  # A child that takes arguments has no properties and no block, so one with either is refused, at the line of the
  # property's node or of the block's first node.
  def test_a_child_with_properties_or_a_block_is_refused
    assert_refusals(MORE)
  end
end

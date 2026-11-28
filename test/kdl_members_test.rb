# frozen_string_literal: true

require_relative("test_helper")

# Checks that a table of members builds the values a node gives, in the order the node has them, and refuses a value
# the domain refuses at the line of the node that gave it.
class KdlMembersTest < Minitest::Test
  TABLE = {
    cpus: [:task_cpus, -> (node) { Integer(node.properties["cpus"]) }],
    "keep-free": [:keep_free, -> (node) { node.arguments.first.upcase }],
    label: [:labels, -> (node) { node.arguments.sort }],
    refused: [:refused, -> (_node) { raise(Proof::Error, "the domain says no") }],
  }.freeze
  private_constant(:TABLE)

  def members
    Proof::KdlMembers.new(TABLE, refusal: Proof::PoolFileReader.new(path: "pool.kdl").file.refusal(Proof::PoolFileRefusal))
  end

  def parse(text)
    Proof::KdlParser.parse(text, path: "pool.kdl", error: Proof::PoolFileError).first
  end

  # Project file reference, "The `defaults` and `task` nodes": a property gives the member of the task it names, with
  # the value the domain builds from it.
  def test_the_properties_of_a_node_give_the_members_they_name
    assert_equal({ task_cpus: 4 }, members.of_properties(parse("task cpus=4\n")))
  end

  # The same page: each child of a block gives the member it names, in the order the block has them.
  def test_the_children_of_a_node_give_the_members_they_name_in_the_order_the_node_has_them
    built = members.of_children(parse("host {\n  label b a\n  keep-free \"2gb\"\n}\n"))

    assert_equal([[:labels, %w[a b]], [:keep_free, "2GB"]], built.to_a)
  end

  # A name the table doesn't list gives no member, because the form check has refused what a page doesn't list before a
  # value is built.
  def test_a_name_the_table_lacks_gives_no_member
    given = parse("host other=1 {\n  other\n}\n")

    assert_equal([{}, {}], [members.of_properties(given), members.of_children(given)])
  end

  # Pool file reference, "What happens when the file has a mistake": a value the domain refuses is refused with the
  # line of the node that gave it, which for a property is the node and for a child is the child.
  def test_a_value_the_domain_refuses_is_refused_at_the_line_of_its_giver
    parent = parse("\nhost refused=1 {\n\n  refused\n}\n")

    by_property = assert_raises(Proof::PoolFileError) { members.of_properties(parent) }
    by_child = assert_raises(Proof::PoolFileError) { members.of_children(parent) }

    refused = [by_property, by_child].map { |error| [error.line, error.reason] }

    assert_equal([[2, "the domain says no"], [4, "the domain says no"]], refused)
  end
end

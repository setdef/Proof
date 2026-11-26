# frozen_string_literal: true

require_relative("support/project_file_reader_helper")

# Checks the mistakes in the shape of a project file: nodes, properties, and children that the page doesn't list, and the arguments of `defaults` and `task`.
class ProjectFileReaderUnknownTest < Minitest::Test
  include ProjectFileReaderHelper

  # Project file reference, "Mistakes Proof catches": "a node or property isn't one this page lists", for a node.
  def test_an_unknown_node_is_refused
    assert_refused(
      "defaults cpus=4\n\ntasks test\n",
      3,
      "there is no node \"tasks\" in a project file. A project file has \"defaults\" and \"task\" nodes"
    )
  end

  # The same bullet, for a property of a task entry.
  def test_an_unknown_property_of_a_task_is_refused
    assert_refused(
      "task test\ntask lint cpu=4\n",
      2,
      "a \"task\" node has no property \"cpu\". Its properties are cpus, memory, and timeout"
    )
  end

  # The same bullet, for a property of `defaults`.
  def test_an_unknown_property_of_defaults_is_refused
    assert_refused(
      "defaults ram=\"8GB\"\n",
      1,
      "a \"defaults\" node has no property \"ram\". Its properties are cpus, memory, and timeout"
    )
  end

  # The same bullet, for a child.
  def test_an_unknown_child_is_refused
    assert_refused(
      "task test {\n  os linux\n  gpu yes\n}\n",
      3,
      "a \"task\" node has no child \"gpu\". Its children are os, label, artifact, and cache"
    )
  end

  # The same bullet, for a child of `defaults`.
  def test_an_unknown_child_of_defaults_is_refused
    assert_refused(
      "defaults {\n  tag x\n}\n",
      2,
      "a \"defaults\" node has no child \"tag\". Its children are os, label, artifact, and cache"
    )
  end

  # The same bullet, for `task` inside a task, which is a node the page lists but not as a child.
  def test_a_task_inside_a_task_is_refused
    assert_refused(
      "task a {\n  task b\n}\n",
      2,
      "a \"task\" node has no child \"task\". Its children are os, label, artifact, and cache"
    )
  end

  # The same bullet, for a child written at the top of the file, which is a node the page lists but not there.
  def test_a_child_at_the_top_of_the_file_is_refused
    assert_refused(
      "task a\nos linux\n",
      2,
      "there is no node \"os\" in a project file. A project file has \"defaults\" and \"task\" nodes"
    )
  end

  # The same bullet, for a property written as a child: the page lists `cpus` as a property only, so a `cpus` child
  # is a child the node doesn't have.
  def test_a_property_written_as_a_child_is_refused_as_an_unknown_child
    assert_refused(
      "task a {\n  cpus 4\n}\n",
      2,
      "a \"task\" node has no child \"cpus\". Its children are os, label, artifact, and cache"
    )
  end

  # The warning: "Wrong: defaults os=linux os=macos os=windows". `os` is a child and not a property, so Proof
  # refuses the page's own wrong example, with the way to write it.
  def test_a_child_written_as_a_property_is_refused_with_the_way_to_write_it
    assert_refused(
      "defaults os=linux os=macos os=windows\n",
      1,
      "\"os\" is a child node, not a property. Put it in the node's block, with every value as an argument"
    )
  end

  # Project file reference, "`defaults`": "A file has at most one `defaults` node", and the refusal names the second.
  def test_a_second_defaults_node_is_refused
    assert_refused(
      "defaults cpus=4\ntask a\ndefaults cpus=2\n",
      3,
      "a project file has at most one \"defaults\" node, and the first is on line 1. Merge them into one"
    )
  end

  # The same sentence: `defaults` "takes the same properties and children as a `task`, except a command", so a
  # command is an argument it doesn't take.
  def test_defaults_with_an_argument_is_refused
    assert_refused(
      "defaults \"make\" cpus=4\n",
      1,
      "a \"defaults\" node takes properties and children and no arguments, as in defaults cpus=4"
    )
  end

  # Project file reference, "`task`": the form is `task NAME [COMMAND]`, so no name is a mistake, and so is a
  # third argument.
  def test_a_task_with_no_name_or_too_many_arguments_is_refused
    message = "a task entry is task NAME or task NAME COMMAND, such as task test or task docs \"make docs\", " \
      "and this one has %d arguments"

    assert_refused("task cpus=4\n", 1, format(message, 0))
    assert_refused("task a \"make\" extra\n", 1, format(message, 3))
  end
end

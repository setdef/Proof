# frozen_string_literal: true

require_relative("kdl_refusal")

module Proof
  class ProjectFileRefusal < KdlRefusal
    MESSAGES = {
      unknown_node: "there is no node %<name>p in a project file. " \
        "A project file has \"defaults\" and \"task\" nodes",
      repeated_node: "a project file has at most one %<name>p node, and the first is on line %<line>d. " \
        "Merge them into one",
      defaults_arguments: "a \"defaults\" node takes properties and children and no arguments, as in defaults cpus=4",
      task_arguments: "a task entry is task NAME or task NAME COMMAND, such as task test or task docs \"make docs\", " \
        "and this one has %<count>d arguments",
      child_without_arguments: "%<name>p takes one or more arguments, and this one has none",
      unknown_property: "a %<name>p node has no property %<property>p. %<known>s",
      property_that_is_a_child: "%<property>p is a child node, not a property. " \
        "Put it in the node's block, with every value as an argument",
      unknown_child: "a %<name>p node has no child %<child>p. %<known>s",
      child_with_more: "%<name>p takes arguments only, with no properties and no children",
      repeated_child: "%<name>p is given twice, and the first is on line %<line>d. " \
        "Give every value as arguments to one %<name>p node",
      repeated_task: "two task entries are named %<entry>p, and the first is on line %<line>d. " \
        "A name appears in only one task entry, so merge them into one",
      blank_command: "a task's command is text with at least one character that isn't white space, " \
        "such as \"make docs\", not %<command>p. " \
        "Leave the command out to run the mise task of the same name",
    }.freeze
    ARGUMENTS = { defaults: :defaults_arguments, task: :task_arguments }.freeze
    public_constant(:MESSAGES)
    private_constant(:ARGUMENTS)

    def node_arguments(node, count)
      # The page writes the arguments of each node its own way: a task's name and command, none for defaults, and
      # one or more for a child.
      say_of(node, ARGUMENTS.fetch(node.name.to_sym, :child_without_arguments), count:)
    end

    def stray_property(node, property)
      return say_of(node, :child_with_more) if form_of(node).arguments_only?

      super
    end

    def stray_child(parent, child)
      # A child that has the name of a property is a child the node doesn't have, as any other is, and a child of a
      # child is refused at the child, which takes arguments only.
      return say_of(parent, :child_with_more) if form_of(parent).arguments_only?

      unknown_child(parent, child)
    end

    def repeated_task(node, first)
      say(node, :repeated_task, entry: node.arguments.first, line: first.line)
    end

    def blank_command(node, command)
      say(node, :blank_command, command:)
    end
  end
end

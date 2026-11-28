# frozen_string_literal: true

require_relative("kdl_refusal")

module Proof
  class PoolFileRefusal < KdlRefusal
    MESSAGES = {
      unknown_node: "there is no node %<name>p in a pool file. " \
        "A pool file has \"server\", \"retention\", \"limits\", \"defaults\", \"host\", and \"repository\" nodes",
      repeated_node: "a pool file has at most one %<name>p node, and the first is on line %<line>d. " \
        "Merge them into one",
      node_arguments: "a %<name>p node takes %<takes>s, as in %<usage>s, and this one has %<count>d",
      unknown_property: "a %<name>p node has no property %<property>p. %<known>s",
      property_that_is_a_child: "%<property>p is a child node, not a property. " \
        "Put it in the node's block, with every value as an argument",
      unknown_child: "a %<name>p node has no child %<child>p. %<known>s",
      child_that_is_a_property: "%<child>p is a property, not a child node. " \
        "Write it on the line of the node, as in %<usage>s",
      repeated_child: "%<name>p is given twice, and the first is on line %<line>d. " \
        "Give every value as arguments to one %<name>p node",
      repeated_entry: "a second %<name>s is named %<entry>p, and the first is on line %<line>d. " \
        "Each %<name>s has one entry, so merge them into one",
      shared_runner: "the runner %<runner>p is also on the host %<entry>p, whose entry starts on line %<line>d. " \
        "A runner is one operating system on one host, so list it on one",
      missing: "a %<name>p node needs the %<kind>s %<missing>p, as in %<usage>s",
    }.freeze
    EARLIER = -> (node) { { entry: node.arguments.first, line: node.line } }
    public_constant(:MESSAGES)
    private_constant(:EARLIER)

    def repeated_entry(node, first)
      say_of(node, :repeated_entry, **EARLIER.call(first))
    end

    def shared_runner(child, runner, host)
      say(child, :shared_runner, runner:, **EARLIER.call(host))
    end
  end
end

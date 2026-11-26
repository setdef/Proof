# frozen_string_literal: true

module Proof
  class ProjectFileRefusal
    MESSAGES = {
      unknown_node: "there is no node %p in a project file. A project file has \"defaults\" and \"task\" nodes",
      repeated_defaults: "a project file has at most one \"defaults\" node, and the first is on line %d. " \
        "Merge them into one",
      repeated_task: "two task entries are named %p, and the first is on line %d. " \
        "A name appears in only one task entry, so merge them into one",
      defaults_arguments: "a \"defaults\" node takes properties and children and no arguments, as in defaults cpus=4",
      task_arguments: "a task entry is task NAME or task NAME COMMAND, such as task test or task docs \"make docs\", " \
        "and this one has %d arguments",
    }.freeze
    private_constant(:MESSAGES)

    def initialize(path:)
      @path = path
    end

    def checking(node)
      yield
    rescue Error => e
      # The block builds domain values and nothing else, so what it raises is what the domain refuses.
      refuse(node, e.message)
    end

    def unknown_node(node)
      say(node, :unknown_node, node.name)
    end

    def repeated_defaults(node, first)
      say(node, :repeated_defaults, first.line)
    end

    def repeated_task(node, first)
      say(node, :repeated_task, node.arguments.first, first.line)
    end

    def defaults_arguments(node)
      say(node, :defaults_arguments)
    end

    def task_arguments(node, count)
      say(node, :task_arguments, count)
    end

    private def say(node, key, *values)
      refuse(node, format(messages[key], *values))
    end

    private def messages
      MESSAGES
    end

    private def refuse(node, reason)
      raise(ProjectFileError.new(path: @path, line: node.line, reason:))
    end
  end
end

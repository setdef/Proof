# frozen_string_literal: true

module Proof
  class TaskReader
    BLANK = -> (value) { value.is_a?(String) && value.match?(/\A[[:space:]]*\z/) }
    private_constant(:BLANK)

    def initialize(refusal:, settings:)
      @refusal = refusal
      @settings = settings
    end

    def read_all(nodes)
      entries = nodes.map { |node| read(node) }
      refuse_repeats_among(nodes)
      entries
    end

    def read(node)
      name, command = words_of(node)
      settings = @settings.read(node)
      # The domain refuses a name or a command that isn't text, with its own message, so the entry is built from
      # what the file holds, and Steep is told that this one call may pass what the domain's signature refuses.
      # steep:ignore:start
      @refusal.checking(node) { TaskEntry.new(name:, command:, settings:) }
      # steep:ignore:end
    end

    private def refuse_repeats_among(nodes)
      named = nodes.group_by { |node| node.arguments.first }
      named.each_value { |same| refuse_repeat(same) }
    end

    private def refuse_repeat(same)
      first, second = same
      @refusal.repeated_task(second, first) if first && second
    end

    private def words_of(node)
      refuse_count(node)
      name, command = node.arguments
      refuse_blank(node, name, command)
      [name, command]
    end

    private def refuse_count(node)
      count = node.arguments.size
      @refusal.task_arguments(node, count) unless (1..2).cover?(count)
    end

    private def refuse_blank(node, name, command)
      @refusal.blank_name(node, name) if BLANK.call(name)
      @refusal.blank_command(node, command) if BLANK.call(command)
    end
  end
end

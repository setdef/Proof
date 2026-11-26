# frozen_string_literal: true

require_relative("task_settings")

module Proof
  # steep:ignore:start
  class TaskEntry < Data.define(:name, :command, :settings)
    # steep:ignore:end
    def initialize(name:, command: nil, settings: TaskSettings.none)
      raise(InvalidTaskEntryError, format("a task entry has a name that is text, not %p", name)) unless
        name.is_a?(String)
      raise(InvalidTaskEntryError, format("a task entry's command is text, not %p", command)) unless
        [NilClass, String].any? { |kind| command.is_a?(kind) }
      raise(InvalidTaskEntryError, format("a task entry's settings are task settings, not %p", settings)) unless
        settings.is_a?(TaskSettings)

      super
    end
  end
end

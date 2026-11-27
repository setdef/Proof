# frozen_string_literal: true

require_relative("name")
require_relative("task_settings")

module Proof
  class TaskEntry < Data.define(:name, :command, :settings)
    def initialize(name:, command: nil, settings: TaskSettings.none)
      raise(InvalidTaskEntryError, format(Name.message("a task's name", "test"), name)) unless Name.valid?(name)
      raise(InvalidTaskEntryError, format("a task entry's command is text, not %p", command)) unless
        [NilClass, String].any? { |kind| command.is_a?(kind) }
      raise(InvalidTaskEntryError, format("a task entry's settings are task settings, not %p", settings)) unless
        settings.is_a?(TaskSettings)

      super
    end

    # @dynamic name, command, settings
  end
end

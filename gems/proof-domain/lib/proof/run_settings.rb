# frozen_string_literal: true

require_relative("task_commands")
require_relative("task_settings")

module Proof
  # steep:ignore:start
  class RunSettings < Data.define(:settings, :commands)
    # steep:ignore:end
    def initialize(settings:, commands:)
      raise(InvalidRunSettingsError, format("a run has task settings, not %p", settings)) unless
        settings.is_a?(TaskSettings)

      missing = TaskSettings.members - settings.to_h.compact.keys
      raise(InvalidRunSettingsError, "a run has every setting, and #{missing.first} is missing") unless missing.empty?
      raise(InvalidRunSettingsError, format("a run has a command or none for each task name, not %p", commands)) unless
        TaskCommands.valid?(commands)

      super(settings:, commands: commands.dup.freeze)
    end
  end
end

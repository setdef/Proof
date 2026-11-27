# frozen_string_literal: true

require_relative("built_in_defaults")
require_relative("listing")
require_relative("project_file")
require_relative("run_settings")

module Proof
  class SettingsResolver < Data.define(:project_file, :flags)
    MESSAGE = "a run reads a project file and flags, not %<file>p and %<flags>p"
    private_constant(:MESSAGE)

    def initialize(project_file:, flags:)
      raise(InvalidRunSettingsError, format(MESSAGE, file: project_file, flags:)) unless
        project_file.is_a?(ProjectFile) && flags.is_a?(TaskSettings)

      super
    end

    def resolve(task_names)
      names = task_names_in(task_names)
      RunSettings.new(settings: together(names), commands: project_file.commands_of(names))
    end

    private def task_names_in(task_names)
      names = Listing.set(task_names, String, 1)
      raise(InvalidRunSettingsError, format("a run has one or more task names, not %p", task_names)) unless names

      # Listing.set has found each name to be a String, which Steep can't know.
      names.to_a #: Array[String]
    end

    private def settings_for(name)
      # The first source that has a single value wins, and the sources that give a list add.
      [flags, project_file.entry_for(name).settings, project_file.defaults, BuiltInDefaults::SETTINGS].reduce(:over)
    end

    private def together(names)
      # The settings of a run of several tasks, which suit all of them.
      settings = names.map { |name| settings_for(name) }
      refuse_unshared(names.zip(settings.map(&:os)).to_h)
      settings.reduce(:alongside)
    end

    private def refuse_unshared(systems)
      raise(NoSharedOSError.new(operating_systems: systems)) if systems.values.reduce(:&).empty?
    end

    # @dynamic project_file, flags
  end
end

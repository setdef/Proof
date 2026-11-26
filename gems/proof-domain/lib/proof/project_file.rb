# frozen_string_literal: true

require_relative("task_entry")

module Proof
  # steep:ignore:start
  class ProjectFile < Data.define(:defaults, :entries)
    # steep:ignore:end
    REPEATED_MESSAGE = "two task entries are named %p. A name appears in only one task entry, so merge them into one."
    private_constant(:REPEATED_MESSAGE)

    def self.none
      new
    end

    def initialize(defaults: TaskSettings.none, entries: [])
      raise(InvalidProjectFileError, format("a project file's defaults are task settings, not %p", defaults)) unless
        defaults.is_a?(TaskSettings)
      raise(InvalidProjectFileError, format("a project file's entries are a list of task entries, not %p", entries)) \
        unless entries.is_a?(Array) && entries.all?(TaskEntry)

      entries.map(&:name).tally.each do |name, times|
        raise(InvalidProjectFileError, format(REPEATED_MESSAGE, name)) if times > 1
      end

      super(defaults:, entries: entries.dup.freeze)
    end

    def entry_for(name)
      entries.find { |entry| entry.name == name } || TaskEntry.new(name:)
    end

    def commands_of(names)
      names.to_h { |name| [name, entry_for(name).command] }
    end
  end
end

# frozen_string_literal: true

require_relative("host_settings")

module Proof
  class ResolvedHost < Data.define(:name, :runners, :budget, :keep_free, :share, :active_for, :withheld)
    MISSING = "a resolved host has every setting, and %s is missing"
    private_constant(:MISSING)

    def initialize(name:, runners:, **settings)
      # The settings arrive as one hash, since seven keywords make a parameter list longer than RuboCop accepts.
      missing = HostSettings.members - settings.compact.keys
      raise(InvalidResolvedHostError, format(MISSING, missing.first)) unless missing.empty?

      entry = entry_of(name, runners, settings)
      super(name: entry.name, runners: entry.runners, **settings)
    end

    private def entry_of(name, runners, settings)
      # The entry holds the rules for a name, runners, and settings of each kind, so a resolved host is checked by
      # building the entry it came from.
      HostEntry.new(name:, runners:, settings: HostSettings.new(**settings))
    rescue Error => e
      raise(InvalidResolvedHostError, e.message)
    end

    # @dynamic name, runners, budget, keep_free, share, active_for, withheld
  end
end

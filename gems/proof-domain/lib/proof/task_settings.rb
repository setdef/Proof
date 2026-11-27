# frozen_string_literal: true

require_relative("setting_check")

module Proof
  class TaskSettings < Data.define(:os, :labels, :cpus, :megabytes, :time_limit, :artifacts, :caches)
    REPLACING = %i[os cpus megabytes time_limit].freeze
    ADDING = %i[labels artifacts caches].freeze
    LARGEST = %i[cpus megabytes time_limit].freeze
    private_constant(:REPLACING, :ADDING, :LARGEST)

    def self.none
      new
    end

    def initialize(**given)
      # The keywords arrive as one hash, since seven keywords make a parameter list longer than RuboCop accepts.
      super(**SettingCheck.all(given, members))
    end

    def over(lower)
      TaskSettings.new(**REPLACING.to_h { |member| [member, pair(member, lower).compact.first] }, **added(lower))
    end

    def alongside(other)
      largest = LARGEST.to_h { |member| [member, pair(member, other).compact.max] }
      TaskSettings.new(os: pair(:os, other).compact.reduce(:&), **largest, **added(other))
    end

    private def pair(member, other)
      [public_send(member), other.public_send(member)]
    end

    private def added(other)
      ADDING.to_h { |member| [member, pair(member, other).compact.reduce(:|)] }
    end

    # @dynamic os, labels, cpus, megabytes, time_limit, artifacts, caches
  end
end

# frozen_string_literal: true

# The table of kinds below names these classes while the file loads, so the file loads them first.
require_relative("label_set")
require_relative("listing")
require_relative("os")
require_relative("path_pattern")
require_relative("resources")
require_relative("time_limit")

module Proof
  module SettingCheck
    MESSAGES = {
      os: "os is one or more operating systems",
      labels: "labels are a set of labels",
      time_limit: "a time limit is a duration",
      artifacts: "artifacts are path patterns",
      caches: "caches are path patterns",
    }.freeze
    KINDS = { os: OS, labels: LabelSet, time_limit: TimeLimit, artifacts: PathPattern, caches: PathPattern }.freeze
    private_constant(:MESSAGES, :KINDS)

    def self.all(given, names)
      unknown = given.keys - names
      raise(ArgumentError, "unknown keyword: #{unknown.first.inspect}") unless unknown.empty?

      # A setting given as nil is a setting the source doesn't give.
      names.product([nil]).to_h.merge(given.compact.to_h { |name, value| [name, checked(name, value)] })
    end

    def self.checked(name, value)
      case name
      when :cpus then cpus(value)
      when :megabytes then megabytes(value)
      when :os, :artifacts, :caches then listed(name, value)
      else single(name, value)
      end
    end

    def self.cpus(value)
      # Resources holds the rules for CPUs and memory, so a source's CPUs and megabytes are checked by building them,
      # and Steep is told that the value may be what the signatures refuse.
      count = value #: Integer
      Resources.request(cpus: count, memory: "0MB").cpus
    end
    private_class_method(:cpus)

    def self.megabytes(value)
      count = value #: Integer
      Resources.new(cpus: 1, megabytes: count).megabytes
    end
    private_class_method(:megabytes)

    def self.single(name, value)
      return value if value.is_a?(KINDS[name])

      raise(InvalidTaskSettingsError, format("#{MESSAGES[name]}, not %p", value))
    end
    private_class_method(:single)

    def self.listed(name, values)
      # An os node lists one or more operating systems, and the other lists may be empty.
      found = Listing.set(values, KINDS[name], (name == :os) ? 1 : 0)
      return found if found

      raise(InvalidTaskSettingsError, format("#{MESSAGES[name]}, not %p", values))
    end
    private_class_method(:listed)
  end
  private_constant(:SettingCheck)
end

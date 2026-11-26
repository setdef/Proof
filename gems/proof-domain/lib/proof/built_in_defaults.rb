# frozen_string_literal: true

# The settings below are built while the file loads, so the file loads what builds them first.
require_relative("errors")
require_relative("label_set")
require_relative("os")
require_relative("task_settings")
require_relative("time_limit")

module Proof
  module BuiltInDefaults
    SETTINGS = TaskSettings.new(
      os: OS.all,
      labels: LabelSet.of,
      cpus: 2,
      megabytes: 4096,
      time_limit: TimeLimit.read("60m"),
      artifacts: [],
      caches: []
    )
    public_constant(:SETTINGS)
  end
end

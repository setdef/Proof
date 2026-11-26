# frozen_string_literal: true

# The settings below are built while the file loads, so the file loads what builds them first.
require_relative("duration")
require_relative("host_settings")
require_relative("label_set")
require_relative("resources")
require_relative("size")

module Proof
  module BuiltInHostDefaults
    SETTINGS = HostSettings.new(
      keep_free: Size.new(megabytes: 25 * 1024),
      share: Resources.new(cpus: 2, megabytes: 4096),
      active_for: Duration.new(seconds: 300),
      withheld: LabelSet.of
    )
    public_constant(:SETTINGS)
  end
end

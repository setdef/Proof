# frozen_string_literal: true

require_relative("duration")
require_relative("label_set")
require_relative("resources")
require_relative("size")

module Proof
  # steep:ignore:start
  class HostSettings < Data.define(:budget, :keep_free, :share, :active_for, :withheld)
    # steep:ignore:end
    MESSAGES = {
      budget: "a host's budget is a size",
      keep_free: "a host's keep-free space is a size",
      share: "a host's share is resources",
      active_for: "a host's active-for time is a duration",
      withheld: "a host's withheld labels are a set of labels",
    }.freeze
    KINDS = { budget: Size, keep_free: Size, share: Resources, active_for: Duration, withheld: LabelSet }.freeze
    REPLACING = %i[budget keep_free share active_for].freeze
    private_constant(:MESSAGES, :KINDS, :REPLACING)

    def initialize(budget: nil, keep_free: nil, share: nil, active_for: nil, withheld: nil)
      # A setting given as nil is a setting the source doesn't give.
      given = { budget:, keep_free:, share:, active_for:, withheld: }.compact
      member, value = given.find { |name, setting| !setting.is_a?(KINDS[name]) }
      raise(InvalidHostSettingsError, format("#{MESSAGES[member]}, not %p", value)) if member

      super
    end

    def over(lower)
      # The first source that has a single value wins, and the sources that give labels add.
      HostSettings.new(
        **REPLACING.to_h { |member| [member, public_send(member) || lower.public_send(member)] },
        withheld: [withheld, lower.withheld].compact.reduce(:|)
      )
    end
  end
end

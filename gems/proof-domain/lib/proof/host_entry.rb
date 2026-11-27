# frozen_string_literal: true

require_relative("built_in_host_defaults")
require_relative("host_settings")
require_relative("member_check")
require_relative("name")
require_relative("resolved_host")

module Proof
  # steep:ignore:start
  class HostEntry < Data.define(:name, :runners, :settings)
    # steep:ignore:end
    RULES = MemberCheck.rules(
      name: [Name.message("a host's name", "nuc"), MemberCheck.method(:named?)],
      runners: [
        "a host entry's runners are one or more runner names that differ without regard to case, " \
          "each #{Name::TEXT}, such as [\"nuc-linux\"], not %p",
        MemberCheck.method(:distinct_names?),
      ],
      settings: ["a host entry's settings are host settings, not %p", HostSettings.method(:===)]
    )
    NO_BUDGET = "the host %p has no budget. Give its entry a budget, or give defaults one"
    private_constant(:RULES, :NO_BUDGET)

    def initialize(name:, runners:, settings: HostSettings.new)
      problem = MemberCheck.problem(RULES, { name:, runners:, settings: })
      raise(InvalidHostEntryError, problem) if problem

      super(name: -name, runners: runners.dup.freeze, settings:)
    end

    def resolved(defaults)
      # The entry's own value wins, then the defaults', then Proof's built-in value.
      settled = settings.over(defaults).over(BuiltInHostDefaults::SETTINGS)
      raise(InvalidHostEntryError, format(NO_BUDGET, name)) unless settled.budget

      # The built-in defaults give every setting, so settled has them all, which Steep can't know.
      # steep:ignore:start
      ResolvedHost.new(name:, runners:, **settled.to_h)
      # steep:ignore:end
    end
  end
end

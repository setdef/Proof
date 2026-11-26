# frozen_string_literal: true

module Proof
  class PoolFileSettings
    MEMBERS = {
      budget: :budget, "keep-free": :keep_free, share: :share, "active-for": :active_for, withhold: :withheld
    }.freeze
    BUILDERS = {
      budget: -> (child) { Size.read(child.arguments.first, name: "budget") },
      "keep-free": -> (child) { Size.read(child.arguments.first, name: "keep-free") },
      share: lambda do |child|
        memory = Size.read(child.properties["memory"], name: "share memory")
        Resources.new(cpus: child.properties["cpus"], megabytes: memory.megabytes)
      end,
      "active-for": -> (child) { Duration.read(child.arguments.first, units: %i[s m h], name: "active-for") },
      withhold: -> (child) { LabelSet.new(labels: child.arguments.map { |name| Label.new(name:) }) },
    }.freeze
    private_constant(:MEMBERS, :BUILDERS)

    def initialize(node:, refusal:)
      @node = node
      @refusal = refusal
    end

    def settings
      pairs = @node.children.filter_map { |child| pair(child) }
      HostSettings.new(**pairs.to_h)
    end

    def entry
      # The domain refuses a name or a runner that isn't text, with its own message, so the entry is built from what the
      # file holds, and Steep is told that this one call may pass what the domain's signature refuses.
      # steep:ignore:start
      HostEntry.new(name: @node.arguments.first, runners: @node.arguments_named("runner"), settings:)
      # steep:ignore:end
    end

    private def pair(child)
      key = child.name.to_sym
      [MEMBERS[key], @refusal.checking(child) { BUILDERS[key].call(child) }] if MEMBERS.key?(key)
    end
  end
end

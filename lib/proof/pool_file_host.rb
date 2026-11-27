# frozen_string_literal: true

module Proof
  class PoolFileHost
    MEMBERS = {
      budget: :budget, "keep-free": :keep_free, share: :share, "active-for": :active_for, withhold: :withheld
    }.freeze
    BUILDERS = {
      budget: -> (child) { Size.read(child.arguments.first, name: "budget") },
      "keep-free": -> (child) { Size.read(child.arguments.first, name: "keep-free") },
      share: -> (child) { Resources.share(cpus: child.properties["cpus"], memory: child.properties["memory"]) },
      "active-for": -> (child) { Duration.read(child.arguments.first, units: %i[s m h], name: "active-for") },
      withhold: -> (child) { LabelSet.of(*child.arguments) },
    }.freeze
    private_constant(:MEMBERS, :BUILDERS)

    def initialize(node:, refusal:, names:)
      @node = node
      @refusal = refusal
      @names = names
    end

    def settings
      pairs = @node.children.filter_map { |child| pair(child) }
      HostSettings.new(**pairs.to_h)
    end

    def entry
      # The domain refuses a name or a runner that isn't text, with its own message, so the entry is built from what the
      # file holds.
      HostEntry.new(name: @node.arguments.first, runners: @names.read(@node, :runner), settings:)
    end

    private def pair(child)
      key = child.name.to_sym
      [MEMBERS[key], @refusal.checking(child) { BUILDERS[key].call(child) }] if MEMBERS.key?(key)
    end
  end
end

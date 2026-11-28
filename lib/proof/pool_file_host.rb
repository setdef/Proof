# frozen_string_literal: true

module Proof
  class PoolFileHost
    # @type var table: Hash[Symbol, KdlMembers::entry]
    table = {
      budget: [:budget, -> (child) { Size.read(child.arguments.first, name: "budget") }],
      "keep-free": [:keep_free, -> (child) { Size.read(child.arguments.first, name: "keep-free") }],
      share: [
        :share, -> (child) { Resources.share(cpus: child.properties["cpus"], memory: child.properties["memory"]) }
      ],
      "active-for": [
        :active_for, -> (child) { Duration.read(child.arguments.first, units: %i[s m h], name: "active-for") }
      ],
      withhold: [:withheld, -> (child) { LabelSet.of(*child.arguments) }],
    }
    TABLE = table.freeze
    private_constant(:TABLE)

    def initialize(node:, refusal:, names:)
      @node = node
      @members = KdlMembers.new(TABLE, refusal:)
      @names = names
    end

    def settings
      HostSettings.new(**@members.of_children(@node))
    end

    def entry
      # The domain refuses a name or a runner that isn't text, with its own message, so the entry is built from what the
      # file holds.
      HostEntry.new(name: @node.arguments.first, runners: @names.read(@node, :runner), settings:)
    end
  end
end

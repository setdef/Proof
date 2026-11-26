# frozen_string_literal: true

module Proof
  class PoolFileRepository
    def initialize(node:, refusal:)
      @node = node
      @refusal = refusal
    end

    def entry
      # The domain refuses a name, a URL, a path, or a branch that isn't text, with its own message, so the entry is
      # built from what the file holds, and Steep is told that this one call may pass what the domain's signature
      # refuses.
      # steep:ignore:start
      RepositoryEntry.new(
        name: @node.arguments.first,
        url: @node.properties["url"],
        branches: @node.arguments_named("branch"),
        tasks: @node.arguments_named("task"),
        credentials_file: @node.arguments_named("credentials-file").first,
        **poll
      )
      # steep:ignore:end
    end

    private def poll
      durations = @node.named("poll").map do |child|
        @refusal.checking(child) { Duration.read(child.arguments.first, units: %i[s m h], name: "poll") }
      end
      { poll: durations.first }.compact
    end
  end
end

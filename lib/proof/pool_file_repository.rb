# frozen_string_literal: true

module Proof
  class PoolFileRepository
    def initialize(node:, refusal:, names:)
      @node = node
      @refusal = refusal
      @names = names
    end

    def entry
      credentials_file, branches, tasks = %i[credentials-file branch task].map { |kind| @names.read(@node, kind) }
      # The domain refuses a name, a URL, a path, or a branch that isn't text, with its own message, so the entry is
      # built from what the file holds, and Steep is told that this one call may pass what the domain's signature
      # refuses.
      # steep:ignore:start
      RepositoryEntry.new(
        name: @node.arguments.first,
        url: @node.properties["url"],
        branches:,
        tasks:,
        credentials_file: credentials_file.first,
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

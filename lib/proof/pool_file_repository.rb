# frozen_string_literal: true

module Proof
  class PoolFileRepository
    def initialize(node:, refusal:, names:)
      @node = node
      @refusal = refusal
      @names = names
    end

    def entry
      # The domain refuses a name, a URL, a path, or a branch that isn't text, with its own message, so the entry is
      # built from what the file holds.
      RepositoryEntry.new(
        name: @node.arguments.first,
        url: @node.properties["url"],
        branches: names(:branch),
        tasks: names(:task),
        credentials_file: names(:"credentials-file").first,
        **poll
      )
    end

    private def names(kind)
      @names.read(@node, kind)
    end

    private def poll
      durations = @node.named("poll").map do |child|
        @refusal.checking(child) { Duration.read(child.arguments.first, units: %i[s m h], name: "poll") }
      end
      { poll: durations.first }.compact
    end
  end
end

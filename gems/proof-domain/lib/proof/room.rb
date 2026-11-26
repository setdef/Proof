# frozen_string_literal: true

require_relative("resources")

module Proof
  module Room
    def self.capacity(runners)
      runners.map(&:capacity).reduce(Resources.none, :most)
    end

    def self.free(from, runs, kept = Resources.none)
      requests = runs.map { |run| run.queued.resources }
      requests.push(kept).reduce(from, :minus)
    end
  end
  private_constant(:Room)
end

# frozen_string_literal: true

# NONE is built while the file loads, so the file loads Resources first.
require_relative("resources")

module Proof
  module Capacity
    NONE = Resources.new(cpus: 0, megabytes: 0)
    public_constant(:NONE)

    def self.free(from, runs, kept = NONE)
      less(less(from, sum(runs)), kept)
    end

    def self.sum(runs)
      requests = runs.map { |run| run.queued.resources }
      Resources.new(cpus: requests.sum(&:cpus), megabytes: requests.sum(&:megabytes))
    end

    def self.less(from, taken)
      Resources.new(cpus: [from.cpus - taken.cpus, 0].max, megabytes: [from.megabytes - taken.megabytes, 0].max)
    end

    def self.least(first, second)
      Resources.new(cpus: [first.cpus, second.cpus].min, megabytes: [first.megabytes, second.megabytes].min)
    end

    def self.most(all)
      Resources.new(cpus: all.map(&:cpus).max || 0, megabytes: all.map(&:megabytes).max || 0)
    end
  end
  private_constant(:Capacity)
end

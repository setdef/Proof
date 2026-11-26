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
      requests.reduce(NONE) { |acc, elem| combine(acc, elem, &:+) }
    end

    def self.less(from, taken)
      combine(from, taken) { |have, take| [have - take, 0].max }
    end

    def self.least(first, second)
      combine(first, second) { |one, other| [one, other].min }
    end

    def self.most(runners)
      runners.map(&:capacity).reduce(NONE) { |acc, elem| more(acc, elem) }
    end

    def self.more(first, second)
      combine(first, second) { |one, other| [one, other].max }
    end

    def self.combine(first, second)
      Resources.new(cpus: yield(first.cpus, second.cpus), megabytes: yield(first.megabytes, second.megabytes))
    end
  end
  private_constant(:Capacity)
end

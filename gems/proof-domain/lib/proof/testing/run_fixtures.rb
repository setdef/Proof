# frozen_string_literal: true

module Proof
  module Testing
    module RunFixtures
      AT = Time.utc(2026, 11, 25, 3, 36)
      public_constant(:AT)

      def self.id(characters = "m3d8q")
        RunId.new(minute: AT, characters:)
      end

      def self.queued(position = 1)
        Run::Queued.new(
          at: AT,
          position:,
          os: [OS.new(name: :linux)],
          labels: LabelSet.of,
          resources: Resources.new(cpus: 2, megabytes: 4096)
        )
      end

      def self.run(id: "m3d8q", position: 1, later: [])
        Run.new(id: id(id), facts: [queued(position), *later])
      end

      def self.placed(runner: "nuc-linux")
        Run::Placed.new(at: AT, host: "nuc", runner:)
      end

      def self.lost
        [placed, Run::Lost.new(at: AT)]
      end

      def self.storing(runs, *stored)
        stored.each { |run| runs.add(run) }
        runs
      end

      def self.in_each_state(runs)
        storing(
          runs,
          run(id: "k7q2w", position: 5),
          run(id: "zzzzz", position: 2),
          run(id: "p1ace", position: 3, later: [placed]),
          run(id: "10st0", position: 4, later: lost),
          run(id: "d0ne0", position: 1, later: [*lost, Run::ProcessesEnded.new(at: AT)])
        )
      end

      def self.characters(runs)
        runs.map { |run| run.id.characters }
      end

      def self.facts(runs, id = id())
        # Array of nil is empty, so a missing run gives no facts, with no branch for coverage to miss.
        Array(runs.find(id)).flat_map(&:facts)
      end
    end
  end
end

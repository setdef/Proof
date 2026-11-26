# frozen_string_literal: true

require_relative("at_once")
require_relative("run_fixtures")

module Proof
  module Testing
    module RunsDurabilityContract
      def test_runs_contract_two_threads_placing_one_run_place_it_once
        runs = RunFixtures.storing(build_runs, RunFixtures.run)

        assert_equal(%i[placed refused], AtOnce.place(runs, 2).sort)
        assert_equal(2, RunFixtures.facts(runs).size)
      end

      def test_runs_contract_two_threads_adding_runs_at_one_position_add_one
        runs = build_runs

        assert_equal(%i[added refused], AtOnce.add(runs, %w[k7q2w m3d8q]).sort)
        assert_equal(2, runs.next_position)
      end

      def test_runs_contract_reopening_after_a_restart_keeps_every_run
        runs = RunFixtures.in_each_state(build_runs)
        reopened = reopen_runs(runs)

        assert_equal(runs.holding_resources.map(&:facts), reopened.holding_resources.map(&:facts))
        assert_equal(runs.queued, reopened.queued)
        assert_equal(6, reopened.next_position)
      end
    end
  end
end

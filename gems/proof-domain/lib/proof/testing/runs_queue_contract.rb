# frozen_string_literal: true

require_relative("run_fixtures")

module Proof
  module Testing
    module RunsQueueContract
      def test_runs_contract_next_position_is_one_for_an_empty_store
        assert_equal(1, build_runs.next_position)
      end

      def test_runs_contract_next_position_follows_the_largest
        assert_equal(5, RunFixtures.storing(build_runs, RunFixtures.run(position: 4)).next_position)
      end

      def test_runs_contract_queued_and_holding_resources_give_their_runs_by_position
        runs = RunFixtures.in_each_state(build_runs)

        assert_equal(%w[zzzzz k7q2w], RunFixtures.characters(runs.queued))
        assert_equal(%w[p1ace 10st0], RunFixtures.characters(runs.holding_resources))
      end
    end
  end
end

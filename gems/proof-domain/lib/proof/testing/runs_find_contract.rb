# frozen_string_literal: true

require_relative("run_fixtures")

module Proof
  module Testing
    module RunsFindContract
      def test_runs_contract_find_gives_nil_for_a_run_it_does_not_have
        assert_nil(build_runs.find(RunFixtures.id))
      end

      def test_runs_contract_find_gives_the_run_with_its_facts
        run = RunFixtures.run(later: [RunFixtures.placed])
        runs = RunFixtures.storing(build_runs, run)

        assert_equal(run.facts, RunFixtures.facts(runs))
      end

      def test_runs_contract_add_refuses_an_id_in_use
        runs = RunFixtures.storing(build_runs, RunFixtures.run)

        assert_raises(RunExistsError) { runs.add(RunFixtures.run(position: 2)) }
      end

      def test_runs_contract_add_refuses_a_queue_position_in_use
        runs = RunFixtures.storing(build_runs, RunFixtures.run)

        assert_raises(QueuePositionTakenError) { runs.add(RunFixtures.run(id: "k7q2w")) }
        assert_empty(RunFixtures.facts(runs, RunFixtures.id("k7q2w")))
      end
    end
  end
end

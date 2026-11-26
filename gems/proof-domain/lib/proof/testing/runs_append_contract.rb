# frozen_string_literal: true

require_relative("run_fixtures")

module Proof
  module Testing
    module RunsAppendContract
      def test_runs_contract_append_adds_a_fact_at_the_version_read
        runs = RunFixtures.storing(build_runs, RunFixtures.run)
        added = runs.append(RunFixtures.id, RunFixtures.placed, version: 1)

        assert_equal(2, added.version)
        assert_equal(added.facts, RunFixtures.facts(runs))
      end

      def test_runs_contract_append_refuses_a_version_the_run_no_longer_has
        runs = RunFixtures.storing(build_runs, RunFixtures.run(later: [Run::CancelAsked.new(at: RunFixtures::AT)]))

        assert_raises(RunChangedError) { runs.append(RunFixtures.id, RunFixtures.placed, version: 1) }
        assert_equal(2, RunFixtures.facts(runs).size)
      end

      def test_runs_contract_append_refuses_a_run_it_does_not_have
        assert_raises(UnknownRunError) { build_runs.append(RunFixtures.id, RunFixtures.placed, version: 1) }
      end
    end
  end
end

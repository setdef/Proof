# frozen_string_literal: true

require_relative("run_fixtures")

module Proof
  module Testing
    module RunsRefusalContract
      def test_runs_contract_append_refuses_a_second_placement_at_the_current_version
        runs = RunFixtures.storing(build_runs, RunFixtures.run(later: [RunFixtures.placed]))
        second = RunFixtures.placed(runner: "pc-wsl")

        assert_raises(RunAlreadyPlacedError) { runs.append(RunFixtures.id, second, version: 2) }
      end

      def test_runs_contract_append_refuses_a_second_placement_at_an_older_version
        runs = RunFixtures.storing(build_runs, RunFixtures.run)
        id = RunFixtures.id
        runs.append(id, RunFixtures.placed, version: 1)

        assert_raises(RunAlreadyPlacedError) { runs.append(id, RunFixtures.placed(runner: "pc-wsl"), version: 1) }
      end

      def test_runs_contract_append_refuses_a_fact_that_breaks_a_rule
        runs = RunFixtures.storing(build_runs, RunFixtures.run)

        assert_raises(InvalidRunError) { runs.append(RunFixtures.id, Run::Lost.new(at: RunFixtures::AT), version: 1) }
        assert_equal(1, RunFixtures.facts(runs).size)
      end
    end
  end
end

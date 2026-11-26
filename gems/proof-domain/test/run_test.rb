# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("test_helper")

# Checks a run as an entity: what it is built from, what it says about itself,
# and how a fact is added to it.
class RunTest < Minitest::Test
  include RunFacts

  # A run's ID is a Proof::RunId.
  def test_an_id_that_is_not_a_run_id_is_refused
    error = assert_raises(Proof::InvalidRunError) { Proof::Run.new(id: "20261125-0336-m3d8q", facts: [queued]) }

    assert_equal(%(a run's ID is a Proof::RunId, not "20261125-0336-m3d8q"), error.message)
  end

  # A run's facts are an Array of one or more facts.
  def test_facts_that_are_not_a_list_of_facts_are_refused
    [[], nil, [queued, "placed"], Set[queued]].each do |facts|
      error = assert_raises(Proof::InvalidRunError) { Proof::Run.new(id: ID, facts:) }

      assert_match(/\Aa run's facts are a list of one or more facts, not /, error.message)
    end
  end

  # Architecture, "A run as a consistency boundary": a run is "an append-only
  # list of facts", so a run keeps its own copy, frozen.
  def test_a_run_keeps_a_frozen_copy_of_its_facts
    given = [queued]
    built = run_of(*given)
    given << placed

    assert_equal([queued], built.facts)
    assert_predicate(built.facts, :frozen?)
  end

  # A run is an entity, so it is the same run however many facts it has.
  def test_two_runs_with_the_same_id_are_the_same_run
    assert_equal(run_of(queued), run_of(queued, placed))
    assert(run_of(queued).eql?(run_of(queued, placed)))
  end

  # Two runs with the same ID work as one key.
  def test_two_runs_with_the_same_id_hash_alike
    assert_equal(run_of(queued).hash, run_of(queued, placed).hash)
    assert_equal(1, Set[run_of(queued), run_of(queued, placed)].size)
  end

  # Two runs with different IDs are different runs, even with the same facts.
  def test_two_runs_with_different_ids_differ
    other = Proof::RunId.parse("20261125-0336-k7q2w")

    refute_equal(run_of(queued), run_of(queued, id: other))
    refute_equal(run_of(queued).hash, run_of(queued, id: other).hash)
    refute_equal(run_of(queued), ID)
  end

  # Adding a fact gives a new run and leaves the old one as it was.
  def test_a_fact_is_added_to_a_new_run
    before = run_of(queued)
    after = before.with_fact(placed)

    assert_equal([queued, placed], after.facts)
    assert_equal([queued], before.facts)
    assert_equal(ID, after.id)
  end

  # A fact that breaks a rule can't be added.
  def test_a_fact_that_breaks_a_rule_is_not_added
    assert_raises(Proof::InvalidRunError) { run_of(queued, placed).with_fact(placed) }
  end

  # Server design, "Runs and their records": records are "written so that
  # concurrent writers can't interleave or lose them", and a store compares
  # the number of facts to tell.
  def test_the_version_is_the_number_of_facts
    assert_equal(1, run_of(queued).version)
    assert_equal(3, run_of(queued, placed, started).version)
  end

  # The fact that a run was queued says where it may go and what it requests.
  def test_a_run_gives_the_fact_that_it_was_queued
    assert_equal(queued(position: 4), run_of(queued(position: 4), placed).queued)
  end

  # A queued run has no placement, and a placed run has its runner.
  def test_a_run_gives_its_placement
    assert_nil(run_of(queued).placement)
    assert_equal(placed(runner: "pc-wsl"), run_of(queued, cancel, placed(runner: "pc-wsl")).placement)
  end

  # A run that hasn't ended has no ending, and an ended run has its final state.
  def test_a_run_gives_its_ending
    assert_nil(run_of(queued, placed).ending)
    assert_equal(ended(:lost), run_of(queued, placed, ended(:lost), processes_ended).ending)
  end

  # Glossary, "run states": `queued`, then `running` "from its placement until
  # it ends", then its final state.
  def test_a_runs_state_follows_from_its_facts
    assert_equal(:queued, run_of(queued, cancel).state)
    assert_equal(:running, run_of(*ran).state)
    assert_equal(:succeeded, run_of(*ran, kept, ended(:succeeded)).state)
  end

  # Glossary, "place": placing a run holds "the CPUs and memory it requests on
  # that runner's host", so a running run holds them and a queued one doesn't.
  def test_a_running_run_holds_its_resources_and_a_queued_one_does_not
    refute_predicate(run_of(queued), :holds_resources?)
    assert_predicate(run_of(queued, placed), :holds_resources?)
    assert_predicate(run_of(*ran), :holds_resources?)
  end

  # A run that ended in any state but `lost` holds nothing, since its runner
  # ended its processes before it reported the end.
  def test_a_run_that_ended_holds_no_resources
    refute_predicate(run_of(*ran, kept, ended(:succeeded)), :holds_resources?)
    [ended(:failed), ended(:timed_out), ended(:out_of_memory)].each do |ending|
      refute_predicate(run_of(*ran(1), ending), :holds_resources?)
    end
  end

  # A canceled run's runner ended it, so it holds nothing.
  def test_a_canceled_run_holds_no_resources
    refute_predicate(run_of(queued, placed, cancel, ended(:canceled)), :holds_resources?)
  end

  # Server design, "Runs and their records": "The host's resources stay held
  # until the runner reports that the run's processes ended".
  def test_a_lost_run_holds_its_resources_until_its_processes_end
    assert_predicate(run_of(queued, placed, ended(:lost)), :holds_resources?)
    refute_predicate(run_of(queued, placed, ended(:lost), processes_ended), :holds_resources?)
  end
end

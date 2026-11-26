# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("support/run_rules")
require_relative("test_helper")

# Checks the order a run's facts come in, which every run keeps when it is
# built, including when it is rebuilt from storage.
class RunOrderTest < Minitest::Test
  include RunFacts
  include RunRules

  # Glossary, "queue position": a run's position is "given by the server when
  # the run is queued", so a run's record starts there.
  def test_a_run_starts_with_the_fact_that_it_was_queued
    assert_equal(:queued, run_of(queued).state)
    assert_breaks(FIRST, placed)
  end

  # A run is queued once, so its arrival order can't change.
  def test_a_second_queued_fact_is_refused
    assert_breaks(FIRST, queued, queued(position: 2))
    assert_breaks(FIRST, queued, placed, queued)
  end

  # Architecture, "Placing a run": "The store itself refuses a second
  # placement fact for a run", and the run refuses one too.
  def test_a_run_is_placed_once
    assert_equal(:running, run_of(queued, placed).state)
    assert_breaks(PLACED_ONCE, queued, placed, placed(runner: "pc-wsl"))
  end

  # Glossary, "run states": `running` is "from its placement until it ends",
  # and Runner design, "Time limits", starts a run's time limit "when its
  # command starts", which a runner does only for a run it has.
  def test_a_command_starts_only_after_the_run_is_placed
    assert_breaks(STARTS, queued, started)
  end

  # Server design, "Runs and their records": "Proof never runs a run's
  # command again by itself".
  def test_a_command_starts_once
    assert_breaks(STARTS, queued, placed, started, started)
  end

  # Runner design, "A run's end": "The status of a run must come from the
  # command", so it ends only after it started, and once.
  def test_a_command_ends_once_after_it_starts
    assert_breaks(ENDS, queued, placed, exited)
    assert_breaks(ENDS, queued, placed, started, exited, signaled)
  end

  # Glossary, "end marker": the runner sends it "after a run's last byte of
  # output", so the whole output arrives after the command ends, and once.
  def test_the_whole_output_arrives_once_after_the_command_ends
    assert_breaks(OUTPUT, queued, placed, started, output)
    assert_breaks(OUTPUT, *ran, output)
  end

  # Server design, "Artifacts": "The run's artifacts are sealed by a sorted
  # manifest once all have arrived; nothing is added after that."
  def test_artifacts_are_kept_once_after_the_command_ends
    assert_kind_of(Proof::Run::ArtifactsKept, run_of(*ran, kept).facts.last)
    assert_breaks(AFTER_COMMAND, queued, placed, started, kept)
    assert_breaks(ARTIFACTS_ONCE, *ran, kept, kept)
  end

  # Glossary, "run states": `failed` covers "Proof couldn't keep the run's
  # artifacts", so the artifacts are either kept or not, never both.
  def test_artifacts_are_kept_or_not_kept_never_both
    assert_breaks(ARTIFACTS_ONCE, *ran, kept, not_kept)
    assert_breaks(ARTIFACTS_ONCE, *ran, not_kept, kept)
    assert_breaks(ARTIFACTS_ONCE, *ran, not_kept, not_kept(:over_limit))
  end

  # Artifacts that matched no file, ran over the limit, or had a refused path
  # are known only after the command ends.
  def test_artifacts_go_unkept_for_their_files_only_after_the_command_ends
    %i[no_match over_limit refused_path].each do |reason|
      assert_equal(reason, run_of(*ran(1), not_kept(reason)).facts.last.reason)
      assert_breaks(AFTER_COMMAND, queued, placed, started, not_kept(reason))
    end
  end

  # Server design, "Artifacts": "When a run starts, check that the server's
  # free space is at least `limits artifacts`" and "the run ends `failed`
  # before its command starts".
  def test_artifacts_go_unkept_for_space_after_placement_and_before_the_command
    assert_equal(:running, run_of(queued, placed, not_kept(:short_of_space)).state)
    assert_breaks(SHORT_OF_SPACE, queued, not_kept(:short_of_space))
    assert_breaks(SHORT_OF_SPACE, queued, placed, started, not_kept(:short_of_space))
  end

  # Server design, "Artifacts": the shortage is checked "When a run starts",
  # so it never comes after the command ended.
  def test_artifacts_never_go_unkept_for_space_after_the_command
    assert_breaks(SHORT_OF_SPACE, *ran, not_kept(:short_of_space))
  end

  # Command design: a harness sends `TERM` "often twice", and Server design,
  # "Runs and their records": "Records are bounded per run", so one ask is
  # kept.
  def test_a_cancel_is_asked_for_once
    assert_predicate(run_of(queued, cancel), :cancel_asked?)
    assert_breaks(CANCEL_ONCE, queued, cancel, cancel)
  end

  # A cancel can be asked for at any time before the run ends.
  def test_a_cancel_may_be_asked_for_while_queued_running_or_sending_output
    [[cancel, placed], [placed, started, cancel], [placed, started, exited, cancel]].each do |facts|
      assert_predicate(run_of(queued, *facts), :cancel_asked?)
    end
  end

  # Glossary, "run states": "The first two can change; the rest are final."
  def test_no_fact_follows_a_final_state
    facts = [queued, placed, started, exited(1), output, ended(:failed)]

    [kept, not_kept, cancel, ended(:lost), placed(runner: "pc-wsl"), exited, output, started].each do |late|
      assert_breaks(AFTER_FINAL, *facts, late)
    end
  end

  # Server design, "Runs and their records": "Final states stay final, so a
  # complete report that arrives after `lost` is refused."
  def test_a_complete_report_after_lost_is_refused
    lost = [queued, placed, started, ended(:lost)]

    assert_breaks(AFTER_FINAL, *lost, exited)
    assert_breaks(AFTER_FINAL, *lost, ended(:succeeded))
  end

  # Server design, "Runs and their records": "The host's resources stay held
  # until the runner reports that the run's processes ended".
  def test_the_processes_of_a_lost_run_end_once
    lost = [queued, placed, ended(:lost)]

    assert_equal(:lost, run_of(*lost, processes_ended).state)
    assert_breaks(AFTER_FINAL, *lost, processes_ended, processes_ended)
  end

  # The report that a run's processes ended releases a lost run's hold on its
  # host, and every other run releases it when it ends, so the report fits
  # only a lost run.
  def test_the_processes_ending_follow_only_lost
    assert_breaks(AFTER_FINAL, *ran(1), ended(:failed), processes_ended)
    assert_breaks(PROCESSES, queued, placed, processes_ended)
  end

  # Architecture, "A run as a consistency boundary": "The run's constructor
  # checks every rule about a run", so a rule broken anywhere in the list is
  # found, not only at its end.
  def test_a_rule_broken_in_the_middle_of_the_list_is_found
    assert_breaks(PLACED_ONCE, queued, placed, placed, started)
  end
end

# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("support/run_rules")
require_relative("test_helper")

# Checks what each final state needs before it, which every run keeps when it
# is built, including when it is rebuilt from storage.
class RunEndTest < Minitest::Test
  include RunFacts
  include RunRules

  # Glossary, "run states": `succeeded` is "The command exited with status 0,
  # its whole output arrived, and Proof kept the run's artifacts."
  def test_a_run_succeeds_with_status_zero_its_whole_output_and_its_artifacts
    assert_equal(:succeeded, run_of(*ran, kept, ended(:succeeded)).state)
  end

  # Runner design, "Output and status": "A run counts as `succeeded` only when
  # the server has the whole output".
  def test_a_run_without_its_whole_output_does_not_succeed
    assert_breaks(SUCCEEDS, queued, placed, started, exited, ended(:succeeded))
  end

  # Runner design, "Output and status": "Output that is cut off makes the run
  # `lost`, whatever the exit status", even when its artifacts were kept.
  def test_a_run_with_kept_artifacts_but_not_its_whole_output_does_not_succeed
    assert_breaks(SUCCEEDS, queued, placed, started, exited, kept, ended(:succeeded))
  end

  # Server design, "Artifacts": "A run whose command exited 0 but whose
  # artifacts couldn't be kept is `failed`, never `succeeded`."
  def test_a_run_whose_artifacts_were_not_kept_does_not_succeed
    assert_breaks(SUCCEEDS, *ran, ended(:succeeded))
    assert_breaks(SUCCEEDS, *ran, not_kept, ended(:succeeded))
  end

  # Glossary, "run states": `succeeded` needs "status 0".
  def test_a_run_whose_command_exited_with_another_status_does_not_succeed
    assert_breaks(SUCCEEDS, *ran(1), kept, ended(:succeeded))
  end

  # Runner design, "A run's end": a tracer "that exits 0 when the command was
  # killed by a signal turns a failure into a pass", so a signal never passes.
  def test_a_run_whose_command_a_signal_ended_does_not_succeed
    assert_breaks(SUCCEEDS, queued, placed, started, signaled, output, kept, ended(:succeeded))
  end

  # Glossary, "run states": `failed` is "The command exited with another
  # status".
  def test_a_run_whose_command_exited_with_another_status_fails
    assert_equal(:failed, run_of(*ran(2), ended(:failed)).state)
    assert_equal(:failed, run_of(*ran(2), kept, ended(:failed)).state)
  end

  # A command a signal ended has no exit status of 0, so its run fails.
  def test_a_run_whose_command_a_signal_ended_fails
    assert_equal(:failed, run_of(queued, placed, started, signaled, output, ended(:failed)).state)
  end

  # Glossary, "run states": `failed` covers "Proof couldn't keep the run's
  # artifacts".
  def test_a_run_whose_artifacts_were_not_kept_fails_even_with_status_zero
    assert_equal(:failed, run_of(*ran(0), not_kept(:over_limit), ended(:failed)).state)
  end

  # Glossary, "run states": `failed` covers "the server was short of space for
  # them when the run started", before its command.
  def test_a_run_fails_before_its_command_when_the_server_is_short_of_space
    assert_equal(:failed, run_of(queued, placed, not_kept(:short_of_space), ended(:failed)).state)
  end

  # Runner design, "Output and status": "Output that is cut off makes the run
  # `lost`, whatever the exit status", so a run without its whole output
  # doesn't fail.
  def test_a_run_without_its_whole_output_does_not_fail
    assert_breaks(FAILS, queued, placed, started, exited(1), ended(:failed))
    assert_breaks(FAILS, queued, placed, started, exited(0), not_kept, ended(:failed))
  end

  # A run whose command exited with 0 and whose artifacts were kept passed.
  def test_a_run_that_passed_does_not_fail
    assert_breaks(FAILS, *ran(0), kept, ended(:failed))
    assert_breaks(FAILS, *ran(0), ended(:failed))
  end

  # A run that hasn't ended its command has nothing to fail with.
  def test_a_run_whose_command_has_not_ended_does_not_fail
    assert_breaks(FAILS, queued, placed, started, ended(:failed))
    assert_breaks(FAILS, queued, placed, ended(:failed))
  end

  # Runner design, "Time limits": "A run's time limit starts when its command
  # starts."
  def test_a_run_times_out_only_after_its_command_starts
    assert_equal(:timed_out, run_of(queued, placed, started, ended(:timed_out)).state)
    assert_breaks(TIMES_OUT, queued, placed, ended(:timed_out))
  end

  # Runner design, "A run's end": a time limit sends `TERM`, then `KILL`, so
  # the command can end by a signal before the run times out.
  def test_a_run_times_out_after_its_command_ended_by_a_signal
    assert_equal(:timed_out, run_of(queued, placed, started, signaled(15), ended(:timed_out)).state)
  end

  # Glossary, "run states": `out_of_memory` is "The run held more memory than
  # it requested", which only a command that started can do.
  def test_a_run_runs_out_of_memory_only_after_its_command_starts
    assert_equal(:out_of_memory, run_of(queued, placed, started, signaled(9), ended(:out_of_memory)).state)
    assert_breaks(OUT_OF_MEMORY, queued, placed, ended(:out_of_memory))
  end

  # Glossary, "run states": `canceled` is "Someone canceled the run, and the
  # runner ended it."
  def test_a_run_is_canceled_after_a_cancel_and_a_placement_in_either_order
    assert_equal(:canceled, run_of(queued, placed, cancel, ended(:canceled)).state)
    assert_equal(:canceled, run_of(queued, cancel, placed, ended(:canceled)).state)
  end

  # Glossary, "run states": `canceled` needs both someone who canceled and a
  # runner that ended the run.
  def test_a_run_is_not_canceled_without_a_cancel_or_a_placement
    assert_breaks(CANCELED, queued, placed, started, ended(:canceled))
    assert_breaks(CANCELED, queued, cancel, ended(:canceled))
  end

  # Glossary, "run states": `lost` is a run whose runner the server "lost
  # contact with", which only a placed run has.
  def test_a_run_is_lost_only_after_it_is_placed
    assert_equal(:lost, run_of(queued, placed, ended(:lost)).state)
    assert_equal(:lost, run_of(*ran, kept, ended(:lost)).state)
    assert_breaks(LOST, queued, ended(:lost))
  end
end

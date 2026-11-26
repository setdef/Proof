# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("test_helper")

# Checks the facts of a run's placement, output, artifacts, and end.
class RunFactValuesTest < Minitest::Test
  include RunFacts

  # Placing holds a host's resources, so a placement names its host and its
  # runner, as the pool file names them.
  def test_a_placement_keeps_its_host_and_runner_as_frozen_names
    given = +"pc-wsl"
    fact = placed(host: "pc", runner: given)
    given << "x"

    assert_equal("pc", fact.host)
    assert_equal("pc-wsl", fact.runner)
    assert_predicate(fact.runner, :frozen?)
  end

  # Glossary, "place": a placement holds resources "on that runner's host", so
  # a placement is on a host only by one of that host's runners.
  def test_a_placement_is_on_its_host_by_one_of_its_runners
    fact = placed(host: "pc", runner: "pc-wsl")

    assert(fact.on?("pc", %w[pc-windows pc-wsl]))
    refute(fact.on?("pc", %w[pc-windows]))
    refute(fact.on?("nuc", %w[pc-wsl]))
  end

  # A host and a runner each have a name.
  def test_a_placement_with_an_empty_host_is_refused
    error = assert_raises(Proof::InvalidFactError) { placed(host: "") }

    assert_equal(
      %(a placed run's host is text with at least one character that isn't white space, such as nuc, not ""),
      error.message
    )
  end

  # A runner has a name too.
  def test_a_placement_with_a_missing_runner_is_refused
    error = assert_raises(Proof::InvalidFactError) { placed(runner: nil) }

    assert_equal(
      "a placed run's runner is text with at least one character that isn't white space, such as nuc-linux, not nil",
      error.message
    )
  end

  # A name of only white space is no more a name than an empty one.
  def test_a_placement_with_a_host_or_runner_of_only_white_space_is_refused
    [" ", "\t", "\u00A0"].each do |blank|
      assert_raises(Proof::InvalidFactError, blank.inspect) { placed(host: blank) }
      assert_raises(Proof::InvalidFactError, blank.inspect) { placed(runner: blank) }
    end
  end

  # Glossary, "end marker": "the number of bytes it sent", from 0.
  def test_complete_output_keeps_its_length_from_zero
    assert_equal(0, output(0).bytes)
    error = assert_raises(Proof::InvalidFactError) { output(-1) }

    assert_equal("a run's output is a whole number of bytes from 0, not -1", error.message)
  end

  # Command line reference, exit status 78: artifacts fail when a pattern
  # matches no file, they exceed the pool's limit, or the server is short of
  # space; and Server design, "Artifacts", refuses some paths.
  def test_artifacts_go_unkept_for_one_of_four_reasons
    assert_equal(%i[no_match over_limit refused_path short_of_space], Proof::Run::ArtifactsNotKept::REASONS)
    Proof::Run::ArtifactsNotKept::REASONS.each { |reason| assert_equal(reason, not_kept(reason).reason) }
  end

  # Any other reason is refused, with the list.
  def test_another_reason_for_unkept_artifacts_is_refused
    error = assert_raises(Proof::InvalidFactError) { not_kept(:disk_full) }

    assert_equal(
      "artifacts go unkept for one of no_match, over_limit, refused_path, short_of_space, not :disk_full", error.message
    )
  end

  # Server design, "Artifacts": the server is short of space "When a run
  # starts", before its command, and every other reason comes after.
  def test_only_a_shortage_of_space_comes_before_the_command
    assert_predicate(not_kept(:short_of_space), :before_command?)
    %i[no_match over_limit refused_path].each { |reason| refute_predicate(not_kept(reason), :before_command?) }
  end

  # Glossary, "run states": the first two can change, and "the rest are final",
  # and each final state is a fact of its own.
  def test_the_final_states_are_the_six_the_glossary_lists
    assert_equal(%i[succeeded failed timed_out out_of_memory canceled lost], Proof::Run::FINAL_STATES.values)
    assert(Proof::Run::FINAL_STATES.keys.all? { |kind| kind.include?(Proof::Run::Final) })
  end

  # A fact that isn't a final state doesn't end a run.
  def test_only_the_final_states_are_final
    others = [queued, placed, started, exited, output, kept, not_kept, cancel, processes_ended]

    assert(others.none?(Proof::Run::Final))
  end
end

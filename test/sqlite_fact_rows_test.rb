# frozen_string_literal: true

require_relative("test_helper")
require "json"

# Checks that every fact of a run turns into a row and back into an equal fact, so a store that keeps the rows loses
# nothing.
class SqliteFactRowsTest < Minitest::Test
  AT = Time.utc(2026, 11, 25, 3, 36)
  FACTS = [
    Proof::Run::Queued.new(
      at: AT,
      position: 7,
      os: [Proof::OS.new(name: :macos), Proof::OS.new(name: :linux)],
      labels: Proof::LabelSet.of("kvm", "GPU"),
      resources: Proof::Resources.new(cpus: 4, megabytes: 6144)
    ),
    Proof::Run::Placed.new(at: AT, host: "nuc", runner: "nuc-wsl"),
    Proof::Run::CommandStarted.new(at: AT),
    Proof::Run::CommandEnded.new(at: AT, exit_status: 4_294_967_295),
    Proof::Run::CommandEnded.new(at: AT, signal: 9),
    Proof::Run::OutputCompleted.new(at: AT, bytes: 48_213),
    Proof::Run::ArtifactsKept.new(at: AT),
    *Proof::Run::ArtifactsNotKept::REASONS.map { |reason| Proof::Run::ArtifactsNotKept.new(at: AT, reason:) },
    Proof::Run::CancelAsked.new(at: AT),
    Proof::Run::Succeeded.new(at: AT),
    Proof::Run::Failed.new(at: AT),
    Proof::Run::TimedOut.new(at: AT),
    Proof::Run::OutOfMemory.new(at: AT),
    Proof::Run::Canceled.new(at: AT),
    Proof::Run::Lost.new(at: AT),
    Proof::Run::ProcessesEnded.new(at: AT),
  ].freeze
  ID = Proof::RunId.parse("20261125-0336-m3d8q")
  private_constant(:AT, :FACTS, :ID)

  # Architecture, "Storage": a fact is stored as columns or as JSON text, whichever reads back exactly.
  def test_every_fact_comes_back_equal
    FACTS.each do |fact|
      assert_equal(fact, Proof::Sqlite::FactRows.fact(row_of(fact)), fact.inspect)
    end
  end

  # A fact added to the domain without a sample here is a fact the store may lose.
  def test_the_samples_cover_every_fact_the_domain_has
    assert_equal(Proof::Sqlite::FactRows::KINDS.values.to_set, FACTS.to_set(&:class))
  end

  def test_a_row_names_its_run_its_version_and_the_kind_of_fact
    row = Proof::Sqlite::FactRows.row(ID, 3, FACTS[1])

    assert_equal(["20261125-0336-m3d8q", 3, "Placed"], row.values_at(:run_id, :version, :kind))
  end

  def test_a_row_keeps_a_time_in_whole_seconds_and_nanoseconds
    row = row_of(Proof::Run::CancelAsked.new(at: Time.at(1_800_000_000, 123_456_789, :nsec)))

    assert_equal([1_800_000_000, 123_456_789], row.values_at(:at_seconds, :at_nanoseconds))
  end

  def test_a_queued_fact_keeps_its_members_in_their_own_columns
    row = row_of(FACTS.first)

    assert_equal(
      { position: 7, os: '["linux","macos"]', labels: '["GPU","kvm"]', cpus: 4, megabytes: 6144 },
      row.slice(:position, :os, :labels, :cpus, :megabytes)
    )
  end

  def test_a_fact_leaves_the_columns_of_other_facts_empty
    row = row_of(FACTS[1])

    assert_equal([nil] * 6, row.values_at(:position, :os, :labels, :cpus, :exit_status, :reason))
  end

  def test_a_time_before_1970_and_after_2262_comes_back_equal
    [Time.at(-1, 999_999_999, :nsec), Time.utc(9999, 12, 31, 23, 59, 59), Time.utc(1)].each do |at|
      assert_equal(at, Proof::Sqlite::FactRows.fact(row_of(Proof::Run::CancelAsked.new(at:))).at)
    end
  end

  def test_a_time_comes_back_in_utc_to_the_nanosecond
    at = Time.new(2026, 11, 25, 4, 36, 0.123456789r, "+01:00")
    back = Proof::Sqlite::FactRows.fact(row_of(Proof::Run::CancelAsked.new(at:))).at

    assert_predicate(back, :utc?)
    assert_equal(at.getutc, back)
    assert_equal(123_456_789, back.nsec)
  end

  def test_a_row_of_an_unknown_kind_is_not_a_fact
    error = assert_raises(Proof::InvalidFactError) { Proof::Sqlite::FactRows.fact(row_of(FACTS[2]).merge(kind: "Paused")) }

    assert_includes(error.message, "Paused")
  end

  def test_a_row_with_a_missing_member_fails_to_load
    assert_raises(Proof::InvalidFactError) { Proof::Sqlite::FactRows.fact(row_of(FACTS[1]).merge(host: nil)) }
  end

  def test_a_row_with_os_that_is_not_json_fails_to_load
    assert_raises(Proof::InvalidFactError) { Proof::Sqlite::FactRows.fact(row_of(FACTS.first).merge(os: "linux")) }
  end

  def test_a_row_with_no_time_fails_to_load
    assert_raises(Proof::InvalidFactError) { Proof::Sqlite::FactRows.fact(row_of(FACTS[2]).merge(at_seconds: nil)) }
  end

  private def row_of(fact)
    Proof::Sqlite::FactRows.row(ID, 1, fact)
  end
end

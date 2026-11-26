# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Runs the pool file page's own text through the reader, and checks it against what the page says it means: the
# complete example, its prose, and each example.
class PoolFileReaderAcceptanceTest < Minitest::Test
  include PoolFileReaderHelper

  # Pool file reference, "A complete example": the page's own text, read by the reader, is the pool file that the
  # domain's tests build by hand from the same description.
  def test_the_complete_example_reads_as_the_pool_file_built_by_hand
    assert_equal(complete_example, read(page_example("## A complete example")))
  end

  # The prose under "A complete example": "The server listens on port 7443. It keeps each run's record for 90 days, its
  # output for 14 days, and its artifacts for 7 days, and it keeps at most 1 GB of output and 16 GB of artifacts from
  # any one run."
  def test_the_server_the_retention_and_the_limits_are_what_the_prose_says
    file = read(page_example("## A complete example"))
    limits = [file.limits.output, file.limits.artifacts].map(&:megabytes)

    assert_equal([7443, [90, 14, 7], [1024, 16_384]], [file.port.number, days_kept(file.retention), limits])
  end

  # The same prose: "On `nuc`, Proof may use 400 GB of disk. On `pc`, Proof may use 250 GB, ... and never offers the
  # PC's GPU to a task."
  def test_nuc_may_use_400_gb_and_pc_250_gb_and_never_offers_its_gpu
    nuc, pc = read(page_example("## A complete example")).resolved_hosts

    assert_equal(
      [409_600, 256_000, Proof::LabelSet.of("gpu"), Proof::LabelSet.of],
      [nuc.budget.megabytes, pc.budget.megabytes, pc.withheld, nuc.withheld]
    )
  end

  # The same prose: on `pc`, Proof "keeps 16 GB of memory free always and 4 CPUs free while someone is active there". A
  # host that has that share keeps 16 GB when nobody is active, and 4 CPUs and 16 GB while someone is.
  def test_pc_keeps_16_gb_free_always_and_4_cpus_free_while_someone_is_active
    pc = read(page_example("## A complete example")).resolved_hosts.last
    kept = [true, false].map { |active| kept_by(pc, active) }

    assert_equal([{ cpus: 4, megabytes: 16_384 }, { cpus: 0, megabytes: 16_384 }], kept)
  end

  # The same prose: "Every commit pushed to Lota's `trunk` branch gets a run of its `test` and `package` tasks."
  def test_lotas_trunk_branch_runs_its_test_and_package_tasks
    lota = read(page_example("## A complete example")).repositories.first

    assert_equal(["lota", %w[trunk], %w[test package]], [lota.name, lota.branches, lota.tasks])
  end

  # Pool file reference, "Examples", "Keep more of the PC free for someone who games on it": "Runs never use 32 GB of
  # the PC's memory, whether or not anyone is there. While someone uses the PC, runs also leave 8 CPUs free ... When
  # nobody has used it for 5 minutes, runs can use all the CPUs again, and the 32 GB stays free."
  def test_the_pc_example_keeps_32_gb_always_and_8_cpus_while_someone_is_there_for_5_minutes
    example = page_example("### Keep more of the PC free for someone who games on it")
    pc = read("defaults {\n  budget \"100GB\"\n}\n#{example}").resolved_hosts.first
    kept = [true, false].map { |active| kept_by(pc, active) }

    assert_equal([[{ cpus: 8, megabytes: 32_768 }, { cpus: 0, megabytes: 32_768 }], 300], [kept, pc.active_for.seconds])
  end

  # Pool file reference, "Examples", "Keep runs' output longer": "`proof logs` works for a run's output for 30 days. The
  # `runs` and `artifacts` values keep their defaults."
  def test_the_output_example_keeps_output_for_30_days_and_the_rest_by_default
    retention = read(page_example("### Keep runs' output longer")).retention

    assert_equal([90, 30, 7], days_kept(retention))
  end

  # Pool file reference, "Examples", "Run tasks on two branches of a public repository": "Every commit pushed to `trunk`
  # or `release` gets runs of `test`. A public repository needs no `credentials-file`."
  def test_the_two_branch_example_watches_both_branches_and_needs_no_credentials_file
    lota = read(page_example("### Run tasks on two branches of a public repository")).repositories.first

    assert_equal([%w[trunk release], %w[test], nil], [lota.branches, lota.tasks, lota.credentials_file])
  end

  # The days that a retention keeps a run's record, its output, and its artifacts.
  def days_kept(retention)
    [retention.runs, retention.output, retention.artifacts].map { |keeps| keeps.seconds / 86_400 }
  end

  # What a host keeps free for a person, as the server's placement reads it: the memory of its share always, and its
  # CPUs while a person is active.
  def kept_by(resolved, active)
    Proof::Host.new(name: resolved.name, share: resolved.share, person_active: active, runners: []).kept.to_h
  end
end

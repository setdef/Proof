# frozen_string_literal: true

require_relative("project_file_helper")
require_relative("test_helper")

# Checks the settings that suit two tasks at once.
class TaskSettingsAlongsideTest < Minitest::Test
  include ProjectFileHelper

  # Project file reference, "Several tasks on one command line", table: `os` is
  # "The operating systems every one of them works on".
  def test_the_operating_systems_are_those_both_work_on
    settings = given(os: %w[linux macos]).alongside(given(os: %w[macos windows]))

    assert_equal(["macos"], os_names(settings.os))
  end

  # Project file reference, "Several tasks on one command line", table: `label`
  # is "Every label any of them needs".
  def test_the_labels_are_those_of_both
    assert_equal(%w[desktop kvm], label_names(given(label: ["kvm"]).alongside(given(label: ["desktop"])).labels))
  end

  # Project file reference, "Several tasks on one command line", table: `cpus`,
  # `memory`, `timeout` are "The largest of their values", each taken on its own.
  def test_cpus_memory_and_time_limit_are_the_largest_of_each
    settings = given(cpus: 2, memory: "8GB", timeout: "10m").alongside(given(cpus: 8, memory: "1GB", timeout: "2h"))

    assert_equal([8, 8192, 7200], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
  end

  # Project file reference, "Several tasks on one command line", table:
  # `artifact` and `cache` are "All of them".
  def test_artifacts_and_caches_are_all_of_them
    settings = given(artifact: ["a"], cache: ["c1"]).alongside(given(artifact: ["b"], cache: ["c2"]))

    assert_equal([%w[a b], %w[c1 c2]], [path_names(settings.artifacts), path_names(settings.caches)])
  end

  # A setting that only one of two gives is that one's, so settings that give less can stand in.
  def test_a_setting_that_only_one_gives_is_that_ones
    settings = given(cpus: 2).alongside(given(memory: "2GB"))

    assert_equal([2, 2048, nil], [settings.cpus, settings.megabytes, settings.time_limit])
  end

  # Project file reference, "Several tasks on one command line": "When the tasks
  # have no operating system in common, Proof refuses the run", and settings
  # with no operating system can't exist.
  def test_settings_that_share_no_operating_system_are_refused
    assert_raises(Proof::InvalidTaskSettingsError) { given(os: ["linux"]).alongside(given(os: ["macos"])) }
  end

  # Both sets of settings are left as they were.
  def test_the_two_are_left_as_they_were
    first = given(cpus: 2)
    first.alongside(given(cpus: 8))

    assert_equal(given(cpus: 2), first)
  end
end

# frozen_string_literal: true

require_relative("project_file_helper")
require_relative("test_helper")

# Checks which source a run's setting comes from: a flag, the task's entry, the
# `defaults` node, or Proof's built-in defaults.
class SettingsResolverTest < Minitest::Test
  include ProjectFileHelper

  # Project file reference, "How values combine", table: Proof's built-in
  # defaults are "Any operating system, 2 CPUs, 4 GB, 60 minutes".
  def test_the_built_in_defaults_are_any_operating_system_2_cpus_4_gb_and_60_minutes
    settings = resolve(Proof::ProjectFile.none, "test").settings

    assert_equal(%w[linux macos windows], os_names(settings.os))
    assert_equal([2, 4096, 3600], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
  end

  # Project file reference, "How values combine": the built-in defaults hold no
  # label, no artifact, and no cache, because the page lists none.
  def test_the_built_in_defaults_hold_no_label_artifact_or_cache
    settings = resolve(Proof::ProjectFile.none, "test").settings

    assert_equal([0, 0, 0], [settings.labels.labels.size, settings.artifacts.size, settings.caches.size])
  end

  # Project file reference, "How values combine", table: "The `defaults` node"
  # comes before "Proof's built-in defaults", as in `defaults memory="8GB"`.
  def test_defaults_come_before_the_built_in_defaults
    file = Proof::ProjectFile.new(defaults: given(cpus: 4, memory: "8GB", timeout: "45m"))
    settings = resolve(file, "test").settings

    assert_equal([4, 8192, 2700], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
  end

  # Project file reference, "How values combine", table: "The task's entry in
  # the project file" comes before "The `defaults` node", as in `task test memory="12GB"`.
  def test_an_entry_comes_before_the_defaults
    file = Proof::ProjectFile.new(defaults: given(memory: "8GB"), entries: [entry("test", memory: "12GB")])

    assert_equal(12_288, resolve(file, "test").settings.megabytes)
  end

  # Project file reference, "How values combine", table: "A flag on `proof run`"
  # comes before "The task's entry", as in `--memory 16GB`.
  def test_a_flag_comes_before_the_entry
    file = Proof::ProjectFile.new(defaults: given(memory: "8GB"), entries: [entry("test", memory: "12GB")])

    assert_equal(16_384, resolve(file, "test", memory: "16GB").settings.megabytes)
  end

  # Project file reference, "How values combine": "For each value of a run,
  # Proof uses the first of these that has it", so a value an entry lacks comes
  # from the defaults, and one that neither has from the built-in defaults.
  def test_each_value_comes_from_the_first_source_that_has_it
    file = Proof::ProjectFile.new(defaults: given(cpus: 4), entries: [entry("test", timeout: "10m")])
    settings = resolve(file, "test").settings

    assert_equal([4, 4096, 600], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
  end

  # Project file reference, "How values combine": a task with an entry that gives
  # nothing takes everything from the defaults, and another task's entry is not its.
  def test_another_tasks_entry_gives_nothing
    file = Proof::ProjectFile.new(defaults: given(cpus: 4), entries: [entry("test", cpus: 8)])

    assert_equal(4, resolve(file, "package").settings.cpus)
  end

  # Project file reference, "How values combine": a memory of `0GB` is a value
  # (the sizes table calls it "Valid"), so it comes before the built-in 4 GB.
  def test_zero_megabytes_are_a_value_that_comes_first
    file = Proof::ProjectFile.new(entries: [entry("test", memory: "0GB")])

    assert_equal(0, resolve(file, "test").settings.megabytes)
  end

  # Project file reference, "How values combine": "`os` replaces: a task's `os`
  # replaces the `defaults` node's `os`".
  def test_an_entrys_os_replaces_the_defaults_os
    file = Proof::ProjectFile.new(defaults: given(os: %w[linux macos]), entries: [entry("test", os: ["windows"])])

    assert_equal(["windows"], os_names(resolve(file, "test").settings.os))
  end

  # Project file reference, "How values combine": "and `--os` replaces both".
  def test_a_flags_os_replaces_the_entrys_and_the_defaults
    file = Proof::ProjectFile.new(defaults: given(os: %w[linux macos]), entries: [entry("test", os: ["windows"])])

    assert_equal(["macos"], os_names(resolve(file, "test", os: ["macos"]).settings.os))
  end

  # Project file reference, "How values combine": the defaults' `os` applies to a
  # task whose entry has none, and a task with no entry.
  def test_the_defaults_os_applies_to_a_task_whose_entry_has_none
    file = Proof::ProjectFile.new(defaults: given(os: %w[linux macos]), entries: [entry("test", cpus: 4)])

    assert_equal([%w[linux macos]] * 2, %w[test lint].map { |name| os_names(resolve(file, name).settings.os) })
  end

  # Project file reference, "How values combine": "`label`, `artifact`, and
  # `cache` add: a task's entries add to those in `defaults`".
  def test_an_entrys_labels_artifacts_and_caches_add_to_the_defaults
    file = Proof::ProjectFile.new(
      defaults: given(label: ["gpu"], artifact: ["a/*"], cache: ["c1"]),
      entries: [entry("test", label: ["desktop"], artifact: ["b/*"], cache: ["c2"])]
    )
    settings = resolve(file, "test").settings

    assert_equal(%w[desktop gpu], label_names(settings.labels))
    assert_equal([%w[a/* b/*], %w[c1 c2]], [path_names(settings.artifacts), path_names(settings.caches)])
  end

  # Project file reference, "How values combine": "`--label` and `--keep` add to
  # both", so a flag's labels and artifacts add to the entry's and the defaults'.
  def test_a_flags_labels_and_artifacts_add_to_the_entrys_and_the_defaults
    entries = [entry("test", label: ["desktop"], artifact: ["a/*"])]
    file = Proof::ProjectFile.new(defaults: given(label: ["gpu"]), entries:)
    settings = resolve(file, "test", label: ["kvm"], artifact: ["b/*"]).settings

    assert_equal(%w[desktop gpu kvm], label_names(settings.labels))
    assert_equal(%w[a/* b/*], path_names(settings.artifacts))
  end

  # Project file reference, "How values combine": "`label`, `artifact`, and
  # `cache` add", and a flag adds a cache to the entry's and the defaults' too.
  def test_a_flags_caches_add_to_the_entrys_and_the_defaults
    file = Proof::ProjectFile.new(defaults: given(cache: ["c1"]), entries: [entry("test", cache: ["c2"])])

    assert_equal(%w[c1 c2 c3], path_names(resolve(file, "test", cache: ["c3"]).settings.caches))
  end

  # Project file reference, "Labels": "Proof compares labels without regard to
  # case, so `GPU` and `gpu` are one label", so adding a label twice keeps one.
  def test_a_label_added_by_two_sources_in_two_cases_is_one_label
    file = Proof::ProjectFile.new(defaults: given(label: ["GPU"]), entries: [entry("test", label: ["gpu"])])

    assert_equal(1, resolve(file, "test").settings.labels.labels.size)
  end

  # A path that two sources both give is kept once.
  def test_a_path_added_by_two_sources_is_one_path
    file = Proof::ProjectFile.new(defaults: given(cache: ["c1"]), entries: [entry("test", cache: ["c1"])])

    assert_equal(["c1"], path_names(resolve(file, "test").settings.caches))
  end

  # Project file reference, "`task`": "**With `COMMAND`,** the entry defines a
  # task with that command", and "**Without `COMMAND`,** ... Proof runs `mise
  # run NAME`", so each task's command is its entry's, or none.
  def test_each_tasks_command_is_its_entrys_or_none
    commands = resolve(complete_example, "docs", "test").commands

    assert_equal(named(["docs", "bundle exec rake rdoc"], ["test", nil]), commands)
  end

  # Project file reference, "`defaults`": defaults "take the same properties and
  # children as a `task`, except a command", so a task with no entry has no command.
  def test_a_task_with_no_entry_has_no_command
    assert_equal(named(["lint", nil]), resolve(complete_example, "lint").commands)
  end

  # Project file reference, "Tasks without a project file": "A task that's
  # neither in the project file nor in `mise.toml` fails on the runner", so a
  # name with no entry is not refused here: it gets the defaults, and no command.
  def test_a_name_with_no_entry_gets_the_defaults_and_the_built_in_defaults
    file = Proof::ProjectFile.new(defaults: given(cpus: 4, label: ["gpu"]))
    settings = resolve(file, "nothing").settings

    assert_equal([4, 4096], [settings.cpus, settings.megabytes])
    assert_equal(%w[gpu], label_names(settings.labels))
  end
end

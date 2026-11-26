# frozen_string_literal: true

require_relative("project_file_helper")
require_relative("test_helper")

# Checks putting one source's settings over another's.
class TaskSettingsOverTest < Minitest::Test
  include ProjectFileHelper

  # Project file reference, "How values combine": "For each value of a run,
  # Proof uses the first of these that has it", so a value the upper source
  # gives beats the lower source's, and one it lacks comes from the lower.
  def test_a_single_value_comes_from_the_first_source_that_has_it
    settings = given(cpus: 8, timeout: "10m").over(given(cpus: 4, memory: "8GB", timeout: "45m"))

    assert_equal([8, 8192, 600], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
  end

  # Project file reference, "How values combine": `0GB` is a size the table of
  # sizes calls "Valid", so 0 megabytes beat a lower source's.
  def test_zero_megabytes_beat_a_lower_source
    assert_equal(0, given(memory: "0GB").over(given(memory: "8GB")).megabytes)
  end

  # Project file reference, "How values combine": "`os` replaces: a task's `os`
  # replaces the `defaults` node's `os`".
  def test_os_replaces
    assert_equal(["windows"], os_names(given(os: ["windows"]).over(given(os: %w[linux macos])).os))
  end

  # Project file reference, "How values combine": the lower source's `os` applies
  # when the upper one gives none.
  def test_os_comes_from_the_lower_source_when_the_upper_gives_none
    assert_equal(%w[linux macos], os_names(given(cpus: 2).over(given(os: %w[linux macos])).os))
  end

  # Project file reference, "How values combine": "`label`, `artifact`, and
  # `cache` add".
  def test_labels_artifacts_and_caches_add
    upper = given(label: ["a"], artifact: ["x"], cache: ["m"])
    settings = upper.over(given(label: ["b"], artifact: ["y"], cache: ["n"]))

    assert_equal(%w[a b], label_names(settings.labels))
    assert_equal([%w[x y], %w[m n]], [path_names(settings.artifacts), path_names(settings.caches)])
  end

  # Project file reference, "How values combine": a list one source lacks is the
  # other's, whichever source is the upper.
  def test_a_list_one_source_lacks_is_the_others
    assert_equal(%w[b], label_names(given(cpus: 2).over(given(label: ["b"])).labels))
    assert_equal(%w[a], label_names(given(label: ["a"]).over(given(cpus: 2)).labels))
  end

  # Settings that neither source gives stay not given, so a third source can fill them in.
  def test_a_setting_that_neither_source_gives_stays_not_given
    assert_equal(Proof::TaskSettings.none, Proof::TaskSettings.none.over(Proof::TaskSettings.none))
  end

  # Putting settings over others builds new settings and leaves the two as they were.
  def test_the_two_sources_stay_as_they_were
    upper = given(cpus: 8)
    upper.over(given(cpus: 4, label: ["gpu"]))

    assert_equal(given(cpus: 8), upper)
  end
end

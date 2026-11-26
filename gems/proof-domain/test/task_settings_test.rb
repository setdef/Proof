# frozen_string_literal: true

require_relative("test_helper")

# Checks the settings that one source gives: a task's entry, the `defaults` node, or the flags of `proof run`.
class TaskSettingsTest < Minitest::Test
  # A set of the operating systems with these names.
  def oses(*names)
    names.map { |name| Proof::OS.new(name:) }
  end

  # Project file reference, "How values combine": "For each value of a run,
  # Proof uses the first of these that has it", so a source can lack any value.
  def test_a_source_that_gives_nothing_has_no_setting
    none = Proof::TaskSettings.none

    assert_equal([nil] * 7, none.to_h.values)
    assert_equal(%i[os labels cpus megabytes time_limit artifacts caches], none.to_h.keys)
  end

  # Project file reference, "Mistakes Proof catches": "a node or property isn't
  # one this page lists", so settings built with a keyword that names no
  # setting, such as `cpu:`, are refused, not read as settings that give nothing.
  def test_a_keyword_that_names_no_setting_is_refused
    error = assert_raises(ArgumentError) { Proof::TaskSettings.new(cpu: 4) }

    assert_equal("unknown keyword: :cpu", error.message)
  end

  # Project file reference, "A complete example": the `defaults` node gives
  # `cpus=4 memory="8GB" timeout="45m"`, `os linux macos windows`, and
  # `cache "tmp/engine/build"`, and gives no label or artifact.
  def test_a_source_gives_every_setting_it_has_and_no_other
    settings = Proof::TaskSettings.new(os: Proof::OS.all, cpus: 4, megabytes: 8192, time_limit: Proof::TimeLimit.read("45m"))

    assert_equal([4, 8192, 2700], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
    assert_equal(Set.new(Proof::OS.all), settings.os)
    assert_equal([nil, nil, nil], [settings.labels, settings.artifacts, settings.caches])
  end

  # Project file reference, "A complete example": the `defaults` node gives
  # `cache "tmp/engine/build"`, so a cache folder is kept as a path pattern.
  def test_a_cache_folder_is_kept
    folder = Proof::PathPattern.new(path: "tmp/engine/build")

    assert_equal(Set[folder], Proof::TaskSettings.new(caches: [folder]).caches)
  end

  # Project file reference, "A complete example": the `test` task gives `label
  # desktop`, so labels are a set of labels, and the `package` task gives `artifact "pkg/*.gem"`.
  def test_labels_and_artifacts_are_kept
    settings = Proof::TaskSettings.new(
      labels: Proof::LabelSet.of("desktop"), artifacts: [Proof::PathPattern.new(path: "pkg/*.gem")]
    )

    assert_equal(Proof::LabelSet.of("desktop"), settings.labels)
    assert_equal(Set[Proof::PathPattern.new(path: "pkg/*.gem")], settings.artifacts)
  end

  # Project file reference, "Children": `os` lists "One or more" systems, and a
  # repeated one is the same system, so the set holds each once.
  def test_the_operating_systems_are_a_set
    assert_equal(Set[Proof::OS.new(name: :linux)], Proof::TaskSettings.new(os: oses("linux", "linux")).os)
  end

  # Project file reference, "Children": `os` lists "One or more" systems, so a
  # source that gives `os` gives at least one.
  def test_an_empty_set_of_operating_systems_is_refused
    assert_raises(Proof::InvalidTaskSettingsError) { Proof::TaskSettings.new(os: []) }
  end

  # Project file reference, "Mistakes Proof catches": "an `os` node lists an
  # operating system other than `linux`, `macos`, or `windows`", so the
  # operating systems are `Proof::OS` values, not names.
  def test_operating_systems_that_are_not_values_are_refused
    ["linux", [:linux], ["linux"], oses("linux") + ["macos"]].each do |os|
      assert_raises(Proof::InvalidTaskSettingsError, os.inspect) { Proof::TaskSettings.new(os:) }
    end
  end

  # Project file reference, "Mistakes Proof catches": "a `label` breaks the
  # label rule", so labels are a `Proof::LabelSet` of checked labels.
  def test_labels_that_are_not_a_label_set_are_refused
    [["gpu"], Set[Proof::Label.new(name: "gpu")], "gpu", 1].each do |labels|
      assert_raises(Proof::InvalidTaskSettingsError, labels.inspect) { Proof::TaskSettings.new(labels:) }
    end
  end

  # Project file reference, "Properties": `cpus` is "A whole number from 1", and
  # "Mistakes Proof catches" lists "a value has the wrong type, such as `cpus="four"`".
  def test_cpus_that_are_not_a_whole_number_from_one_are_refused
    [0, -1, 1.5, "4", "four"].each do |cpus|
      assert_raises(Proof::InvalidResourcesError, cpus.inspect) { Proof::TaskSettings.new(cpus:) }
    end
  end

  # Project file reference, "Properties": `memory` is a size, which Proof holds
  # in whole megabytes from 0, as `Proof::Resources` does.
  def test_megabytes_that_are_not_a_whole_number_from_zero_are_refused
    [-1, 1.5, "512", "8GB"].each do |megabytes|
      assert_raises(Proof::InvalidResourcesError, megabytes.inspect) { Proof::TaskSettings.new(megabytes:) }
    end
  end

  # Project file reference, "Sizes": "0GB" is "Valid", so a source can give 0 megabytes.
  def test_zero_megabytes_are_a_setting_that_is_given
    assert_equal(0, Proof::TaskSettings.new(megabytes: 0).megabytes)
  end

  # Project file reference, "Properties": a `timeout` is a duration, so the
  # time limit is a `Proof::TimeLimit`, not a number or text.
  def test_a_time_limit_that_is_not_a_time_limit_is_refused
    [2700, "45m", Proof::TimeLimit.read("45m").seconds].each do |time_limit|
      assert_raises(Proof::InvalidTaskSettingsError, time_limit.inspect) { Proof::TaskSettings.new(time_limit:) }
    end
  end

  # Project file reference, "Mistakes Proof catches": "a `cache` or `artifact`
  # path starts with `/` or contains `..`", so the paths are `Proof::PathPattern` values.
  def test_artifacts_and_caches_that_are_not_path_patterns_are_refused
    ["pkg/*.gem", ["pkg/*.gem"], [nil]].each do |paths|
      assert_raises(Proof::InvalidTaskSettingsError, paths.inspect) { Proof::TaskSettings.new(artifacts: paths) }
      assert_raises(Proof::InvalidTaskSettingsError, paths.inspect) { Proof::TaskSettings.new(caches: paths) }
    end
  end

  # Project file reference, "Properties": the settings are kept, and two
  # sources that give the same settings are one value.
  def test_two_sources_that_give_the_same_settings_are_equal
    given = { cpus: 4, os: oses("linux") }

    assert_equal(Proof::TaskSettings.new(**given), Proof::TaskSettings.new(**given))
  end

  # The message names the setting and what it got.
  def test_the_message_names_the_setting_and_the_value
    error = assert_raises(Proof::InvalidTaskSettingsError) { Proof::TaskSettings.new(os: []) }

    assert_equal("os is one or more operating systems, not []", error.message)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidTaskSettingsError, :<, Proof::Error)
  end
end

# frozen_string_literal: true

require_relative("project_file_helper")
require_relative("test_helper")

# Checks the settings of a run for each example under the project file page's "Examples".
class ProjectFileExamplesTest < Minitest::Test
  include ProjectFileHelper

  # Project file reference, "Examples", "Request more memory for one task":
  # `task package memory="12GB"` means "The `package` task requests 12 GB. Every
  # other value comes from `defaults` or Proof's built-in defaults."
  def test_request_more_memory_for_one_task
    file = Proof::ProjectFile.new(entries: [entry("package", memory: "12GB")])

    assert_equal(expected(megabytes: 12_288, commands: named(["package", nil])), summary(resolve(file, "package")))
  end

  # Project file reference, "Examples", "Request more memory for one task": the
  # other tasks keep the built-in 4 GB.
  def test_request_more_memory_for_one_task_leaves_the_others
    file = Proof::ProjectFile.new(entries: [entry("package", memory: "12GB")])

    assert_equal(4096, resolve(file, "test").settings.megabytes)
  end

  # The "Examples" page's `task ios "bin/test-ios"` with `os macos` and `label desktop`.
  def ios_file
    Proof::ProjectFile.new(entries: [entry("ios", "bin/test-ios", os: ["macos"], label: ["desktop"])])
  end

  # Project file reference, "Examples", "A task for one operating system":
  # "`proof run ios` waits for a Mac whose runner can open windows."
  def test_a_task_for_one_operating_system
    run = resolve(ios_file, "ios")

    assert_equal(expected(os: ["macos"], labels: ["desktop"], commands: named(["ios", "bin/test-ios"])), summary(run))
  end

  # Project file reference, "Examples", "A task for one operating system":
  # "`proof run ios --os linux` runs it on Linux anyway".
  def test_a_task_for_one_operating_system_run_on_another
    run = resolve(ios_file, "ios", os: ["linux"])

    assert_equal(expected(os: ["linux"], labels: ["desktop"], commands: named(["ios", "bin/test-ios"])), summary(run))
  end

  # Project file reference, "Examples", "Keep the gems a build makes, and
  # download them": `proof run package --os linux --download` "builds on Linux"
  # and keeps `pkg/*.gem`.
  def test_keep_the_gems_a_build_makes
    file = Proof::ProjectFile.new(entries: [entry("package", artifact: ["pkg/*.gem"])])
    settings = resolve(file, "package", os: ["linux"]).settings

    assert_equal([["linux"], ["pkg/*.gem"]], [os_names(settings.os), path_names(settings.artifacts)])
  end

  # Project file reference, "Examples", "Keep a compiler cache between runs":
  # `defaults { cache ".cache/ccache" }` means "Each runner keeps `.cache/ccache`
  # for the project's next run there", so every task gets the cache.
  def test_keep_a_compiler_cache_between_runs
    file = Proof::ProjectFile.new(defaults: given(cache: [".cache/ccache"]), entries: [entry("test")])

    assert_equal([[".cache/ccache"]] * 2, %w[test lint].map { |name| path_names(resolve(file, name).settings.caches) })
  end
end

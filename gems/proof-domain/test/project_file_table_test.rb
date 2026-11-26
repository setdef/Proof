# frozen_string_literal: true

require_relative("project_file_helper")
require_relative("test_helper")

# Checks the settings of a run for each row of the project file page's table of
# tasks without a project file, and for the complete example's own tasks.
class ProjectFileTableTest < Minitest::Test
  include ProjectFileHelper

  # Project file reference, "Tasks without a project file", row 1, column
  # "Without a project file": "Runs `mise run test` on any operating system with
  # a runner free, with 2 CPUs, 4 GB, and 60 minutes."
  def test_proof_run_test_without_a_project_file
    run = resolve(Proof::ProjectFile.none, "test")

    assert_equal(expected(commands: named(["test", nil])), summary(run))
  end

  # Project file reference, "Tasks without a project file", row 1, column "With
  # the complete example on this page": "Runs `mise run test` on whichever
  # operating system has a runner free that can open windows."
  def test_proof_run_test_with_the_complete_example
    run = resolve(complete_example, "test")

    assert_equal(expected(**EXAMPLE_DEFAULTS, labels: ["desktop"], commands: named(["test", nil])), summary(run))
  end

  # Project file reference, "Tasks without a project file", row 2, column
  # "Without a project file": "Runs `mise run test` on Linux, with 2 CPUs, 4 GB,
  # and 60 minutes."
  def test_proof_run_test_os_linux_without_a_project_file
    run = resolve(Proof::ProjectFile.none, "test", os: ["linux"])

    assert_equal(expected(os: ["linux"], commands: named(["test", nil])), summary(run))
  end

  # Project file reference, "Tasks without a project file", row 2, column "With
  # the complete example on this page": "Runs `mise run test` on Linux, with 4
  # CPUs, 8 GB, and 45 minutes, on a runner that can open windows."
  def test_proof_run_test_os_linux_with_the_complete_example
    run = resolve(complete_example, "test", os: ["linux"])

    assert_equal(
      expected(**EXAMPLE_DEFAULTS, os: ["linux"], labels: ["desktop"], commands: named(["test", nil])),
      summary(run)
    )
  end

  # Project file reference, "Tasks without a project file", row 3, column
  # "Without a project file": "Fails on the runner: mise has no `docs` task", so
  # the run still gets the built-in defaults on Linux, and no command.
  def test_proof_run_docs_os_linux_without_a_project_file
    run = resolve(Proof::ProjectFile.none, "docs", os: ["linux"])

    assert_equal(expected(os: ["linux"], commands: named(["docs", nil])), summary(run))
  end

  # Project file reference, "Tasks without a project file", row 3, column "With
  # the complete example on this page": "Runs `bundle exec rake rdoc` on Linux
  # and keeps `doc/api/**`."
  def test_proof_run_docs_os_linux_with_the_complete_example
    run = resolve(complete_example, "docs", os: ["linux"])
    docs = expected(**EXAMPLE_DEFAULTS, os: ["linux"], artifacts: ["doc/api/**"])

    assert_equal(docs.merge(commands: named(["docs", "bundle exec rake rdoc"])), summary(run))
  end

  # Project file reference, "A complete example": "Every task in this file works
  # on all three operating systems", but the `docs` task has `os linux`, so it
  # works on Linux only, as the paragraph says of it.
  def test_the_docs_task_works_on_linux_only
    assert_equal(["linux"], os_names(resolve(complete_example, "docs").settings.os))
  end

  # Project file reference, "A complete example": "The `package` task keeps the
  # gems it builds", with the defaults' 4 CPUs, 8 GB, 45 minutes, and cache.
  def test_the_package_task_keeps_its_gems
    run = resolve(complete_example, "package")

    assert_equal(
      expected(**EXAMPLE_DEFAULTS, artifacts: ["pkg/*.gem"], commands: named(["package", nil])),
      summary(run)
    )
  end

  # Project file reference, "Several tasks on one command line": `proof run lint
  # ::: test` on the complete example gives `lint`, with no entry, the defaults,
  # and `test` the desktop label, and the run gets both.
  def test_lint_and_test_on_the_complete_example
    run = resolve(complete_example, "lint", "test")

    assert_equal(
      expected(**EXAMPLE_DEFAULTS, labels: ["desktop"], commands: named(["lint", nil], ["test", nil])),
      summary(run)
    )
  end
end

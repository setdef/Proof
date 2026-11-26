# frozen_string_literal: true

require_relative("project_file_helper")

# A project file whose tasks differ in everything the project file page's table
# of several tasks lists.
module SeveralTasksHelper
  include ProjectFileHelper

  # `lint` works on Linux and macOS, `test` on macOS and Windows, and `package` anywhere.
  def several
    package = entry("package", cpus: 4, memory: "16GB", timeout: "2h")
    Proof::ProjectFile.new(entries: [lint_entry, entry_for_test, package])
  end

  # The `lint` task of `several`.
  def lint_entry
    entry(
      "lint",
      os: %w[linux macos],
      label: ["kvm"],
      cpus: 2,
      memory: "2GB",
      timeout: "10m",
      artifact: ["a/*"],
      cache: ["c1"]
    )
  end

  # The `test` task of `several`.
  def entry_for_test
    entry(
      "test",
      os: %w[macos windows],
      label: ["desktop"],
      cpus: 8,
      memory: "1GB",
      timeout: "5m",
      artifact: ["b/*"],
      cache: ["c2"]
    )
  end
end

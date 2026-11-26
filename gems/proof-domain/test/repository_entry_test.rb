# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks one `repository` entry of the pool file: the repository whose pushed commits Proof runs tasks on.
class RepositoryEntryTest < Minitest::Test
  include PoolFileHelper

  LOTA = "https://github.com/setdef/Lota.git"
  MESSAGES = {
    { name: 5 } => "a repository's name is a name, not 5",
    { url: 5 } => "a repository's url is a name, not 5",
    { credentials_file: 5 } => "a repository's credentials file is a path or nothing, not 5",
    { branches: [] } => "a repository's branches are one or more branch names that differ, not []",
    { tasks: [] } => "a repository's tasks are one or more task names that differ, not []",
    { poll: 5 } => "a repository's poll is a duration, not 5",
  }.freeze
  NOT_NAMES = [
    { branches: [5] },
    { branches: [""] },
    { branches: %w[trunk trunk] },
    { tasks: [5] },
    { tasks: [""] },
    { tasks: %w[test test] },
    { tasks: "test" },
  ].freeze
  private_constant(:LOTA, :MESSAGES, :NOT_NAMES)

  # The members of an entry, as the page's table lists them.
  def members_of(entry)
    [entry.name, entry.url, entry.credentials_file, entry.branches, entry.tasks, entry.poll]
  end

  # Pool file reference, "A complete example": `repository lota url="https://github.com/setdef/Lota.git"` with
  # `credentials-file "~/.config/proof/credentials/lota"`, `branch trunk`, and `task test` and `task package`.
  def test_the_complete_examples_repository_is_what_its_entry_says
    assert_equal(
      ["lota", LOTA, "~/.config/proof/credentials/lota", %w[trunk], %w[test package], duration("1m")],
      members_of(lota_entry)
    )
  end

  # Pool file reference, "`repository`", table: `credentials-file`'s default is "None", so a public repository has
  # none, and "Run tasks on two branches of a public repository" has `branch trunk release` and `task test`.
  def test_a_public_repository_has_no_credentials_file
    entry = repository_entry("lota", LOTA, branches: %w[trunk release], tasks: %w[test])

    assert_equal(["lota", LOTA, nil, %w[trunk release], %w[test], duration("1m")], members_of(entry))
  end

  # Pool file reference, "`repository`", table: `poll` has the default `"1m"`, and "How often the server fetches the
  # branches" is a duration, so a `poll` that is given is kept.
  def test_the_poll_defaults_to_a_minute_and_a_given_poll_is_kept
    given = repository_entry("lota", LOTA, branches: %w[trunk], tasks: %w[test], poll: "30s")
    unnamed = repository_entry("lota", LOTA, branches: %w[trunk], tasks: %w[test])

    assert_equal([duration("30s"), duration("1m")], [given.poll, unnamed.poll])
  end

  # The same row, "`credentials-file`": "A file holding a read-only token", and the server expands the path later, so
  # the path is kept as written, with its `~`.
  def test_the_credentials_file_is_kept_as_written
    assert_equal("~/.config/proof/credentials/lota", lota_entry.credentials_file)
  end

  # Pool file reference, "`repository`": `url` is "Required", `branch` is "Required", and `task` is "Required", each
  # with one or more, so an entry without one of them is refused, and so is one with an empty list.
  def test_a_url_a_branch_and_a_task_are_required
    refused = [{ url: nil }, { url: "" }, { branches: [] }, { branches: nil }, { tasks: [] }, { tasks: nil }]

    refused.each do |change|
      given = { name: "lota", url: LOTA, branches: %w[trunk], tasks: %w[test] }.merge(change)

      assert_raises(Proof::InvalidRepositoryEntryError, change.inspect) { Proof::RepositoryEntry.new(**given) }
    end
  end

  # Pool file reference, "`repository`": `branch BRANCH...` and `task TASK...` are each a list of names, so a name that
  # is not text or is empty is refused, and so is a branch or a task listed twice.
  def test_a_branch_or_a_task_that_is_not_a_name_or_is_listed_twice_is_refused
    NOT_NAMES.each do |change|
      given = { name: "lota", url: LOTA, branches: %w[trunk], tasks: %w[test] }.merge(change)

      assert_raises(Proof::InvalidRepositoryEntryError, change.inspect) { Proof::RepositoryEntry.new(**given) }
    end
  end

  # Pool file reference, "`repository`": `repository NAME`, so a name is text of at least one character, and the
  # credentials file is a path or nothing, and the poll is a duration.
  def test_a_name_a_credentials_file_and_a_poll_of_the_wrong_kind_are_refused
    refused = [
      { name: 5 }, { name: "" }, { credentials_file: 5 }, { credentials_file: "" }, { poll: "1m" }, { poll: nil }
    ]

    refused.each do |change|
      given = { name: "lota", url: LOTA, branches: %w[trunk], tasks: %w[test] }.merge(change)

      assert_raises(Proof::InvalidRepositoryEntryError, change.inspect) { Proof::RepositoryEntry.new(**given) }
    end
  end

  # The messages say which member is wrong and what it got.
  def test_the_messages_name_the_member
    MESSAGES.each do |change, message|
      given = { name: "lota", url: LOTA, branches: %w[trunk], tasks: %w[test] }.merge(change)
      error = assert_raises(Proof::InvalidRepositoryEntryError) { Proof::RepositoryEntry.new(**given) }

      assert_equal(message, error.message)
    end
  end

  # The entry freezes what a caller could change: its name, its branches, and its tasks.
  def test_the_name_the_branches_and_the_tasks_are_frozen_copies
    branches = %w[trunk]
    tasks = %w[test]
    entry = Proof::RepositoryEntry.new(name: +"lota", url: LOTA, branches:, tasks:)
    branches << "release"
    tasks << "package"

    assert_equal(
      [%w[trunk], %w[test], true, true, true],
      [entry.branches, entry.tasks, entry.name.frozen?, entry.branches.frozen?, entry.tasks.frozen?]
    )
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidRepositoryEntryError, :<, Proof::Error)
  end
end

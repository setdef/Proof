# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the values of a `repository` node: a blank name, the wrong type, and a poll that is not a
# duration. Each is refused at the line of its node, with what the domain says.
class PoolFileReaderRepositoryValuesTest < Minitest::Test
  include PoolFileReaderHelper

  BODY = "{\n  branch trunk\n  task test\n"
  BLANKS = [
    ["repository \"\" url=\"u\" #{BODY}}\n", 1, "a repository's name is not empty and not only spaces, not \"\""],
    ["repository a url=\" \" #{BODY}}\n", 1, "a repository's url is not empty and not only spaces, not \" \""],
    [
      "repository a url=\"u\" {\n  branch \" \"\n  task t\n}\n",
      2,
      "a branch's name is not empty and not only spaces, not \" \"",
    ],
    [
      "repository a url=\"u\" {\n  branch b\n  task \"\"\n}\n",
      3,
      "a task's name is not empty and not only spaces, not \"\"",
    ],
    [
      "repository a url=\"u\" #{BODY}  credentials-file \"  \"\n}\n",
      4,
      "a credentials file's path is not empty and not only spaces, not \"  \"",
    ],
  ].freeze
  LISTS = [
    ["  branch 5\n  task t\n", { branches: [5], tasks: %w[t] }],
    ["  branch b b\n  task t\n", { branches: %w[b b], tasks: %w[t] }],
    ["  branch b\n  task t\n  task t\n", { branches: %w[b], tasks: %w[t t] }],
  ].freeze
  private_constant(:BODY, :BLANKS, :LISTS)

  # The domain's refusal of an entry built with this change from a good one.
  def domain_refused(**change)
    given = { name: "a", url: "u", branches: %w[trunk], tasks: %w[test] }.merge(change)

    domain_said(Proof::InvalidRepositoryEntryError) { Proof::RepositoryEntry.new(**given) }
  end

  # Project file reference, "Mistakes Proof catches" and issue #52: "a blank name", for a repository's name, its URL,
  # a branch, a task, and the path of a credentials file.
  def test_a_blank_name_url_branch_task_or_path_is_refused
    assert_refusals(BLANKS)
  end

  # A name, a URL, and a path that are not text are refused at the repository's line, with what the domain says.
  def test_a_name_url_or_path_that_is_not_text_is_refused
    assert_refused("repository 5 url=\"u\" #{BODY}}\n", 1, domain_refused(name: 5))
    assert_refused("repository a url=5 #{BODY}}\n", 1, domain_refused(url: 5))
    assert_refused("repository a url=\"u\" #{BODY}  credentials-file 5\n}\n", 1, domain_refused(credentials_file: 5))
  end

  # A branch or a task that is not text, or listed twice, is refused at the repository's line, with what the domain
  # says.
  def test_a_branch_or_a_task_that_is_not_text_or_is_listed_twice_is_refused
    LISTS.each do |text, change|
      assert_refused("repository a url=\"u\" {\n#{text}}\n", 1, domain_refused(**change))
    end
  end

  # Pool file reference, "Durations": `poll "1.5m"` is "Refused: the number is whole", and a poll that is a number is
  # refused too, with the setting's name.
  def test_a_poll_that_is_not_a_duration_is_refused
    [["\"1.5m\"", "1.5m"], ["5", 5], ["\"1d\"", "1d"]].each do |written, value|
      assert_refused(
        "repository a url=\"u\" #{BODY}  poll #{written}\n}\n",
        4,
        domain_said(Proof::InvalidDurationError) { Proof::Duration.read(value, units: %i[s m h], name: "poll") }
      )
    end
  end
end

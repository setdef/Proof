# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks that the reader of the pool file builds the repositories that the page says each form means.
class PoolFileReaderRepositoriesTest < Minitest::Test
  include PoolFileReaderHelper

  LOTA = "https://github.com/setdef/Lota.git"
  FORM = "repository lota url=\"#{LOTA}\"".freeze
  private_constant(:LOTA, :FORM)

  # The repositories that this text reads as.
  def repositories_of(text)
    read(text).repositories
  end

  # Pool file reference, "A complete example": `repository lota url="https://github.com/setdef/Lota.git"` with
  # `credentials-file "~/.config/proof/credentials/lota"`, `branch trunk`, `task test`, and `task package`.
  def test_the_complete_examples_repository
    text = "#{FORM} {\n  credentials-file \"~/.config/proof/credentials/lota\"\n  branch trunk\n  task test\n  " \
      "task package\n}\n"

    assert_equal([lota_entry], repositories_of(text))
  end

  # Pool file reference, "Examples", "Run tasks on two branches of a public repository": `branch trunk release` and
  # `task test`, and "A public repository needs no `credentials-file`."
  def test_the_page_example_of_two_branches_of_a_public_repository
    expected = repository_entry("lota", LOTA, branches: %w[trunk release], tasks: %w[test])

    assert_equal([expected], repositories_of(page_example("### Run tasks on two branches of a public repository")))
  end

  # Pool file reference, "`repository`", table: `poll` has the default `"1m"`, and a `poll` that is given is kept.
  def test_the_poll_defaults_to_a_minute_and_a_given_poll_is_kept
    given = repositories_of("#{FORM} {\n  branch trunk\n  task test\n  poll \"90s\"\n}\n").first
    unnamed = repositories_of("#{FORM} {\n  branch trunk\n  task test\n}\n").first

    assert_equal([duration("90s"), duration("1m")], [given.poll, unnamed.poll])
  end

  # Pool file reference, "Durations": `poll "90s"` is "Valid".
  def test_the_page_row_that_gives_a_poll_in_seconds_is_read
    assert_equal(duration("90s"), repositories_of("#{FORM} {\n  branch a\n  task t\n  poll \"90s\"\n}\n").first.poll)
  end

  # Pool file reference, "`repository`": `task TASK...` may be given in several nodes, as the complete example gives it,
  # and joins in order, and the repositories are in the order the file has them.
  def test_tasks_given_in_several_nodes_join_and_repositories_keep_their_order
    text = "repository b url=\"u\" {\n  branch x\n  task one two\n  task three\n}\n" \
      "repository a url=\"v\" {\n  branch y\n  task four\n}\n"

    assert_equal([%w[b a], %w[one two three]], [repositories_of(text).map(&:name), repositories_of(text).first.tasks])
  end

  # Pool file reference, "`repository`", `credentials-file`: "The server reads the token from this file", so the path
  # is kept as written, with its `~`, for the server to expand.
  def test_the_credentials_file_is_kept_as_written
    text = "#{FORM} {\n  credentials-file \"~/x\"\n  branch trunk\n  task test\n}\n"

    assert_equal("~/x", repositories_of(text).first.credentials_file)
  end
end

# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks that the pool file compares names with an accented letter without regard to case, as it does the names of
# ASCII letters.
class PoolFileReaderNamesAccentsTest < Minitest::Test
  include PoolFileReaderHelper

  DEFAULTS = "defaults {\n  budget \"1GB\"\n}\n"
  REPO = "url=\"u\" {\n  branch b\n  task t\n}\n"
  private_constant(:DEFAULTS, :REPO)

  # Pool file reference, "What happens when the file has a mistake": "Proof compares the names of hosts, runners, and
  # repositories without regard to case", and an accented letter has a case, so two hosts that differ only in it are
  # one host, refused at the second entry's line.
  def test_hosts_that_differ_only_in_the_case_of_an_accented_letter_are_refused_at_the_second
    assert_refused(
      "#{DEFAULTS}host Ünal {\n  runner a\n}\nhost ünal {\n  runner b\n}\n",
      7,
      "a second host is named \"Ünal\", and the first is on line 4. Each host has one entry, so merge them into one"
    )
  end

  # The same sentence, for repositories.
  def test_repositories_that_differ_only_in_the_case_of_an_accented_letter_are_refused_at_the_second
    assert_refused(
      "repository Édith #{REPO}repository édith #{REPO}",
      5,
      "a second repository is named \"Édith\", and the first is on line 1. " \
        "Each repository has one entry, so merge them into one"
    )
  end

  # The same sentence, for a runner on two hosts.
  def test_a_runner_on_two_hosts_that_differs_only_in_the_case_of_an_accented_letter_is_refused_at_the_second
    assert_refused(
      "#{DEFAULTS}host a {\n  runner É\n}\nhost b {\n  runner é\n}\n",
      8,
      "the runner \"é\" is also on the host \"a\", whose entry starts on line 4. " \
        "A runner is one operating system on one host, so list it on one"
    )
  end
end

# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the names across a pool file: two hosts with one name, a runner on two hosts, and two
# repositories with one name. Each is refused at the line of the second.
class PoolFileReaderNamesTest < Minitest::Test
  include PoolFileReaderHelper

  DEFAULTS = "defaults {\n  budget \"1GB\"\n}\n"
  REPO = "url=\"u\" {\n  branch b\n  task t\n}\n"
  private_constant(:DEFAULTS, :REPO)

  # Pool file reference, "`host`": "`proof status` shows the host under `NAME`" and "One entry for each physical
  # computer", so two hosts with one name are refused at the second, and the refusal names the first.
  def test_two_hosts_with_one_name_are_refused_at_the_second
    assert_refused(
      "#{DEFAULTS}host nuc {\n  runner a\n}\n\nhost nuc {\n  runner b\n}\n",
      8,
      "a second host is named \"nuc\", and the first is on line 4. Each host has one entry, so merge them into one"
    )
  end

  # Pool file reference, "`repository`": "`proof status` shows its runs under `NAME`", so two repositories with one name
  # are refused at the second.
  def test_two_repositories_with_one_name_are_refused_at_the_second
    assert_refused(
      "repository lota #{REPO}repository lota #{REPO}",
      5,
      "a second repository is named \"lota\", and the first is on line 1. " \
        "Each repository has one entry, so merge them into one"
    )
  end

  # Glossary, "runner": "One operating system on a host", and the design's decision of one host: a runner name on two
  # hosts is refused at the runner of the second, and the refusal names the first host.
  def test_a_runner_on_two_hosts_is_refused_at_the_second_hosts_runner
    assert_refused(
      "#{DEFAULTS}host nuc {\n  runner a b\n}\nhost pc {\n  runner c\n  runner d b\n}\n",
      9,
      "the runner \"b\" is also on the host \"nuc\", whose entry starts on line 4. " \
        "A runner is one operating system on one host, so list it on one"
    )
  end

  # The first of several mistakes in the names is the one refused: a third host with the first's name is refused at the
  # second host's line, not the third's.
  def test_the_first_repeat_is_the_one_refused
    error = assert_raises(Proof::PoolFileError) do
      read("#{DEFAULTS}host a {\n  runner r1\n}\nhost a {\n  runner r2\n}\nhost a {\n  runner r3\n}\n")
    end

    assert_equal(7, error.line)
  end

  # Names are compared as written, as the project file compares task names, so `nuc` and `NUC` are two hosts, and a
  # host and a repository with one name are two entries of different kinds.
  def test_names_that_differ_in_case_and_names_of_different_kinds_are_not_repeats
    text = "#{DEFAULTS}host nuc {\n  runner a\n}\nhost NUC {\n  runner b\n}\nrepository nuc #{REPO}"

    assert_equal([%w[nuc NUC], %w[nuc]], [read(text).hosts.map(&:name), read(text).repositories.map(&:name)])
  end

  # Hosts that share no runner, and repositories that share no name, are read.
  def test_hosts_with_different_runners_are_read
    text = "#{DEFAULTS}host nuc {\n  runner a\n}\nhost pc {\n  runner b c\n}\n"

    assert_equal([%w[a], %w[b c]], read(text).hosts.map(&:runners))
  end
end

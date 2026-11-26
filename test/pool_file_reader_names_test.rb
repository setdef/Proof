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

  # Pool file reference, "What happens when the file has a mistake": "Proof compares names without regard to case, as it
  # does labels, so `nuc` and `NUC` are one host, and a second entry for it is refused." The refusal is the one for a
  # repeated host, at the second entry's line, and names the first as it wrote the name, in either order.
  def test_two_hosts_that_differ_only_in_case_are_refused_at_the_second
    [%w[nuc NUC], %w[NUC nuc], %w[Nuc nUC]].each do |first, second|
      assert_refused(
        "#{DEFAULTS}host #{first} {\n  runner a\n}\n\nhost #{second} {\n  runner b\n}\n",
        8,
        "a second host is named #{first.inspect}, and the first is on line 4. " \
          "Each host has one entry, so merge them into one"
      )
    end
  end

  # The same sentence, for repositories.
  def test_two_repositories_that_differ_only_in_case_are_refused_at_the_second
    [%w[lota LOTA], %w[Lota lota]].each do |first, second|
      assert_refused(
        "repository #{first} #{REPO}repository #{second} #{REPO}",
        5,
        "a second repository is named #{first.inspect}, and the first is on line 1. " \
          "Each repository has one entry, so merge them into one"
      )
    end
  end

  # The same sentence, for a runner on two hosts, in any mix of case: refused at the second host's runner, naming the
  # runner as it is written there and the first host as written.
  def test_a_runner_on_two_hosts_in_any_mix_of_case_is_refused_at_the_second_hosts_runner
    [%w[Nuc-Linux nuc-linux], %w[nuc-linux NUC-LINUX]].each do |first, second|
      assert_refused(
        "#{DEFAULTS}host Nuc {\n  runner x #{first}\n}\nhost pc {\n  runner c\n  runner d #{second}\n}\n",
        9,
        "the runner #{second.inspect} is also on the host \"Nuc\", whose entry starts on line 4. " \
          "A runner is one operating system on one host, so list it on one"
      )
    end
  end

  # A runner listed twice on one host, in any mix of case, is refused at the host's line, with what the domain says,
  # since it is one operating system on one host.
  def test_a_runner_twice_on_one_host_in_any_mix_of_case_is_refused_at_the_hosts_line
    [%w[Pc-WSL pc-wsl], %w[pc-wsl PC-WSL]].each do |runners|
      assert_refused(
        "#{DEFAULTS}host pc {\n  runner #{runners.first}\n  runner #{runners.last}\n}\n",
        4,
        domain_said(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: "pc", runners:) }
      )
    end
  end

  # Names that are not text, which the domain refuses, compare as KDL reads them, so `host 5` twice is a repeat.
  def test_names_that_are_not_text_are_compared_as_read
    assert_refused(
      "#{DEFAULTS}host 5 {\n  runner a\n}\nhost 5 {\n  runner b\n}\n",
      7,
      "a second host is named 5, and the first is on line 4. Each host has one entry, so merge them into one"
    )
  end

  # A name that is not text is not the same as the text of it, so `host 5` and `host "5"` are not a repeat, and the
  # first is refused as a name that is not text, at its own line.
  def test_a_name_that_is_not_text_is_not_the_text_of_it
    assert_refused(
      "#{DEFAULTS}host 5 {\n  runner a\n}\nhost \"5\" {\n  runner b\n}\n",
      4,
      domain_said(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: 5, runners: %w[a]) }
    )
  end

  # Every name is read as its entry writes it, whatever the case of the other entries, and a host and a repository with
  # one name are two entries of different kinds, in any case.
  def test_names_keep_their_case_and_names_of_different_kinds_are_not_repeats
    text = "#{DEFAULTS}host Nuc {\n  runner Nuc-Linux\n}\nhost pc {\n  runner PC-wsl\n}\nrepository NUC #{REPO}"
    file = read(text)

    assert_equal(
      [%w[Nuc pc], [%w[Nuc-Linux], %w[PC-wsl]], %w[NUC]],
      [file.hosts.map(&:name), file.hosts.map(&:runners), file.repositories.map(&:name)]
    )
  end

  # Hosts that share no runner, and repositories that share no name, are read.
  def test_hosts_with_different_runners_are_read
    text = "#{DEFAULTS}host nuc {\n  runner a\n}\nhost pc {\n  runner b c\n}\n"

    assert_equal([%w[a], %w[b c]], read(text).hosts.map(&:runners))
  end
end

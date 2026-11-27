# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks which of the mistakes in the names across a pool file is refused when a file has several, and which entry
# the refusal names when more than one came before.
class PoolFileReaderNamesOrderTest < Minitest::Test
  include PoolFileReaderHelper

  DEFAULTS = "defaults {\n  budget \"1GB\"\n}\n"
  REPO = "url=\"u\" {\n  branch b\n  task t\n}\n"
  REPEATED_HOST = "a second host is named \"a\", and the first is on line 4. " \
    "Each host has one entry, so merge them into one"
  private_constant(:DEFAULTS, :REPO, :REPEATED_HOST)

  # Glossary, "runner": "One operating system on a host", so a runner on a third host is refused at that host's
  # runner, and the refusal names the host that lists it, not the first host of the file.
  def test_a_runner_on_a_later_host_names_the_host_that_lists_it
    assert_refused(
      "#{DEFAULTS}host nuc {\n  runner a\n}\nhost pc {\n  runner b\n}\nhost mac {\n  runner B\n}\n",
      11,
      "the runner \"B\" is also on the host \"pc\", whose entry starts on line 7. " \
        "A runner is one operating system on one host, so list it on one"
    )
  end

  # Names that are not text compare as KDL reads them, so text before a number with its digits is not a repeat, and
  # the number is refused as a name that is not text, at its own line.
  def test_text_before_a_name_that_is_not_text_is_not_a_repeat
    assert_refused(
      "#{DEFAULTS}host \"5\" {\n  runner a\n}\nhost 5 {\n  runner b\n}\n",
      7,
      domain_said(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: 5, runners: %w[b]) }
    )
  end

  # The domain's `Proof::PoolFile` refuses a second host before a runner on two hosts, and the reader refuses them in
  # that order, so a second host that repeats the first host's runner is refused as a second host.
  def test_a_second_host_is_refused_before_a_runner_on_two_hosts
    assert_refused("#{DEFAULTS}host a {\n  runner r\n}\nhost a {\n  runner r\n}\n", 7, REPEATED_HOST)
  end

  # The same order: a runner on two hosts is refused before a second repository, wherever each is in the file.
  def test_a_runner_on_two_hosts_is_refused_before_a_second_repository
    assert_refused(
      "repository lota #{REPO}repository lota #{REPO}#{DEFAULTS}host nuc {\n  runner r\n}\nhost pc {\n  runner r\n}\n",
      16,
      "the runner \"r\" is also on the host \"nuc\", whose entry starts on line 12. " \
        "A runner is one operating system on one host, so list it on one"
    )
  end
end

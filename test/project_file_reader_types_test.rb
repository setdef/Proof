# frozen_string_literal: true

require_relative("support/project_file_reader_helper")

# Checks the mistakes in a value: the wrong type, or an operating system, label, or size that breaks its rule.
class ProjectFileReaderTypesTest < Minitest::Test
  include ProjectFileReaderHelper

  # Project file reference, "Mistakes Proof catches": "a value has the wrong type, such as `cpus=\"four\"`".
  def test_cpus_that_is_text_is_refused
    assert_refused(
      "task a\ntask b cpus=\"four\"\n",
      2,
      domain_said(Proof::InvalidResourcesError) { Proof::Resources.request(cpus: "four", memory: "0MB") }
    )
  end

  # The same bullet, for `cpus` that is a decimal, which isn't a whole number, and for one that is `#null`.
  def test_cpus_that_is_not_a_whole_number_is_refused
    assert_refused(
      "task a cpus=1.5\n",
      1,
      domain_said(Proof::InvalidResourcesError) { Proof::Resources.request(cpus: 1.5, memory: "0MB") }
    )
    assert_refused(
      "task a cpus=#null\n",
      1,
      domain_said(Proof::InvalidResourcesError) { Proof::Resources.request(cpus: nil, memory: "0MB") }
    )
  end

  # The same bullet: the message names the project file's `cpus`, which a task requests from 1, and not a share's, which
  # the pool file keeps free from 0.
  def test_the_message_for_cpus_names_the_tasks_cpus
    assert_refused("task a cpus=2.5\n", 1, "cpus is a whole number from 1, not 2.5")
    assert_refused("defaults cpus=0\n", 1, "cpus is a whole number from 1, not 0")
  end

  # The same bullet, for `cpus` below 1, which the page's table calls "A whole number from 1".
  def test_cpus_of_zero_is_refused
    assert_refused(
      "task a cpus=0\n",
      1,
      domain_said(Proof::InvalidResourcesError) { Proof::Resources.request(cpus: 0, memory: "0MB") }
    )
  end

  # The same bullet, for `memory` that is a number and for `timeout` that is a number: each is "A quoted" value.
  def test_memory_and_timeout_that_are_numbers_are_refused
    assert_refused(
      "task a memory=8\n", 1, domain_said(Proof::InvalidResourcesError) { Proof::Resources.request(cpus: 1, memory: 8) }
    )
    assert_refused("task a timeout=45\n", 1, domain_said(Proof::InvalidTimeLimitError) { Proof::TimeLimit.read(45) })
  end

  # The same bullet, for a task's name and command that aren't text.
  def test_a_name_or_command_that_is_not_text_is_refused
    assert_refused(
      "task 5\n", 1, domain_said(Proof::InvalidTaskEntryError) { Proof::TaskEntry.new(name: 5) }
    )
    assert_refused(
      "task a 5\n", 1, domain_said(Proof::InvalidTaskEntryError) { Proof::TaskEntry.new(name: "a", command: 5) }
    )
  end

  # Project file reference, "Mistakes Proof catches": "an `os` node lists an operating system other than `linux`,
  # `macos`, or `windows`".
  def test_an_unknown_operating_system_is_refused
    assert_refused(
      "task a {\n  os linux beos\n}\n", 2, domain_said(Proof::InvalidOSError) { Proof::OS.new(name: "beos") }
    )
  end

  # The same bullet, for an operating system written in another case, which the page's list doesn't have.
  def test_an_operating_system_in_another_case_is_refused
    assert_refused(
      "defaults {\n  os Linux\n}\n",
      2,
      domain_said(Proof::InvalidOSError) { Proof::OS.new(name: "Linux") }
    )
  end

  # The same bullet, for an operating system that is a number.
  def test_an_operating_system_that_is_not_text_is_refused
    assert_refused("task a {\n  os 5\n}\n", 2, domain_said(Proof::InvalidOSError) { Proof::OS.new(name: 5) })
  end

  # Project file reference, "Mistakes Proof catches": "a `label` breaks the label rule", where the table refuses
  # `"nvidia gpu"`.
  def test_a_label_that_breaks_the_rule_is_refused
    assert_refused(
      "task a\ntask b {\n  label gpu \"nvidia gpu\"\n}\n",
      3,
      domain_said(Proof::InvalidLabelError) { Proof::Label.new(name: "nvidia gpu") }
    )
  end

  # The same bullet, for a label that is a number: "KDL needs quotes around a value that starts with a digit".
  def test_a_label_that_is_not_text_is_refused
    assert_refused("task a {\n  label 4\n}\n", 2, domain_said(Proof::InvalidLabelError) { Proof::Label.new(name: 4) })
  end

  # The same bullet: "or a size breaks the size rule", where the table refuses `"8G"`.
  def test_a_size_that_breaks_the_rule_is_refused
    assert_refused(
      "defaults memory=\"8G\"\n",
      1,
      domain_said(Proof::InvalidResourcesError) { Proof::Resources.request(cpus: 1, memory: "8G") }
    )
  end
end

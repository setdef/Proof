# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks the flags of `proof run`.
class CommandLineRunFlagsTest < Minitest::Test
  include CommandLineHelper

  # proof.usage.kdl: `proof run test` with no flags runs the task test and sets nothing else.
  def test_a_task_alone_runs_with_every_flag_at_its_default
    assert_equal(run_command([task("test")]), command("run", "test"))
  end

  # proof.usage.kdl: `flag "--os <os>" var=#true`: "repeat to run on several in parallel".
  def test_a_repeated_flag_collects_every_value_in_order
    assert_equal(
      run_command([task("test")], os: %w[linux windows]),
      command("run", "test", "--os", "linux", "--os", "windows")
    )
  end

  # proof.usage.kdl: `choices "linux" "macos" "windows" "any" "all"`, so `any` and `all` are values of `--os`.
  def test_os_takes_any_and_all
    assert_equal(run_command([task("test")], os: %w[any all]), command("run", "test", "--os=any", "--os", "all"))
  end

  # proof.usage.kdl: `choices strict=#false "gpu" ...`: a label that isn't listed is still a label.
  def test_label_takes_a_value_the_spec_does_not_list
    assert_equal(
      run_command([task("test")], label: %w[gpu hdr]),
      command("run", "test", "--label", "gpu", "--label", "hdr")
    )
  end

  # proof.usage.kdl: the flags that name the code, the project, and the resources, each with one value.
  def test_the_flags_with_one_value_keep_it_as_typed
    words = %w[run test --commit HEAD -C folder --cpus 2 --memory 8GB --timeout 30m]

    assert_equal(
      run_command([task("test")], commit: "HEAD", project: "folder", cpus: "2", memory: "8GB", timeout: "30m"),
      command(*words)
    )
  end

  # proof.usage.kdl: usage reads each letter after `-C` as a flag, so `-Cd folder` is `-C -d folder`.
  def test_a_short_flag_that_takes_a_value_leaves_it_the_next_word_after_the_flags_written_with_it
    assert_equal(run_command([task("test")], project: "folder"), command("run", "test", "-Cd", "folder"))
    assert(global("run", "test", "-Cd", "folder").debug)
  end

  # proof.usage.kdl: `--empty`, `--download`, `--detach`, and `--json` are yes-or-no flags.
  def test_the_yes_or_no_flags_are_true_when_given
    assert_equal(
      run_command([task("test")], empty: true, download: true, detach: true, json: true),
      command("run", "test", "--empty", "--download", "--detach", "--json")
    )
  end

  # proof.usage.kdl: `--keep`, `--input`, and `--input-file` are `var=#true`, and `-o --output` goes with `--download`.
  def test_the_flags_about_artifacts_collect_their_values
    words = %w[run build --keep a --keep b --input m3d8q --input-file f --download -o dist]

    assert_equal(
      run_command([task("build")], keep: %w[a b], input: ["m3d8q"], input_file: ["f"], download: true, output: "dist"),
      command(*words)
    )
  end

  # proof.usage.kdl: `--script <file>` "give - to read it from standard input".
  def test_a_script_runs_with_no_task
    assert_equal(run_command([], script: "-"), command("run", "--script", "-"))
  end

  # proof.usage.kdl: the long help, "Proof's flags work anywhere before `--`".
  def test_the_flags_work_before_and_after_the_task
    assert_equal(command("run", "--os", "linux", "test"), command("run", "test", "--os", "linux"))
  end

  # A flag given twice with a value each time keeps the last, as a shell alias plus a typed flag would.
  def test_a_flag_that_does_not_repeat_keeps_its_last_value
    assert_equal("b", command("run", "test", "--commit", "a", "--commit", "b").commit)
  end

  # Flags written one letter at a time and together mean the same.
  def test_short_flags_may_be_written_together
    assert_equal(global("-qd", "status"), global("-q", "-d", "status"))
  end

  # usage binds the value of a flag in a cluster that ends in a flag with a value to the next word.
  def test_a_short_flag_with_a_value_may_end_a_cluster
    assert_equal(run_command([task("test")], project: "folder"), command("run", "test", "-dC", "folder"))
  end
end

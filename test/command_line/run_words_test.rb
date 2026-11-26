# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks which words of `proof run` go to which task.
class CommandLineRunWordsTest < Minitest::Test
  include CommandLineHelper

  # proof.usage.kdl: "The words for the task follow `--`".
  def test_the_words_after_the_dashes_go_to_the_task_as_they_are
    assert_equal([task("test", "--seed", "1234")], command("run", "test", "--", "--seed", "1234").tasks)
  end

  # architecture.md: "A plain word before `--`, as in `proof run test foo`, goes to the task".
  def test_a_plain_word_before_the_dashes_goes_to_the_task
    assert_equal([task("test", "foo", "--bar")], command("run", "test", "foo", "--", "--bar").tasks)
  end

  # proof.usage.kdl: Proof's flags work anywhere before `--`, and nothing after it is one.
  def test_a_proof_flag_after_the_dashes_is_a_word_for_the_task
    assert_equal([task("test", "--os", "linux")], command("run", "test", "--", "--os", "linux").tasks)
  end

  # proof.usage.kdl: `example "proof run lint ::: test"`: "Run two tasks in one run, as mise runs them".
  def test_the_marker_starts_the_next_task
    assert_equal([task("lint"), task("test")], command("run", "lint", ":::", "test").tasks)
  end

  # proof.usage.kdl: `example "proof run lint -- --fix ::: test -- --seed 1234"`: "Give two tasks different words".
  def test_each_task_has_its_own_words_after_its_own_dashes
    assert_equal(
      [task("lint", "--fix"), task("test", "--seed", "1234")],
      command("run", "lint", "--", "--fix", ":::", "test", "--", "--seed", "1234").tasks
    )
  end

  # proof.usage.kdl: "`:::` starts the next task, before or after `--`".
  def test_the_marker_works_before_the_dashes_too
    assert_equal([task("lint"), task("test", "x")], command("run", "lint", ":::", "test", "--", "x").tasks)
  end

  # command.md, tasks after `:::`: a second `--` after a name is a separator, and a later one is a word.
  def test_a_dashes_after_a_name_separates_and_a_later_one_is_a_word
    assert_equal(
      [task("lint", "a"), task("test", "b", "--", "c")],
      command("run", "lint", "--", "a", ":::", "test", "--", "b", "--", "c").tasks
    )
  end

  # A `--` after the first task's words is one of them, as `cargo run` passes it on.
  def test_a_second_dashes_in_the_first_tasks_words_is_a_word
    assert_equal([task("test", "a", "--", "b")], command("run", "test", "--", "a", "--", "b").tasks)
  end

  # The first word after `--` is the task when none came before it.
  def test_the_first_word_after_the_dashes_is_the_task_when_none_came_before
    assert_equal([task("test", "x")], command("run", "--", "test", "--", "x").tasks)
  end

  # `--` with nothing after it gives the task no words.
  def test_dashes_with_nothing_after_give_no_words
    assert_equal([task("test")], command("run", "test", "--").tasks)
  end

  # proof.usage.kdl: the group `what` takes a task or `--script`, so a script has no tasks.
  def test_a_script_has_no_tasks
    assert_empty(command("run", "--script", "f").tasks)
  end
end

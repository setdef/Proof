# frozen_string_literal: true

require_relative("../test_helper")
require "json"
require "tmpdir"

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../../tasks/doc_examples/child")

# Checks how the child runs blocks and judges what they do.
class DocExamplesChildTest < Minitest::Test
  # A child with a scope of its own, so a block can't touch this test.
  def child
    DocExamples::Child.new(Object.new.instance_eval { binding })
  end

  def entry(code, raises: nil, line: 5)
    { path: "doc/a.md", line:, code:, raises: }
  end

  def test_a_block_that_raises_nothing_has_no_failures
    assert_empty(child.run([entry("1 + 1\n")]))
  end

  def test_a_variable_one_block_sets_is_there_for_the_next
    assert_empty(child.run([entry("x = 5\n"), entry("raise 'no' unless x == 5\n")]))
  end

  def test_a_block_that_raises_fails_at_the_line_of_the_code_that_raised
    failures = child.run([entry("a = 1\nb = 2\nraise ArgumentError, 'bad'\n", line: 10)])

    assert_equal(["doc/a.md:12: raised ArgumentError: bad"], failures)
  end

  def test_an_error_that_does_not_say_where_it_came_from_fails_at_the_first_line_of_the_block
    failures = child.run([entry("e = RuntimeError.new('bad')\ne.set_backtrace([])\nraise e\n", line: 10)])

    assert_equal(["doc/a.md:10: raised RuntimeError: bad"], failures)
  end

  def test_a_block_that_exits_fails_instead_of_ending_the_child
    assert_equal(["doc/a.md:5: raised SystemExit: exit"], child.run([entry("exit\n")]))
  end

  def test_the_blocks_after_a_failing_block_still_run
    failures = child.run([entry("raise 'one'\n"), entry("raise 'two'\n", line: 9)])

    assert_equal(["doc/a.md:5: raised RuntimeError: one", "doc/a.md:9: raised RuntimeError: two"], failures)
  end

  def test_a_block_marked_to_raise_passes_when_it_raises_that_error_or_a_subclass
    assert_empty(child.run([entry("1 / 0\n", raises: "ZeroDivisionError")]))
    assert_empty(child.run([entry("1 / 0\n", raises: "StandardError")]))
  end

  def test_a_block_marked_to_raise_fails_when_it_raises_nothing
    failures = child.run([entry("1 + 1\n", raises: "ZeroDivisionError")])

    assert_equal(["doc/a.md:5: expected ZeroDivisionError to be raised, but nothing was"], failures)
  end

  def test_a_block_marked_to_raise_fails_when_it_raises_another_error
    failures = child.run([entry("\nraise ArgumentError, 'bad'\n", raises: "ZeroDivisionError")])

    assert_equal(["doc/a.md:6: expected ZeroDivisionError to be raised, but ArgumentError was: bad"], failures)
  end

  def test_a_block_marked_to_raise_something_that_is_no_error_fails
    %w[Nope String Kernel].each do |name|
      assert_equal(["doc/a.md:5: `#{name}` is not an error class"], child.run([entry("1\n", raises: name)]))
    end
    assert_equal(["doc/a.md:5: `` is not an error class"], child.run([entry("1\n", raises: "")]))
  end

  def test_a_value_must_be_equal_and_print_the_same
    refute_empty(child.run([entry("#{DocExamples::Child::LOCAL}.check(1.0, '1', 'where')\n")]))
    refute_empty(child.run([entry("#{DocExamples::Child::LOCAL}.check({a: 1, b: 2}, '{b: 2, a: 1}', 'where')\n")]))
    assert_empty(child.run([entry("#{DocExamples::Child::LOCAL}.check({a: 1, b: 2}, '{a: 1, b: 2}', 'where')\n")]))
  end

  def test_a_check_returns_the_value_it_was_given
    assert_equal(:value, child.check(:value, ":value", "where"))
  end

  def test_a_value_the_comparison_cannot_make_fails_the_check_and_not_the_child
    odd = Object.new
    def odd.==(_other)
      raise(ArgumentError, "no")
    end
    scope = Object.new.instance_eval { binding }
    runner = DocExamples::Child.new(scope)
    scope.local_variable_set(:odd, odd)
    runner.check(odd, "odd", "where")

    assert_equal(["where: can't read odd as a Ruby value: no"], runner.run([]))
  end

  def test_main_runs_the_blocks_in_a_file_and_writes_the_failures_to_another
    Dir.mktmpdir do |dir|
      blocks = File.join(dir, "blocks.json")
      results = File.join(dir, "results.json")
      File.write(blocks, JSON.generate([entry("raise 'bad'\n")]))
      DocExamples::Child.main([blocks, results], scope: Object.new.instance_eval { binding })

      assert_equal(["doc/a.md:5: raised RuntimeError: bad"], JSON.parse(File.read(results)))
    end
  end
end

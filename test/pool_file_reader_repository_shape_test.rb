# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the shape of a `repository` node: its arguments, its property, and its children.
class PoolFileReaderRepositoryShapeTest < Minitest::Test
  include PoolFileReaderHelper

  USAGE = "repository lota url=\"https://github.com/setdef/Lota.git\" { branch trunk; task test }"
  CHILDREN = "Its children are credentials-file, branch, task, and poll"
  BODY = "{\n  branch trunk\n  task test\n"
  UNKNOWN = [
    [
      "repository a url=\"u\" {\n  branch trunk\n  task test\n  url \"v\"\n}\n",
      4,
      "a \"repository\" node has no child \"url\". #{CHILDREN}",
    ],
    [
      "repository a url=\"u\" tag=\"v\" #{BODY}}\n",
      1,
      "a \"repository\" node has no property \"tag\". Its properties are url",
    ],
    [
      "repository a url=\"u\" branch=\"trunk\" #{BODY}}\n",
      1,
      "\"branch\" is a child node, not a property. Put it in the node's block, with every value as an argument",
    ],
  ].freeze
  TAKES = "a \"repository\" node takes one argument, as in #{USAGE}, and this one has".freeze
  NAMES = [
    ["repository url=\"u\" #{BODY}}\n", 1, "#{TAKES} 0"],
    ["repository a b url=\"u\" #{BODY}}\n", 1, "#{TAKES} 2"],
  ].freeze
  MISSING = [
    ["repository a #{BODY}}\n", 1, "a \"repository\" node needs the property \"url\""],
    ["repository a url=\"u\" {\n  task test\n}\n", 1, "a \"repository\" node needs a \"branch\" child"],
    ["repository a url=\"u\" {\n  branch trunk\n}\n", 1, "a \"repository\" node needs a \"task\" child"],
  ].freeze
  private_constant(:USAGE, :CHILDREN, :BODY, :UNKNOWN, :TAKES, :NAMES, :MISSING)

  # Project file reference, "Mistakes Proof catches", which the pool file reference points to: "a node or property
  # isn't one this page lists", for a child, and for a property of `repository`, which has `url` as a property and
  # not a child.
  def test_an_unknown_child_or_property_is_refused
    assert_refusals(UNKNOWN)
  end

  # Pool file reference, "`repository`": `repository NAME url="URL"` has one argument, its name, so none or two are
  # refused.
  def test_a_repository_with_no_name_or_two_names_is_refused
    assert_refusals(NAMES)
  end

  # Pool file reference, "`repository`", table: `url` is "Required", `branch` is "Required", and `task` is "Required".
  def test_a_url_a_branch_and_a_task_are_required
    assert_refusals(MISSING)
  end

  # Issue #52, "a child node given twice": refused, for `branch`, `credentials-file`, and `poll`, and not for `task`.
  def test_a_branch_a_credentials_file_and_a_poll_given_twice_are_refused
    [["branch", 4, 2], ["credentials-file", 5, 4], ["poll", 5, 4]].each do |name, line, first|
      assert_refused(
        "repository a url=\"u\" #{BODY}  #{name} x\n  #{name} y\n}\n",
        line,
        "\"#{name}\" is given twice, and the first is on line #{first}. " \
          "Give every value as arguments to one \"#{name}\" node"
      )
    end
  end

  # Issue #52, "a child node with no arguments": refused, for each child of `repository` that takes one or more.
  def test_a_child_with_no_arguments_is_refused
    assert_refused(
      "repository a url=\"u\" {\n  branch\n  task test\n}\n",
      2,
      "a \"branch\" node takes one or more arguments, as in branch trunk release, and this one has 0"
    )
  end

  # `credentials-file "PATH"` and `poll "DURATION"` take one argument, so two are refused.
  def test_a_credentials_file_or_a_poll_with_two_arguments_is_refused
    assert_refused(
      "repository a url=\"u\" #{BODY}  poll \"1m\" \"2m\"\n}\n",
      4,
      "a \"poll\" node takes one argument, as in poll \"1m\", and this one has 2"
    )
  end
end

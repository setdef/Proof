# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the number of arguments of each child of a pool file's nodes, which the page's forms show.
class PoolFileReaderArgumentsTest < Minitest::Test
  include PoolFileReaderHelper

  HOST = "defaults {\n  budget \"1GB\"\n}\nhost a {\n  runner r\n"
  REPOSITORY = "repository a url=\"u\" {\n  branch trunk\n  task test\n"
  ONE = "one argument"
  MANY = "one or more arguments"
  # Each is a text, the line it is refused at, and the child with what it takes, how to write it, and how many it has.
  MISTAKES = [
    ["defaults {\n  budget \"1GB\" \"2GB\"\n}\n", 2, ["budget", ONE, "budget \"100GB\"", 2]],
    ["defaults {\n  keep-free\n}\n", 2, ["keep-free", ONE, "keep-free \"25GB\"", 0]],
    ["defaults {\n  active-for \"5m\" \"6m\"\n}\n", 2, ["active-for", ONE, "active-for \"5m\"", 2]],
    ["#{HOST}  runner\n}\n", 6, ["runner", MANY, "runner nuc-linux", 0]],
    ["#{HOST}  withhold\n}\n", 6, ["withhold", MANY, "withhold gpu desktop", 0]],
    ["#{REPOSITORY}  poll \"1m\" \"2m\"\n}\n", 4, ["poll", ONE, "poll \"1m\"", 2]],
    [
      "#{REPOSITORY}  credentials-file \"a\" \"b\"\n}\n",
      4,
      ["credentials-file", ONE, "credentials-file \"~/.config/proof/credentials/lota\"", 2],
    ],
    ["repository a url=\"u\" {\n  branch\n  task test\n}\n", 2, ["branch", MANY, "branch trunk release", 0]],
    ["repository a url=\"u\" {\n  branch trunk\n  task\n}\n", 3, ["task", MANY, "task test package", 0]],
  ].freeze
  private_constant(:HOST, :REPOSITORY, :ONE, :MANY, :MISTAKES)

  # Pool file reference, "`host`" and "`repository`": a child's form shows how many arguments it has, `budget "SIZE"`
  # and `poll "DURATION"` one, `runner RUNNER...` and `task TASK...` one or more, so a child with another number is
  # refused at its own line, with the form that works. A second path in `credentials-file` is refused, not ignored.
  def test_a_child_with_a_number_of_arguments_its_form_does_not_show_is_refused
    MISTAKES.each do |text, line, (name, takes, usage, count)|
      assert_refused(text, line, "a #{name.inspect} node takes #{takes}, as in #{usage}, and this one has #{count}")
    end
  end
end

# frozen_string_literal: true

require "json"
require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "usage"

# A spec of a small program, `todo`, as `usage generate json` would write it with the keys the tests need, and short
# names for reading it.
module UsageTestHelper
  TODO = <<~JSON
    {
      "bin": "todo",
      "about": "Keep a list of things to do",
      "about_long": "Keeps the list in a file of its own.\\n\\nEach item has a number.",
      "after_help_long": "Report a problem: https://example.com/todo/issues",
      "examples": [{"code": "todo list", "help": "Lists every item."}],
      "exit_codes": [{"code": 0, "help": "It worked."}, {"code": 2, "help": "A mistake."}],
      "unknown_env": {"prefix": "TODO_", "allow": ["TODO_HOME"]},
      "cmd": {
        "name": "todo",
        "full_cmd": [],
        "flags": [
          {"name": "quiet", "short": ["q"], "long": ["quiet"], "global": true, "help": "Print less"},
          {"name": "debug", "short": ["d"], "long": ["debug"], "global": true}
        ],
        "subcommands": {
          "add": {
            "name": "add",
            "full_cmd": ["add"],
            "help": "Add an item",
            "args": [{"name": "text", "help": "What to do"}],
            "flags": [
              {"name": "tag", "long": ["tag"], "var": true, "help": "Tag the item",
               "arg": {"name": "tag", "choices": {"choices": ["home", "work"], "strict": false}}},
              {"name": "file", "short": ["f"], "long": ["file"], "arg": {"name": "path"}}
            ],
            "groups": [{"name": "source", "members": ["text", "--file"], "required": true}],
            "examples": [{"code": "todo add 'Buy milk' --tag home", "header": "Add an item with a tag"}]
          },
          "list": {
            "name": "list",
            "full_cmd": ["list"],
            "help": "List the items",
            "flags": [
              {"name": "sort", "long": ["sort"], "help": "Sort by this",
               "arg": {"name": "key", "choices": {"choices": ["due", "added"]}}},
              {"name": "json", "long": ["json"], "help": "Print JSON"},
              {"name": "output", "short": ["o"], "long": ["output"], "arg": {"name": "file"}, "requires": ["--json"]}
            ]
          },
          "done": {
            "name": "done",
            "full_cmd": ["done"],
            "help": "Mark items done",
            "args": [{"name": "item", "required": true, "var": true, "help": "The items, by number"}]
          },
          "remote": {
            "name": "remote",
            "full_cmd": ["remote"],
            "help": "Share the list",
            "subcommand_required": true,
            "flags": [
              {"name": "dry-run", "short": ["n"], "long": ["dry-run"], "global": true, "help": "Change nothing"}
            ],
            "subcommands": {
              "add": {"name": "add", "full_cmd": ["remote", "add"], "args": [{"name": "url", "required": true}]},
              "remove": {"name": "remove", "full_cmd": ["remote", "remove"]}
            }
          }
        }
      }
    }
  JSON
  public_constant(:TODO)

  # The spec that +text+, JSON as usage writes it, holds.
  def read(text)
    Usage::Spec.read(text)
  end

  # The `todo` spec.
  def todo
    read(TODO)
  end

  # What the `todo` spec reads +words+, the words after `todo`, as, by +value_rules+.
  def parse(*words, value_rules: Usage::UsageValueRules)
    Usage::Parser.new(todo, value_rules:).parse(words)
  end

  # The message of the mistake that the `todo` spec finds in +words+.
  def mistake(*words, value_rules: Usage::UsageValueRules)
    assert_raises(Usage::CommandLineError) { parse(*words, value_rules:) }
      .message
  end

  # The message of the error that reading +text+ raises.
  def refusal(text)
    assert_raises(Usage::SpecError) { read(text) }
      .message
  end
end

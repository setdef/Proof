# usage-rb

Read the [usage](https://usage.jdx.dev) spec that describes a Ruby program's command line, and print its help from it.

A usage spec describes a program's commands, flags, and arguments once, in KDL, and usage generates the program's reference, man pages, and shell completions from it. usage-rb reads the JSON that `usage generate json` writes from the spec, with no dependencies beyond Ruby's standard library.

It is designed to grow toward the whole of usage's spec. It reads only what it acts on, and refuses a spec that uses anything else when it reads it, naming what the spec uses, so a spec it accepts means what it says.

## Installing

usage-rb needs Ruby 4.1 or later. It isn't on RubyGems. It lives in [Proof](https://github.com/setdef/Proof)'s repository, under `gems/usage-rb`, while its design settles, and is meant to move to a repository apart from Proof's afterward. Until then, add it to a Gemfile by its path: `gem "usage-rb", path: "gems/usage-rb"`.

## Reading a spec

```ruby
require "usage"

spec = Usage::Spec.read(<<~JSON)
  {"bin": "todo", "about": "Keep a list of things to do",
   "cmd": {"subcommands": {"add": {"name": "add", "full_cmd": ["add"], "help": "Add an item",
                                   "args": [{"name": "text", "required": true}]}}}}
JSON
spec.commands.find(["add"]).help # => "Add an item"
```

`Usage::Spec.read` raises `Usage::SpecError` for a spec it can't act on in full:

```ruby
require "usage"

begin
  Usage::Spec.read('{"cmd": {"aliases": ["a"]}}')
rescue Usage::SpecError => e
  e.message # => "the program sets aliases to [\"a\"], which usage-rb doesn't support"
end
```

### What it reads

- The program: `bin`, `about`, `long_about`, `after_long_help`, examples, exit codes, and `unknown_env`.
- Each command: its help and long help, subcommands, `subcommand_required`, arguments (`required` and `var`), groups, and examples.
- Each flag: its short and long names, help and long help, a value that is required, with `choices` (strict or not), `requires`, `var` with a value, and `global`.
- `unknown_flags "error"`, with the program treating a flag it doesn't know as a mistake.

It accepts and ignores `name`, `version`, `author`, `license`, and `repository` of the program, and `effect` of a command, because they describe the documents usage writes and change nothing it does.

### What it refuses

A spec that uses any other part of usage's spec is refused, naming the part. Among them are command aliases, hidden commands, flags, and arguments, `default`, `env`, `negate`, `count`, `required`, and `deprecated` of a flag, `default`, `env`, and `choices` of an argument, a flag value that may be left out, `var` on a flag with no value, configuration files, completions, `mount`, `restart_token`, `default_subcommand`, any `unknown_flags` but `"error"`, a `min_usage_version` newer than usage 7.4.1, whose specs it reads, and a command with both arguments and subcommands.

## Printing help

`Usage::Help#text` writes the help of the command at a path, or of the program for an empty path:

```ruby
require "usage"

spec = Usage::Spec.read(<<~JSON)
  {"bin": "todo", "about": "Keep a list of things to do",
   "cmd": {"subcommands": {"add": {"name": "add", "full_cmd": ["add"], "help": "Add an item",
                                   "args": [{"name": "text", "required": true, "help": "What to do"}]}}}}
JSON
Usage::Help.new(spec).text(["add"]).lines.first # => "todo add - Add an item\n"
```

## Documentation

The API reference is the RDoc in the `.rbs` files of the `sig` folder.

## Reporting problems

Report a problem in [Proof's forum category](https://forum.setdef.com/c/proof).

## License

usage-rb is released under the [MIT License](LICENSE).

## How this was made

I use four words for how code and prose comes to exist. Code or prose I wrote, I typed by hand, with nothing generated. Code or prose I wrought, an AI agent generated while I iterated with it, and I reviewed every change before committing it, so I own every diff. Code or prose I requested, an agent built with little or no review from me, but I take ownership of the outcome or product because I tested and iterated. Code or prose I rushed, an agent built with little or no feedback from me, and may or may not be useful (or safe).

usage-rb's code, tests, and documentation are requested. In place of review, the project's rules require every line of Ruby to be covered by tests meant to stand up to mutation testing, and a check of each change before its push. [declare-ai.org](https://declare-ai.org/1.0.0/total.html)

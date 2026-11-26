# usage-rb

Read the [usage](https://usage.jdx.dev) spec that describes a Ruby program's command line.

A usage spec describes a program's commands, flags, and arguments once, in KDL, and usage generates the program's reference, man pages, and shell completions from it. usage-rb reads the JSON that `usage generate json` writes from the spec, with no dependencies beyond Ruby's standard library.

It is designed to grow toward the whole of usage's spec. It reads only what it acts on, and refuses a spec that uses anything else when it reads it, naming what the spec uses, so a spec it accepts means what it says.

usage-rb lives in [Proof](https://github.com/setdef/Proof)'s repository, under `gems/usage-rb`, while its design settles, and is meant to move to a repository of its own afterward. It isn't on RubyGems.

## Reading a spec

```ruby
require "usage"

spec = Usage::Spec.read(<<~JSON)
  {"bin": "todo", "about": "Keep a list of things to do",
   "cmd": {"subcommands": {"add": {"name": "add", "full_cmd": ["add"], "help": "Add an item",
                                   "args": [{"name": "text", "required": true}]}}}}
JSON
spec.command(["add"]).help # => "Add an item"
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

## License

usage-rb is released under the [MIT License](LICENSE).

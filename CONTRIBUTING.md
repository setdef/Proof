# Contributing

This page shows how to set up a computer to work on Proof, run the checks a change has to pass, and regenerate the CLI reference when you change the CLI. It is for people who change Proof's code or docs; to use Proof on a project, start with the [README](README.md).

[AGENTS.md](AGENTS.md) holds the rules every change follows, whether a person or a coding agent writes it: what Proof is for, the decisions not to work against, and the standards for Ruby, tests, and commits. Read it before your first change.

## Set up

Proof is developed on the Ruby that Fledge's apps carry, which [mise](https://mise.jdx.dev/) installs from `mise.toml` along with the other tools the checks use. The checks run on Linux and macOS; Windows isn't set up yet.

1. Install [mise](https://mise.jdx.dev/getting-started.html).
2. From a clone of the repository, install the tools, then the gems:

   ```console
   $ mise install
   $ bundle install
   ```

   `mise install` installs Ruby 4.1.0-preview1 and the other tools `mise.toml` pins. If your shell doesn't activate mise, run each command through `mise exec --`, as in `mise exec -- bundle install`.

## Run the checks

Run all of them before every commit:

```console
$ bundle exec rake
```

The command exits 0 when every check passes, with no errors and no warnings. It runs:

| Check | What fails it |
| --- | --- |
| Tests | A failing test, or a line or branch no test runs (SimpleCov's minimum is 100% for each file) |
| RuboCop | Any offense, with every cop on |
| Steep | A type error, or `untyped` in a `.rbs` file |
| RubyCritic | A file rated below A, a smell (from reek), duplication (from flay), or an overall score below 95. The failure names each file, its rating, and each smell |
| REUSE | A file that `REUSE.toml` gives no copyright or license |
| RDoc coverage | A public class, module, constant, or method with no documentation |
| CLI spec | `usage lint` finding a fault, or a generated reference that differs from the spec |

Run one check while you work: `bundle exec rake test:ruby`, `rubocop`, `steep`, `rubycritic`, `reuse:lint`, `rdoc:coverage`, `usage:lint`, or `usage:references`. `bundle exec rake lint:fix` corrects the RuboCop offenses it can.

Tests never reach the internet. Use local fakes.

## Regenerate the CLI reference

The CLI reference is generated from [`proof.usage.kdl`](proof.usage.kdl), and two pages hold it: `doc/reference/cli.md` and `skills/proof/references/cli.md`. After you change the spec, regenerate both:

```console
$ usage generate markdown --file proof.usage.kdl --out-file doc/reference/cli.md
$ usage generate markdown --file proof.usage.kdl --out-file skills/proof/references/cli.md
```

Never edit either page by hand. If one differs from what the spec generates, `bundle exec rake usage:references` fails and prints these two commands.

## Write the change

- Documentation follows [the style guide](doc/contributors/style-guide.md), and RDoc comments in Ruby files follow [the documentation style guide](doc/contributors/documentation_style.md).
- Use the words in [the glossary](doc/glossary.md).
- What Proof builds next, and what 1.0 leaves out, is in [the plan](doc/contributors/plan.md).
- To propose a change, open an [issue](https://github.com/setdef/Proof/issues) that describes it, or a pull request with the change and its tests.

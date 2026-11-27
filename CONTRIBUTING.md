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

Run all of them before every push, with `BUNDLE_PATH` set to a folder outside the repository, where RuboCop and REUSE won't read the gems:

```console
$ BUNDLE_PATH=$HOME/.cache/proof-bundle bin/ci
```

`bin/ci` refuses a `BUNDLE_PATH` that is unset or inside the repository. It runs `mise exec -- bundle exec rake` at a low priority, with half as many test processes as the computer has processors (set `PARALLEL_TEST_PROCESSORS` to change that). Rake starts every check at once and exits 0 when every check passes, with no errors and no warnings. CI runs the same checks with `bundle exec rake` on Linux and macOS for every commit on the trunk. The checks are:

| Check | What fails it |
| --- | --- |
| Tests | A failing test, or a line or branch no test runs (SimpleCov's minimum is 100% for each file) |
| RuboCop | Any offense, with every cop on |
| Steep | A type error, or `untyped` in a `.rbs` file |
| RubyCritic | A file rated below A, a smell (from reek), duplication (from flay), or an overall score below 95. The failure names each file, its rating, and each smell |
| REUSE | A file that `REUSE.toml` gives no copyright or license |
| RDoc coverage | A public class, module, constant, or method with no documentation, counting the comments in `sig/**/*.rbs` |
| Comment placement | A comment in `lib/` directly above a `def`, `class`, or `module`, where RDoc would take it as documentation |
| Documentation examples | A Ruby example in a Markdown page or an `.rbs` comment that raises, or shows a wrong `# =>` value. The failure shows the file and line |
| CLI spec | `usage lint` finding a fault, or a file generated from the spec that differs from it |

Run one check while you work: `bundle exec rake -T` lists them with what each one checks. `bundle exec rake lint:fix` corrects the RuboCop offenses it can.

Tests never reach the internet. Use local fakes.

## Regenerate the files made from the CLI spec

Three files are generated from [`proof.usage.kdl`](proof.usage.kdl): the CLI reference in two pages, `doc/reference/cli.md` and `skills/proof/references/cli.md`, and `lib/proof/command_line/spec.json`, which the command line reads to print help. After you change the spec, regenerate all three:

```console
$ usage generate markdown --file proof.usage.kdl --out-file doc/reference/cli.md
$ usage generate markdown --file proof.usage.kdl --out-file skills/proof/references/cli.md
$ usage generate json --file proof.usage.kdl > lib/proof/command_line/spec.json
```

Never edit these files by hand. If one differs from what the spec generates, `bundle exec rake usage:references` fails and prints these three commands.

## Write the change

- Documentation follows [the style guide](doc/contributors/style-guide.md), and the API documentation in `sig/**/*.rbs` follows [the documentation style guide](doc/contributors/documentation_style.md).
- Use the words in [the glossary](doc/glossary.md).
- What Proof builds next, and what 1.0 leaves out, is in [the plan](doc/contributors/plan.md).
- To propose a change, open an [issue](https://github.com/setdef/Proof/issues) that describes it, or a pull request with the change and its tests.

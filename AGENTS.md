# AGENTS.md

## The Tao of Proof

Proof serves three values. Never serve one by spending another.

1. Get the work off the computer the developer works at: no hammered CPU or memory, no windows on their screen.
2. Run the work where the developer can't: other operating systems, GPUs, desktops, emulators, Simulators.
3. Be CI for trunk-based development, before and after the push, answering sooner than pushing and polling would.

- Leave every host usable by the person working or gaming at it.
- Never report a pass that didn't happen.

Why these pull against each other, and how Proof balances them: `doc/how-proof-works.md`, "Three values in balance".

For working on Proof itself. To use Proof on another project, read `skills/proof/SKILL.md`.

What to build next, what 1.0 leaves out, and what is undecided: `doc/contributors/plan.md`.

How Proof is built, with the libraries and layout and the options each beat: `doc/contributors/architecture.md`.

## Commands

- The gate, before every push: `bin/ci`, with `BUNDLE_PATH` pointing outside the repository, where RuboCop and REUSE won't read the gems. `bin/ci` refuses a `BUNDLE_PATH` that is unset or inside the repository, then runs these checks at once through `nice mise exec -- bundle exec rake`, with half as many processes as the computer has processors, for the tests and for the documentation examples alike (`PARALLEL_TEST_PROCESSORS` overrides that), so the computer stays usable. The checks are the tests, in parallel processes, with 100% line and branch coverage of the whole suite, RuboCop with every cop on, Steep, RubyCritic, REUSE, RDoc coverage, the comment-placement check, the Ruby examples in the docs, the CLI spec's lint, the check that the three files generated from it match it, and a frozen `bundle install`. It must pass with zero errors and zero warnings. CI runs the same checks with `bundle exec rake` on Linux and macOS for every trunk commit.
- RubyCritic's gate fails unless every file is rated A, reek and flay report no smells or duplication, and the overall score is at least 95. That floor may rise, never fall. `tasks/critic_faults.rb` reads RubyCritic's JSON report, because RubyCritic has no option that fails on a rating or a smell; its `--minimum-score` enforces the score.
- `rake -T` lists the single checks and what each one checks. Run one as `MISE_TRUSTED_CONFIG_PATHS=$PWD mise exec -- bundle exec rake steep`.
- Fix what a gate can fix: `rake lint:fix` corrects RuboCop offenses.
- Run Ruby as `bundle exec ruby`, never `ruby -Ilib:test`.
- `bin/setup` is for a person setting up a clone. Agents don't run it, or install any hook: it installs a pre-commit hook, and every worktree of a clone shares its hooks, so a hook one agent installs runs in every agent's worktree and in the owner's. Run `mise install` and `bundle install` instead.
- Set `PAGER=cat` for `git`.
- Lint the CLI spec: `usage lint proof.usage.kdl`
- After any change to `proof.usage.kdl`, regenerate the three files made from it:
  - `usage generate markdown --file proof.usage.kdl --out-file doc/reference/cli.md`
  - `usage generate markdown --file proof.usage.kdl --out-file skills/proof/references/cli.md`
  - `usage generate json --file proof.usage.kdl > lib/proof/command_line/spec.json`, which the command line reads to print help

## Decisions

- The docs are the specification. When code and docs disagree, change the code, or change both in one commit and say why.
- Use the words in `doc/glossary.md`, in code as in docs. A new idea gets a glossary entry before it gets a name.
- Don't work against `doc/contributors/decisions/`: no external scheduler, no transport but Git through the server, nothing connects to a runner, no root for runs. To change one, write a new record with the next number and delete the old one; never edit an accepted record.
- Each requirement in `doc/contributors/design/` becomes a test that fails when the requirement is broken.
- Ruby only, packaged with Fledge; native calls go through Fiddle, on every system (Fledge's runtimes ship it as a bundled gem; `Kernel#syscall` doesn't exist on macOS or Windows, and its call numbers differ between Linux processors). Another language needs a reason only it can meet, written in its design page.
- Reuse before you build. Before writing a parser, a checker, or a helper, look for reliable code that exists: the standard library, Ruby's bundled gems, maintained gems. Write new code only with a written reason.
- Copyright and licenses follow the [REUSE Specification](https://reuse.software/spec-3.3/). Proof's own files are under permissive licenses, `MIT` for code and configuration and `CC-BY-4.0` for documentation, so they carry no SPDX header: `REUSE.toml` declares their copyright and license. An SPDX header is only for content under a copyleft or share-alike license, and what comes from elsewhere is marked by how it came:
  - A file copied under a copyleft or share-alike license carries that license in its own SPDX header, and the license's text goes in `LICENSES/`.
  - A file copied under a permissive or public-domain license gets an annotation in `REUSE.toml` with its copyright and license, and no header.
  - Code ported from another project (an algorithm translated into Ruby, a table, a regex), as opposed to code only inspired by it, goes between `# SPDX-SnippetBegin` and `# SPDX-SnippetEnd` comments. Inside them, give the upstream license as `SPDX-License-Identifier`, the upstream copyright as `SPDX-SnippetCopyrightText`, and an `SPDX-SnippetComment` that names the upstream project and file and says what the port changed. The upstream license's text goes in `LICENSES/`.
- Every line of Ruby is covered by tests that would stand up to mutation testing, and each test checks specific behavior. No mutation-testing tool runs in the gate until one exists for Ruby.
- Value objects are `Data.define`, written `class Foo < Data.define(...)`, because RDoc skips the methods in a `Foo = Data.define(...) do` block and the coverage check never counts them; entities are classes.
- Type every class and method in `.rbs`, with no `untyped`. A `Data.define` subclass declares `class Foo < Data`, an `attr_reader` for each member, and `self.new` (and `self.[]` if used) with positional and keyword overloads, because `Data.new` returns `bot`.
- Write RDoc, not YARD, in the `.rbs` file, in Markdown, for every public class, module, constant, and method, following `doc/contributors/documentation_style.md`. That guide covers API documentation; `doc/contributors/style-guide.md` covers everything else.
- A comment in a `.rb` file says why the code is written as it is, or explains a tricky part. Put it inside the body, never directly above a `def`, `class`, or `module`: RDoc would take it as documentation. `rake docs:placement` fails on one that is.
- Every cop RuboCop has is on. Fix an offense; never write `rubocop:disable`. Turn a cop off in `.rubocop.yml` only for a reason written beside it.
- A one-off script that grows past a few lines is a temporary Rake task or `ruby -e`, not a long shell string.
- Commit straight to the trunk, one tested change at a time; run the checks before the push, not after. A commit message is one plain imperative line in sentence case with no prefix (not Conventional Commits), a blank line, and a short body saying why.
- Releases: bump the version in `lib/proof/version.rb`, tag it, and publish a GitHub release regularly, always as `0.X.Y`, never with a prerelease suffix such as `-rc.1` or `.pre.1`.
- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and lists only what people who use Proof see: new commands and flags, changed behavior, deprecations, removals. Its Unreleased section covers the time since the last tag, so a commit that undoes an earlier unreleased one removes that entry. Past versions stay as they are.

## Writing things down

Record these where the next contributor will find it. (What lives only in a chat, or on one machine, gets lost.) Write each thing in its axis's home, and nowhere else:

| Axis | As it is | As it will be |
| - | - | - |
| Requirements: what the software does for its users | User documentation† | Issues |
| Contract: what a caller can rely on | Doc comments; the changelog, for changes over time | Issues |
| Architecture: the few decisions the structure rests on | Accepted ADRs | Proposed ADRs |
| Design: how each part works, and why | Design documents | Nowhere |
| Behavior: what the code does | Tests | Nowhere |
| Facts that constrain the design | The design document or ADR they constrain; until that exists, the issue whose work they constrain | Nowhere |

- **Decide a design at the last responsible moment,** while building it, with the facts in hand, then record it as it is. Never write a design, or a behavior, ahead of the code, in an issue or anywhere else.
- **A design document explains a part to the people who change it:** its concepts, how its pieces fit, why it is shaped this way, its traps, and what it deliberately doesn't do. It doesn't restate the code: no fields, option types, step-by-step restatements of the code, or private call graphs.
- **Change a design document when a design decision changes,** never because behavior did. The two vary independently.
- **A doc comment describes the contract from the caller's side,** never how the code does the work inside.
- **Check a fact at its source before anything rests on it,** on the platform it's about. A decision that rests on an unchecked fact waits.
- **Record a fact found before its design exists as a fact, not a decision:** what was spiked or checked, how, on which platform and version, and the result. It waits in the issue whose work it constrains. When the design or architecture is decided, the relevant facts go in that design document or ADR.
- **Issues may represent proposed or accepted** requirements or contracts, and an issue that doesn't specify which can't be assumed to have already been accepted or denied.
- † **In a project being built under README-Driven Development,** the user documentation is written ahead of the code, as its requirements. Everywhere else, it describes only what the software does today.

## Landmines

- `doc/reference/cli.md`, `skills/proof/references/cli.md`, and `lib/proof/command_line/spec.json` are generated. Never edit them by hand.
- A change to the CLI or to what agents should do changes `skills/proof/` in the same commit.
- `skills/proof/references/project-file.md` is a hand-written summary of `doc/reference/project-file.md`, not a copy. A change to the project file's format changes both in the same commit.
- Tests never reach the internet. Use local fakes.
- Never develop or test on a pool people use. Use virtual machines.
- Prove what a virtual machine can't show, such as a real GPU or a Windows desktop, on one real host only, in a window its owner agreed to beforehand.
- Root only inside a disposable virtual machine. Never hand a person a root command that hasn't run there.
- This repository is public: no names of anyone's computers or accounts, no private paths or pool records, no secrets, no quotes from conversations.
- Follow `doc/contributors/style-guide.md` for every page, every message Proof prints, and every commit message.

## Done

A change is done when it is on the trunk with all of these true:

- The gate passes, with zero errors and zero warnings.
- The RBS types are complete, the RDoc follows the style guide, and the docs, `skills/proof/`, and the glossary say what the code does now.
- `CHANGELOG.md`'s Unreleased section lists what people who use Proof will see.

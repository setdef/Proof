<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

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

## Commands

- The gate, before every commit: `MISE_TRUSTED_CONFIG_PATHS=$PWD mise exec -- bundle exec rake`, with `BUNDLE_PATH` pointing outside the repository, where RuboCop and REUSE won't read the gems. It runs the tests with 100% line and branch coverage, RuboCop with every cop on, Steep, RubyCritic, REUSE, RDoc coverage, the CLI spec's lint, and the check that both generated references match it. It must pass with zero errors and zero warnings.
- RubyCritic's gate fails unless every file is rated A, reek and flay report no smells or duplication, and the overall score is at least 95. That floor may rise, never fall. `tasks/critic_faults.rb` reads RubyCritic's JSON report, because RubyCritic has no option that fails on a rating or a smell; its `--minimum-score` enforces the score.
- One gate at a time: `rake test:ruby`, `rubocop`, `steep`, `rubycritic`, `reuse:lint`, `rdoc:coverage`, `usage:lint`, `usage:references`.
- Fix what a gate can fix: `rake lint:fix` corrects RuboCop offenses and adds missing SPDX headers.
- Run Ruby as `bundle exec ruby`, never `ruby -Ilib:test`.
- Don't run `bin/setup` or install a pre-commit hook: the hooks of a clone's worktrees are shared. Run `mise install` and `bundle install`.
- Set `PAGER=cat` for `git`.
- Lint the CLI spec: `usage lint proof.usage.kdl`
- After any change to `proof.usage.kdl`, regenerate both references:
  - `usage generate markdown --file proof.usage.kdl --out-file doc/reference/cli.md`
  - `usage generate markdown --file proof.usage.kdl --out-file skills/proof/references/cli.md`

## Decisions

- The docs are the specification. When code and docs disagree, change the code, or change both in one commit and say why.
- Use the words in `doc/glossary.md`, in code as in docs. A new idea gets a glossary entry before it gets a name.
- Don't work against `doc/contributors/decisions/`: no external scheduler, no transport but Git through the server, nothing connects to a runner, no root for runs. To change one, write a new record with the next number and delete the old one; never edit an accepted record.
- Each requirement in `doc/contributors/design/` becomes a test that fails when the requirement is broken.
- Ruby only, packaged with Fledge; native calls go through Fiddle, on every system (Fledge's runtimes ship it as a bundled gem; `Kernel#syscall` doesn't exist on macOS or Windows, and its call numbers differ between Linux processors). Another language needs a reason only it can meet, written in its design page.
- Reuse before you build. Before writing a parser, a checker, or a helper, look for reliable code that exists: the standard library, Ruby's bundled gems, maintained gems. Write new code only with a written reason.
- Every file starts with an SPDX header, copyright `2026 setdef <kerrick@setdef.com>`: `MIT` for code, `CC-BY-SA-4.0` for documentation. In Ruby, wrap it in `#--` and `#++` to keep it out of RDoc output.
- Every line of Ruby is covered by tests that would stand up to mutation testing, and each test checks specific behavior. No mutation-testing tool runs in the gate until one exists for Ruby.
- Value objects are `Data.define`, written `class Foo < Data.define(...)`, because RDoc skips the methods in a `Foo = Data.define(...) do` block and the coverage check never counts them; entities are classes.
- Type every class and method in `.rbs`, with no `untyped`; `.rbs` files carry no comments. A `Data.define` subclass declares `class Foo < Data`, an `attr_reader` for each member, and `self.new` (and `self.[]` if used) with positional and keyword overloads, because `Data.new` returns `bot`.
- Document every public class and method with RDoc, not YARD, in the `.rb` file, following `doc/contributors/documentation_style.md`. That guide covers RDoc in Ruby files; `doc/contributors/style-guide.md` covers everything else.
- Every cop RuboCop has is on. Fix an offense; never write `rubocop:disable`. Turn a cop off in `.rubocop.yml` only for a reason written beside it.
- A one-off script that grows past a few lines is a temporary Rake task or `ruby -e`, not a long shell string.
- Commit straight to the trunk, one tested change at a time; run the checks before the push, not after. A commit message is one plain imperative line in sentence case with no prefix (not Conventional Commits), a blank line, and a short body saying why.
- Releases: bump the version in `lib/proof/version.rb`, tag it, and publish a GitHub release regularly, always as `0.X.Y`, never with a prerelease suffix such as `-rc.1` or `.pre.1`.
- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and lists only what people who use Proof see: new commands and flags, changed behavior, deprecations, removals. Its Unreleased section covers the time since the last tag, so a commit that undoes an earlier unreleased one removes that entry. Past versions stay as they are.

## Landmines

- `doc/reference/cli.md` and `skills/proof/references/cli.md` are generated. Never edit them by hand.
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

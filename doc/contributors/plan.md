<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Plan for 1.0

What 1.0 builds, in what order, what it leaves out, and what is still undecided. Delete each item here once it's done or decided, and record a decision where it belongs: the docs, a design page, or an ADR.

## Order of work

1. **Scaffold the repository** from `ruby_quality`, and merge its `AGENTS.md` into this repository's, so there is one.
2. **One Linux runner, end to end,** in virtual machines: server setup, runner setup, a run of a commit and of a working tree, streamed output, the exit status, cancel, and artifacts.
3. **Prove sensing a person** on each system, as [People at hosts](design/people-at-hosts.md#proven-before-its-built-on) lists, before anything depends on it.
4. **macOS,** then **Windows with WSL.**
5. **Move one real project at a time** onto Proof once it can carry that project's checks.

Each requirement in the design pages becomes an acceptance test as its part is built.

## Not in 1.0

Leave these out until a project asks for one, and then decide it as a design change:

- Windows as the server, or as the computer where `proof` runs
- runs that take a whole host, such as benchmarks
- runs on a person's real desktop, with real input
- priorities, and moving a run ahead in the queue
- placement or sizing from earlier runs' history
- a record of every process a run started
- Linux distributions beyond those the README lists
- isolation between runs beyond separate folders and accounts
- reporting results to a forge, such as GitHub commit statuses

## Undecided

Each item says what the docs say now, which is what to build unless it's decided otherwise.

- **`keep-free` defaults to 25 GB** in the pool file reference.
- **A lost build of a pushed commit** is never run again, like any other run. Running it once more, since nobody is there to, was proposed.
- **GitHub commit statuses** for builds of pushed commits are left out of 1.0; without them, a private repository's forge shows no check marks.
- **Dependency folders inside the project,** such as `node_modules` and `vendor/bundle`, are deleted before every run unless the project declares them as caches. Keeping known dependency folders automatically was the alternative.
- **Agents get the Agent Skill through `proof skill install`,** which copies the skill that ships with the release.
- **The trunk's name:** the README's CI badge says `trunk`.
- **Who decided each ADR:** the records say "not recorded".
- **The Agent Skill's license:** `CC-BY-SA-4.0`, as for the docs, while Proof's code is MIT.
- **On macOS, a run that plays sound without asking for the `sound` label** is heard by a person at the host.
- **Harnesses that read `CLAUDE.md`** won't find `AGENTS.md` without a `CLAUDE.md` that points to it.
- **Missing files the docs link:** `LICENSE`, `CONTRIBUTING.md`, and `CHANGELOG.md`.

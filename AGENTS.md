<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# AGENTS.md

Instructions for coding agents working on Proof itself, in any harness. People contributing by hand follow the same rules. To use Proof to run another project's checks, read [the Agent Skill](skills/proof/SKILL.md) instead.

## What Proof is, and where things are

Proof runs a project's tasks on the Linux, Windows, and macOS computers its user already has, from the working tree or any commit, and exits with the task's status. Read the [README](README.md) first, then the [glossary](doc/glossary.md): every word in the code, the docs, and Proof's output means what the glossary says.

| Path | What it is |
| --- | --- |
| `README.md`, `doc/` except `doc/contributors/` | Documentation for people who use Proof |
| `doc/reference/cli.md` | The CLI reference, generated from `proof.usage.kdl`; never edit it by hand |
| `proof.usage.kdl` | The command-line interface, as a [usage](https://usage.jdx.dev) spec |
| `skills/proof/` | The Agent Skill that ships with each release, for agents that use Proof |
| `doc/contributors/decisions/` | The architectural decisions, one per record |
| `doc/contributors/design/` | What each part must guarantee, and the traps known so far |
| `doc/contributors/style-guide.md` | The conventions for every page and for what Proof prints |

## The documentation is the specification

The user documentation was written before the code, and it is the specification. Every command, flag, file, output line, and exit status it shows is a promise the code must keep, and each becomes an acceptance test.

- **When code and docs disagree, one of them is wrong, and nobody may leave it that way.** Change the code to match the docs. If the docs are what's wrong, change them in the same commit as the code, and say why in the commit message.
- **Change the CLI in `proof.usage.kdl` first,** then regenerate both references from it:

  ```console
  $ usage generate markdown --file proof.usage.kdl --out-file doc/reference/cli.md
  $ usage generate markdown --file proof.usage.kdl --out-file skills/proof/references/cli.md
  ```

  Run `usage lint proof.usage.kdl` before you commit. The parser in the code must accept exactly what the spec accepts.
- **Keep the Agent Skill in step.** A change to what agents type, read, or should do changes `skills/proof/` in the same commit.
- **Use the glossary's words, and avoid the words it lists to avoid,** in identifiers, messages, and docs alike. A new idea gets a glossary entry before it gets a name in code.

## Decisions

The architectural decisions are in [`doc/contributors/decisions/`](doc/contributors/decisions/README.md). Don't work against one: no external scheduler, no transport but Git through the server, no connection to a runner, no root for runs. When a change needs a different decision, write a new record with the next number that restates the decision whole, and delete the old one in the same change. Never edit the decision text of an accepted record. Most choices aren't architectural, and belong in the design pages instead.

## Building and testing

Proof is written in Ruby and packaged per platform with [Fledge](https://github.com/setdef/Fledge), so the code may use nothing outside what Fledge's Ruby provides: no Fiddle, and native calls through `Kernel#syscall` or a helper program. A helper in another language needs a reason only that language can meet, written in its design page.

- **Each requirement in the design pages becomes a test,** and each test should fail when its requirement is broken: check a new test fails on the commit before your change.
- **Tests never reach the internet,** neither GitHub nor any server Proof talks to in use. They use local fakes with fixed answers.
- **Develop and test in virtual machines,** never on a pool people depend on. A test or a run must not stop, slow, or change anyone's real hosts.
- **Root is for disposable virtual machines only.** Proof's code never runs anything as root, and its setup prints administrator commands for a person instead. Never hand a person a command to run as root that hasn't already run, as written, in a virtual machine.
- **What a virtual machine can't show,** such as a real GPU, a Windows private desktop, a macOS session presenting frames, or KVM on real hardware, is proven on one real host, in a window the host's owner agrees to beforehand, with nothing changed outside Proof's account.

## Working on the trunk

Commit each change straight to the trunk, one concern per commit, each tested and releasable, and push it as soon as it passes. Don't open long-lived branches, and don't wait on CI after a push: run the checks that prove the change before you push. If the trunk is broken, reverting the commit that broke it comes before any other work.

## Writing

Follow [the style guide](doc/contributors/style-guide.md) for every page, every message Proof prints, and every commit message: American English, the glossary's words, the prompts and example names it lists, ASCII only in output and examples. In the docs, a run's sound, windows, and input are things Proof handles for the tests that need them, never things to avoid.

## What stays out of the repository

This repository is public. Write nothing into it that a stranger couldn't already find: no names of anyone's computers or accounts, no private paths, no logs or records from anyone's pool, no secrets, and no quotes from conversations. Give the reasons for a change as the project's reasons.

<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# AGENTS.md

## The Tao of Proof

Proof does three things for a developer whose coding agents check every change:

1. **It gets the work off the computer you work at.** Test suites stop hammering its CPU and memory, and their windows stop flashing across your screen.
2. **It runs the work where you can't.** A compiler that builds only for the operating system it runs on builds on that system, and a bug that shows only on Windows is tested on Windows.
3. **It is CI for trunk-based development, before the push as well as after.** An agent learns whether a change works, from the working tree or any commit, in a private or unpushed repository, without paying for minutes, and without pushing to a forge and polling it while waiting for a Mac runner that may never come.

Each is easy alone, and each pulls against the others. Getting work off your computer puts it on another, where a person may be working or gaming. Running where you can't means waiting for the one Mac you have. Checking every change fills the queue the other two wait in. Proof lives in the balance: a run must leave every computer usable by the person at it, reach the hardware it needs, and still answer sooner than pushing and polling would. A design that serves one of the three by spending another isn't done: freeing your screen by flashing windows on another someone else is actively using, reaching the Mac by making every run wait for it, or answering sooner with a pass nobody saw. The answer is worth having only when it's true, so Proof never reports a pass that didn't happen.

---

For working on Proof itself. To use Proof on another project, read `skills/proof/SKILL.md`.

## Commands

- Lint the CLI spec: `usage lint proof.usage.kdl`
- After any change to `proof.usage.kdl`, regenerate both references:
  - `usage generate markdown --file proof.usage.kdl --out-file doc/reference/cli.md`
  - `usage generate markdown --file proof.usage.kdl --out-file skills/proof/references/cli.md`

## Decisions

- The docs are the specification. When code and docs disagree, change the code, or change both in one commit and say why.
- Use the words in `doc/glossary.md`, in code as in docs. A new idea gets a glossary entry before it gets a name.
- Don't work against `doc/contributors/decisions/`: no external scheduler, no transport but Git through the server, nothing connects to a runner, no root for runs. To change one, write a new record with the next number and delete the old one; never edit an accepted record.
- Each requirement in `doc/contributors/design/` becomes a test that fails when the requirement is broken.
- Ruby only, packaged with Fledge: no Fiddle; native calls through `Kernel#syscall`. Another language needs a reason only it can meet, written in its design page.
- Commit straight to the trunk, one tested change at a time; run the checks before the push, not after.

## Landmines

- `doc/reference/cli.md` and `skills/proof/references/cli.md` are generated. Never edit them by hand.
- A change to the CLI or to what agents should do changes `skills/proof/` in the same commit.
- Tests never reach the internet. Use local fakes.
- Never develop or test on a pool people use. Use virtual machines.
- Prove what a virtual machine can't show, such as a real GPU or a Windows desktop, on one real host only, in a window its owner agreed to beforehand.
- Root only inside a disposable virtual machine. Never hand a person a root command that hasn't run there.
- This repository is public: no names of anyone's computers or accounts, no private paths or pool records, no secrets, no quotes from conversations.
- Follow `doc/contributors/style-guide.md` for every page, every message Proof prints, and every commit message.

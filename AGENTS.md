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
- `skills/proof/references/project-file.md` is a hand-written summary of `doc/reference/project-file.md`, not a copy. A change to the project file's format changes both in the same commit.
- Tests never reach the internet. Use local fakes.
- Never develop or test on a pool people use. Use virtual machines.
- Prove what a virtual machine can't show, such as a real GPU or a Windows desktop, on one real host only, in a window its owner agreed to beforehand.
- Root only inside a disposable virtual machine. Never hand a person a root command that hasn't run there.
- This repository is public: no names of anyone's computers or accounts, no private paths or pool records, no secrets, no quotes from conversations.
- Follow `doc/contributors/style-guide.md` for every page, every message Proof prints, and every commit message.

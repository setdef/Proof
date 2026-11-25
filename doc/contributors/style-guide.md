<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Documentation style guide

The conventions Proof's documentation follows that general writing guidance doesn't settle. They apply to the README, everything under `doc/`, Proof's Agent Skill, and the text Proof itself prints.

## Words

[The glossary](../glossary.md) is the authority on which word to use for each idea, and on the words to avoid. When a page needs a word the glossary lacks, add it there first, with what other tools call it and the words to avoid.

Two terms differ by audience:

| Idea | In the README and `doc/` | In the Agent Skill |
| --- | --- | --- |
| Someone at a host's keyboard, mouse, or screen | person | human |

Agents call themselves and each other "someone", so the Agent Skill says "human" to keep an agent from counting itself.

Say what each part does with the verb that fits it: a runner *runs* tasks and scripts, each execution is a *run*, and the server *places* each run on a runner. A task *requests* resources: CPUs and memory.

## Prompts in examples

On a page whose commands run on more than one computer, or as more than one account, every command's prompt shows the account and the computer. Use the same form for every command on that page, not only where the computer changes:

| Shell | Prompt |
| --- | --- |
| Linux | `you@nuc $` |
| macOS | `you@mac %` |
| Windows (PowerShell in Windows Terminal) | `PS C:\Users\you>` |
| Any shell, as root | `root@nuc #` |

Each such page explains its prompts once, in a table near the top, before the first command.

On a page whose commands all run as one account on one computer, use a bare prompt: `$`, or `%` when the example is specific to macOS, or the PowerShell prompt when it's specific to Windows.

## Names in examples

| What | Name |
| --- | --- |
| The reader's account | `you` |
| The account Proof runs as | `proof`. Proof doesn't require that name, and examples say so where the account is created. |
| The computer the reader works on | `laptop` |
| The server's computer and its address | `server`, at `server.home.arpa`. [RFC 8375](https://www.rfc-editor.org/rfc/rfc8375) reserves `home.arpa` for home networks. |
| A Linux host and its runner | `nuc`, with the runner `nuc-linux` |
| A Windows host and its runners | `pc`, with the runners `pc-windows` and `pc-wsl` |
| A Mac host and its runner | `mac`, with the runner `mac-macos` |
| A run ID | `20261125-0336-m3d8q`, shortened to `m3d8q` where the page has shown the full form |
| A runner's approval code, and a sign-in code | `XK7P-42MQ` and `Q8MR-2T4W` |

Examples of real use come from a real project. Any public repository under [github.com/setdef](https://github.com/setdef) may be named and linked; [Lota](https://github.com/setdef/Lota) is the running example in the README and the references. Tutorials, which need output the reader can reproduce with any project, use a Ruby project called `invoices`.

## Output in examples

- **Use real output where there is any,** and clean it first: leave out compiler and build-tool noise, warnings, and debug lines the point of the example doesn't need.
- **Keep every number plausible beside the others.** A count of tests, a run time, and a size in one example have to fit together, and the example has to show why Proof is worth using.
- **Mark a number you don't have yet** with an HTML comment before the example, saying which values to replace and with what: `<!-- Placeholder: replace queued= and ran= with those of real runs of Lota's package task. -->`.
- **Lead with a run that succeeds.** Show failing runs where a page teaches what a failure looks like.
- **Use ASCII only,** in examples and in what Proof prints: no emoji and no other non-ASCII characters, even where the project's output has them.

## What Proof prints

- The lines Proof prints go to standard error and begin with `proof:`, so they can't be confused with a task's output, which goes to standard output.
- A run ends with one result line of `key=value` fields. Fields are only ever added to it, never renamed or removed.
- Messages follow the [Command Line Interface Guidelines](https://clig.dev/) and [Better CLI](https://bettercli.org/).

## Generated pages

`doc/reference/cli.md` is generated from [`proof.usage.kdl`](../../proof.usage.kdl). Change the spec, then regenerate the page:

```console
$ usage generate markdown --file proof.usage.kdl --out-file doc/reference/cli.md
```

Writing guidance applies to the text in the spec, which people and agents write, and not to the wording usage's templates add around it.

## The README

- The one-line description and the introduction state what Proof can do, never what it can't. "From your working tree or any commit", not "before you push".
- The comparison section, "What Proof replaces", is organized by what readers do today, such as running the suite on their laptop, and says what changes for them.
- Badges follow Lota's and Fledge's set: CI, release, license, platforms, and Certified Shovelware. There is no Ruby badge, because people who use Proof don't install Ruby.
- "How this was made" uses the four-word disclosure, as in Fledge's README.

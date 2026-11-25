<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Design

What each part of Proof must guarantee, and the traps known so far. These pages say what must hold and why, not how to build it. Each requirement becomes an acceptance test. The decisions they rest on are in [the decision log](../decisions/README.md), and the behavior people see is in [How Proof works](../../how-proof-works.md).

- [Command](command.md): agents as the main users, choosing the project and the code to send, the pre-push hook, slow links, and exit statuses.
- [Server](server.md): placement per host, run records, output, the Git repositories, artifacts, tokens and codes, and versions.
- [Runner](runner.md): ending everything a run starts, memory, measuring, output, a run's folders, workspaces, caches, and disk.
- [Platforms](platforms.md): what Linux, Windows, and macOS each need from a runner.
- [Plan for 1.0](../plan.md): the order of work, what 1.0 leaves out, and what is still undecided.
- [People at hosts](people-at-hosts.md): giving way to a person, what is known about sensing one on each system, and what must be proven first.

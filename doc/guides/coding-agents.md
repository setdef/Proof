<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Teach your agents to use Proof

A coding agent runs a project's tests the way its instructions say. Proof's Agent Skill tells it to run them with `proof`, how to read the result, and what to do when a run fails or waits. This guide installs the skill, and adds one line to a project's agent instructions.

## Install the skill

The skill comes with Proof. Install it where your agents look for skills:

```console
$ proof skill install
proof: installed the proof skill to ~/.agents/skills/proof
```

To install it somewhere else, such as a folder one agent tool reads, give the folder:

```console
$ proof skill install --to ~/.claude/skills
```

Install it again after each upgrade of Proof, so the skill matches the version you run.

## Point a project at it

In the project's agent instructions, such as `AGENTS.md`, say which tasks to run before a change is done:

```markdown
Before you finish a change, run `proof run test` and `proof run lint`, and fix what fails.
```

The skill teaches the rest: that `proof` exits with the task's status, that exit status 75 means the pool failed and the run should be run again, how to come back to a run with `proof watch`, and to read the end of a long output with `proof logs RUN_ID --tail 100`.

## What the skill tells agents

- Run tasks with `proof run`, never by hand on the computer you work on, and never through `bash -c`: every task and script runs as `proof run NAME` or `proof run --script FILE`.
- Read the last line, which is the result, and the exit status. Don't pipe `proof` into `tail` or `head`: use `--tail` on `proof logs` instead.
- When a run waits, `proof status` says what it waits behind. A run that waits isn't hung.
- Exit status 75 means the pool failed, not the task: run it again. Any other non-zero status is the task's.
- Never cancel another agent's run, and never ask for a different operating system to make a failure go away.
- A person at a host comes first. If runs wait because a person is using a host, wait or use another host; never ask the person to stop.

## Many agents at once

Five agents that each run a test suite after every change send five runs at once, and Proof places each on a host with room for it. Each agent's run gets a separate workspace; runs of one project share a download cache, so a large download arrives once per host. If runs pile up in the queue, `proof status` shows it, and adding a host is the fix.

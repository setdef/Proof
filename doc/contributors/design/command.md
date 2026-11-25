<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Command design

What the `proof` command must guarantee, and the traps known so far. Its interface is [`proof.usage.kdl`](../../../proof.usage.kdl); this page covers what the interface can't say. How to meet each requirement is the implementer's choice.

## Who runs it

Most invocations come from coding agents, inside agent harnesses. That shapes several requirements:

- **No shell text on the command line.** Harnesses refuse compound commands such as `bash -c '...'` from sub-agents, so every task and script must be runnable as `proof run NAME` or `proof run --script FILE`, with nothing for a shell to parse.
- **Signals mean cancel.** A harness that stops an agent sends `TERM`, often twice, to the whole process tree. `proof run` must cancel its run on the first, and not exit before the server has heard, within a bounded wait. `proof watch` stops watching and leaves the run going.
- **A closed pipe means the reader is gone.** Agents pipe output into `head` and `tail`. A broken pipe on standard output cancels the run, as a signal would, and `proof` exits 141, rather than letting the run go on unseen.
- **Background use must not lose the result.** An agent that starts `proof` in the background, or whose harness ends, has the run ID in the first lines, and `proof watch ID` exits with the run's status, so the result is never lost.

## Which project and which code

- The project is the Git repository containing the current folder, or `-C`'s. If there is none, refuse; never guess. The first line names the project's root and the commit, so an agent whose shell drifted into another project's folder sees it at once.
- **A working-tree run is a synthetic commit made without touching the clone:** a temporary index (`GIT_INDEX_FILE`), `git add -A` with untracked files that aren't ignored, `git write-tree`, `git commit-tree` with `HEAD` as parent. The clone's index, `HEAD`, and branches stay exactly as they were.
- **Strip `GIT_*` variables** inherited from a Git hook before running Git: a hook run inside a linked worktree inherits `GIT_DIR`, which redirects every Git command.
- **Submodules** go at the commits the superproject records; their objects may live in the superproject's `.git/modules/NAME`, not in the submodule's checkout. Uncommitted changes inside a submodule are not sent.
- **Partial clones** can't send all a commit's objects, because they don't have them. Refuse with a message that says so.
- Push only objects the server lacks.

## The pre-push hook

- Git gives a pre-push hook one line per ref it will push. For a new branch, the remote's old value is all zeros: use the remote's default branch as the base instead.
- Git gives the hook no lines at all for a push it is about to refuse, such as a non-fast-forward. No lines doesn't mean nothing to check: refuse, and say what the likely cause is.
- One run checks the whole push.

## Sending over slow links

- A transfer fails when it stalls, not when it is slow: below a minimum rate for a whole window (for example, 1,000 bytes a second for 60 seconds). A deadline on the whole transfer can't tell a slow link from a dead one, and makes every retry start from zero.
- Write to a temporary name and check the byte count before the transfer counts as complete: a dropped connection can look like the end of the input.
- Say how a failed try ended: stalled, cut off, or no answer.

## Output and exit status

- Print a line before any network call, so a command never sits silent while it connects.
- The last line is the result: `key=value` fields, only ever added to, never renamed.
- Exit with the task's status, or with one of the statuses the spec reserves for Proof. Proof's failures before anything was sent exit 2; failures of the pool after sending exit 75. A failure of Proof itself prints no result line, so it can't be read as a run's.
- Errors are rewritten for people, end with the command to run next, and keep a debug log under `~/.local/state/proof/`, never in the current folder.

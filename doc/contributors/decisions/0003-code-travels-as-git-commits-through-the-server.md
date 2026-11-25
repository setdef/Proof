---
status: proposed
date: 2026-11-24
deciders: not recorded
---

# Code travels to runners as Git commits, through Proof's server

## Context and Problem Statement

A run checks either the working tree as it is, with uncommitted changes, or an exact commit with its history, which tasks that compare commits need. The runner that gets the run is chosen after the code is sent, and a run can move to another runner. Runners have no credentials for the project's forge, and code nobody has pushed must not go there. Most runs follow a change of a few lines to a much larger project. How should a run's code get from where `proof` runs to the runner?

## Decision Drivers

* An exact commit, with its history, on the runner
* The working tree as it is, uncommitted changes included
* Only what changed travels, since most runs follow a change of a few lines
* No forge involved, and no forge credentials on runners
* A runner chosen after the code is sent can still get it

## Considered Options

1. Git commits, pushed to a repository on Proof's server and fetched by the runner
2. An archive of the working tree, uploaded to the server and downloaded by the runner
3. Pushing to the project's forge, and having the runner fetch from there

## Decision Outcome

Chosen: option 1, because Git sends only the objects the other side lacks, keeps a commit's history, and can check that nothing a commit reaches is missing, and every runner has it. Option 2 lost because an archive has no history and sends the whole tree for every run. Option 3 lost because it puts forge credentials on every runner, and sends code to the forge that nobody decided to push.

A working tree goes as a commit `proof` makes without touching the clone's index, branch, or `HEAD`. A runner counts a commit as fetched only once it has every object the commit reaches. How it works is in [How Proof works](../../how-proof-works.md#how-your-code-reaches-a-runner).

Confidence: unbuilt. No recorded comparison measures option 1 against option 2.

### Consequences

* Good, because a run of a commit has the same history as the clone, so `git log` and comparisons with `HEAD~1` work.
* Good, because a run after a one-line change sends kilobytes, not the project.
* Bad, because the server keeps a Git repository per project, which grows with every run's commits and needs repacking and pruning.
* Bad, because uncommitted changes inside a submodule aren't sent.
* Bad, because where `proof` runs needs Git, and the project must be a Git repository.

### Confirmation

Nothing automated checks it yet.

## More Information

Revisit this decision if Proof has to run projects that aren't Git repositories.

---
status: proposed
date: 2026-11-24
deciders: not recorded
---

# Proof's server places runs itself, with no external scheduler

## Context and Problem Statement

A pool is a few hosts that people also use, on Linux, Windows, and macOS. Each run has to go to a host with the right operating system, the labels the task needs, and the CPUs and memory it requests free. A Windows PC and the Linux in its WSL are one host with two runners, so their resources have to be counted together. While a person is active at a host, runs there must go on with less of the host, not stop. Every runner runs as an unprivileged account. Should Proof place runs itself, or hand that job to an existing scheduler?

## Decision Drivers

* Placement by operating system, labels, and free resources counted per host
* A reduced share of a host while a person is active there, with runs going on
* Unprivileged runners on Linux, Windows, and macOS on Apple silicon
* Documentation a person can read whole, within about 150,000 tokens for the entire project

## Considered Options

1. A queue and placement written in Proof's server
2. HTCondor
3. Nomad
4. Concourse

## Decision Outcome

Chosen: option 1, because each of the others fails a driver that defines the product. Option 2 lost because HTCondor builds for macOS only on Intel, installs on Windows only as an administrator, can only suspend or stop work while a person is at a host, and can't count two runners on one host against one budget except at the moment a job is matched; its documentation alone runs to about 454,000 words. Option 3 lost because Nomad treats each runner as a separate node, has no notion of a person at a host, and its documentation says its `raw_exec` driver, which runs tasks as the same account as Nomad, runs them "with no resource isolation". Option 4 lost because Concourse's Linux tasks reach a GPU or KVM only when they run as root on the worker.

How placement works is in [How Proof works](../../how-proof-works.md#how-the-server-places-a-run).

Confidence: the reasons against options 2 to 4 come from their documentation, and for HTCondor also from running it unprivileged in a Debian 13 virtual machine. Nothing yet shows that option 1 places runs correctly; it is unbuilt.

### Consequences

* Good, because placement can count resources per host and keep a share for a person, which no option weighed can do.
* Good, because a pool needs nothing installed but Proof.
* Bad, because Proof's maintainers are responsible for the queue's correctness: no run lost, none placed twice, none stuck behind a vanished host.
* Bad, because the server has no priorities, no preemption, and no fair sharing between people; adding them would grow the server toward what the rejected schedulers already do.

### Confirmation

Nothing automated checks it yet. Tests of the server's placement will.

## More Information

Revisit this decision if Proof needs priorities, preemption, or fair queueing between people: that is the point at which an existing scheduler may cost less than growing Proof's server.

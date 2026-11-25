---
status: proposed
date: 2026-11-24
deciders: not recorded
---

# Runs never get root, and each runner runs as an account set aside for Proof

## Context and Problem Statement

Hosts are computers people use. Tasks need hardware such as KVM for Android emulators and a GPU for graphics, and some need a desktop session. A run's command is whatever the project says, so a mistake in it, or in Proof, lands on someone's computer. What should a run be allowed to do on its host, and as which account should it run?

## Decision Drivers

* Hosts that people use, whose files and system a run must not change
* Hardware for tasks that need it: KVM, a GPU, a display
* Setup a person can understand: any step that needs an administrator is printed, never performed

## Considered Options

1. An ordinary account set aside for Proof, with hardware granted through groups such as `kvm` and `render`
2. An ordinary account: the account of the person who uses the host
3. Root, or a privileged container, for the runner and its runs

## Decision Outcome

Chosen: option 1, because a separate ordinary account keeps runs away from both the system and the person's files, while groups give it the hardware tasks need. Option 2 lost because a run's command could read and change the files of the person who uses the host. Option 3 lost because a run could then change the system it runs on, which is exactly what a host someone uses can't afford.

Proof prints the commands that need an administrator, such as creating the account and adding it to a group, and checks them the next time setup runs. The docs name the account `proof`; any name works. How it works is in [How Proof works](../../how-proof-works.md#what-a-runner-gives-each-run), and what it must guarantee is in the designs of [the runner](../design/runner.md) and [each platform](../design/platforms.md).

Confidence: on Debian 13, an unprivileged account held a process tree to a memory limit through a systemd user scope, and ran a virtual display with a window manager, both tested in a virtual machine. Hardware access through groups is unproven on real hosts.

### Consequences

* Good, because a run can't change its host's system, or read the files of the person who uses it.
* Bad, because setup needs an administrator once per host, to create the account and grant it groups.
* Bad, because runs on one runner share the account, so one project's run can read another project's files.
* Bad, because without root, holding a run to its memory request depends on each system: a systemd user scope on Linux, a job object on Windows, and on macOS, where the kernel has no limit an ordinary account can set, ending the run when the host runs short.
* Bad, because on macOS, a run that opens windows needs a signed-in session for the account, which someone has to sign in after each restart.

### Confirmation

Nothing automated checks it yet. `proof runner setup` will refuse to set up a runner as root.

## More Information

The administrator steps for each system are in the guides for adding hosts.

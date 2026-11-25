<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Guides

Each guide does one job, from a pool that already has a server and one runner. If you don't have that yet, start with [Getting started](../getting-started.md). For every command and setting, see the [command reference](../reference/cli.md), the [project file reference](../reference/project-file.md), and the [pool file reference](../reference/pool-file.md).

## Add hosts to the pool

- [Add a Mac](add-a-mac.md): set up a runner on macOS, including one that can open windows in a signed-in session.
- [Add a Windows PC](add-a-windows-pc.md): set up a runner on Windows and another in its WSL, counted as one host.
- [Run a task on several operating systems](several-operating-systems.md): write setup that works on Linux, macOS, and Windows, and list in the project file where each task works.
- [Give runs a GPU, KVM, or a desktop](labels.md): which hardware each runner offers as a label, and how a task asks for it.

## Work with coding agents

- [Teach your agents to use Proof](agents.md): install Proof's Agent Skill, so an agent runs tasks with `proof` instead of on your computer.
- [Check every push](pre-push-hook.md): add a pre-push hook that runs a task on the commits you push, and stops the push when the run fails.

## Move files into and out of runs

- [Keep and download artifacts](artifacts.md): keep files from a run, download them, and give them to another run.
- [Keep caches between runs](caches.md): choose folders worth keeping between a project's runs, and when to start in an empty workspace instead.

## Use the pool in place of hosted CI

- [Build every pushed commit](build-pushed-commits.md): list a repository in the pool file, and read each commit's results.

## Share hosts with the people who use them

- [Share a host with the person who uses it](sharing.md): set how much of a host to keep free for a person, and what waits while they're there.

## Run containers and emulators

- [Run containers in a run](containers.md): use rootless Podman on a Linux runner, with no Docker daemon and no root.
- [Run Android emulators and iOS Simulators](emulators.md): KVM for Android emulators on Linux, and Simulators on a Mac.

## Keep the pool running

- [Upgrade the pool](upgrade.md): upgrade the server, and let the runners follow.
- [Remove a runner or the server](remove.md): revoke a runner, uninstall Proof from a computer, and delete what it kept.
- [When a run fails or waits](troubleshooting.md): read the result line and exit status, find why a run is queued, and what to put in an issue.

<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Proof

[![CI](https://github.com/setdef/Proof/actions/workflows/ci.yml/badge.svg?branch=trunk)](https://github.com/setdef/Proof/actions/workflows/ci.yml) [![Release](https://img.shields.io/github/v/release/setdef/Proof)](https://github.com/setdef/Proof/releases) [![License](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fsetdef%2FProof%2Ftrunk%2Fproof.gemspec&search=spec%5C.license%20%3D%20%22(.*)%22&replace=%241&label=License&color=a2c93e)](https://spdx.org/licenses/MIT.html) [![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20Windows-a2c93e)](#compatibility) [![Certified Shovelware](https://justin.searls.co/img/shovelware.svg)](https://justin.searls.co/shovelware/)

Run your project's tests and builds on your spare computers, from your working tree or any commit.

## Introduction

Proof sends your project from the computer you work on to the other Linux, Windows, and macOS computers you have, runs its tests and builds there, streams their output back, and exits with their status. It's for developers whose coding agents check every change. When five agents each run a one-minute test suite after every change, the computer they work on is running tests most of the time. With Proof, each agent sends its run to a computer with room for it, and no agent has to push to GitHub, or wait for a hosted CI service, to find out whether a change works.

Proof sends your working tree as it is, uncommitted changes included, or an exact commit with its history. It runs work that needs a real GPU, a desktop session where it can open windows, or [KVM](https://linux-kvm.org/) for Android emulators, and it never runs anything as root. Proof can also build every commit after it's pushed, on the same computers, so you pay for no CI minutes for a private repository.

A person using one of those computers comes first. While someone is at its keyboard, mouse, or screen, Proof keeps part of the computer free for them and runs other work in what's left; work that needs their display or GPU waits until they stop.

### What Proof replaces

- **Running the suite where you work.** On your laptop, an agent's test suite slows down everything else, opens windows, steals the keyboard focus, and plays sound while you're trying to work, and five agents running it at once bog down the whole computer. Proof sends those runs to computers with room for them.
- **Pushing to hosted CI and waiting.** You learn the result only after you push, often minutes later, and GitHub charges for a private repository's minutes past a monthly allowance. With Proof, an agent learns the result before it pushes, and gets the same exit status as it would from running the suite itself, and no service bills you by the minute.
- **Scripts that ssh to another computer.** A script like that works for one computer at a time, and you need a different one for each operating system. Proof is one command for Linux, Windows, and macOS, with a queue, reused workspaces, artifacts, and cleanup after every run.
- **Self-hosted CI runners.** [GitHub Actions self-hosted runners](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners) and [Buildkite](https://buildkite.com/) agents run on computers you manage, but only code you've pushed, and they take their work from GitHub's or Buildkite's service. Proof runs code you haven't pushed, and Proof's server runs on one of your computers.

## A first example

[Lota](https://github.com/setdef/Lota) is a Ruby library for 2D games. The compiler that builds its native extension builds only for the operating system it runs on, so building each operating system's gem takes a computer running that system. From a Mac, this command builds Lota's Linux gem on a Linux computer and downloads it:

<!-- Placeholder: replace queued= and ran= with those of a real run of Lota's package task on Linux. -->
```console
$ proof run package --os linux
proof: project ~/src/Lota at 3f9c2e1, no uncommitted changes
proof: run 20261124-1431-m3d8, task package, on linux
proof: running on nuc-linux (workspace reused)
✅ Built pkg/lota-0.0.1.dev-x86_64-linux.gem
proof: exit=0 run=20261124-1431-m3d8 runner=nuc-linux queued=0s ran=0s
$ proof download 20261124-1431-m3d8
pkg/lota-0.0.1.dev-x86_64-linux.gem
```

Proof's first lines say what it sent and where the run went, and its last line is the result: the exit status, the run's ID, the computer it ran on, and how long it waited and ran. Between them is the output of the task's command, as the command printed it. `proof` exits with the command's status, here 0.

## Compatibility

| Role | Supported systems |
| --- | --- |
| Where you run `proof` | Linux or macOS, with [Git](https://git-scm.com/) |
| The server, on one always-on computer that takes no runs | Linux or macOS |
| A runner, on each computer that takes runs | Linux (Debian 13, Ubuntu 24.04, or Fedora 40 and later) on x86-64 or ARM64; Windows on x86-64, with Linux in [WSL](https://learn.microsoft.com/windows/wsl/) (the Windows Subsystem for Linux) as a second runner on the same computer; macOS on Apple silicon |

Proof runs a project's named tasks with [mise](https://mise.jdx.dev/), which Proof installs on each runner. You don't need mise where you run `proof`.

### Limitations

- Whoever holds a token for running work can run any command, as the runner account, on every computer in the pool. Keep such a token as you would an SSH key.
- Runs on one computer share one account. Each run gets a separate workspace, home folder, and temporary folder, but a run's command can read another project's files in that account.
- The server is one computer. While it's asleep or off the network, no new run starts.

## Installation

Download the archive for your computer from [the releases page](https://github.com/setdef/Proof/releases), unpack it anywhere, and put `proof` on your `PATH`. The archive contains everything Proof needs, so you install no Ruby or other runtime.

## Usage

1. **Set up a server.** On the always-on computer, run `proof setup server`. It checks the computer, says what it will change, starts the server as a service of your account, and prints a code for signing in.
2. **Add each computer that takes runs.** Run `proof setup runner proof-server.local` on it. It prints a short code, such as `XK7-42P`, so you never type a long token at a text console. Where setup needs a change only an administrator can make, such as adding the account to the `kvm` group, it prints the commands for you to run.
3. **Sign in where you work,** then let each runner in: `proof login proof-server.local`, then `proof approve XK7-42P`. `proof verify` then sends a known run to every runner and reports each result.
4. **Run a task** from anywhere in the project: `proof run test`. `test` can be a task in the project's `mise.toml` or a task defined in `.config/proof.kdl`. In that optional file, you say which operating systems each task works on, what hardware it needs, the CPUs and memory it requests, and which files to keep from its runs. To try something without a task, run a script: `proof run --script bench.sh --os linux`.
5. **Come back to a run** by its ID from any terminal: `proof watch RUN_ID` streams it and exits with its status, `proof logs RUN_ID` prints its whole output, and `proof cancel RUN_ID` stops it. `proof status` shows every runner and what each queued run is waiting behind.
6. **Check before each push.** `proof hook install test` adds a Git pre-push hook to your clone, and Git stops the push when the `test` run fails.
7. **Build every pushed commit** by listing a repository, its branches, and its tasks in the server's pool file.
8. **Upgrade** by running `proof upgrade` on the server. The runners upgrade themselves to match.

[Getting started](doc/getting-started.md) covers steps 1 to 4 with one Linux runner.

## Documentation

- [Getting started](doc/getting-started.md): set up a server and one Linux runner, and run a first task.
- [Guides](doc/guides/index.md): adding a Mac or a Windows PC, GPUs and desktops, artifacts and inputs, caches, the pre-push hook, building pushed commits, and sharing a computer with the person who uses it.
- [How Proof works](doc/how-proof-works.md): the server, the runners, how your code reaches them, and why Proof is built that way.
- [Command reference](doc/reference/cli.md): every command, flag, and exit status.
- [Project file reference](doc/reference/project-file.md) and [pool file reference](doc/reference/pool-file.md): every setting in `.config/proof.kdl` and in the server's pool file.
- [Glossary](doc/glossary.md): the word Proof uses for each idea, and the words it avoids.

## Reporting problems

Open an issue at [github.com/setdef/Proof/issues](https://github.com/setdef/Proof/issues). Include the output of `proof status`, the run's ID, and `proof logs RUN_ID` for the run that went wrong.

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) says how to build Proof, run its tests, and propose a change.

## License

Proof is released under the [MIT License](LICENSE). It places no conditions on the projects you check with it.

## How this was made

I use four words for how code and prose comes to exist. Code or prose I wrote, I typed by hand, with nothing generated. Code or prose I wrought, an AI agent generated while I iterated with it, and I reviewed every change before committing it, so I own every diff. Code or prose I requested, an agent built with little or no review from me, but I take ownership of the outcome or product because I tested and iterated. Code or prose I rushed, an agent built with little or no feedback from me, and may or may not be useful (or safe).

Proof's code, tests, and documentation are requested. In place of review, the project's rules require every line of Ruby to be covered by tests meant to stand up to mutation testing, tests that never touch the network, and a check of each change before its push. This README is wrought. [declare-ai.org](https://declare-ai.org/1.0.0/creative.html)

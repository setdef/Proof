# Proof

[![CI](https://github.com/setdef/Proof/actions/workflows/ci.yml/badge.svg?branch=trunk)](https://github.com/setdef/Proof/actions/workflows/ci.yml) [![Release](https://img.shields.io/github/v/release/setdef/Proof)](https://github.com/setdef/Proof/releases) [![License](https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fraw.githubusercontent.com%2Fsetdef%2FProof%2Ftrunk%2Fproof.gemspec&search=spec%5C.license%20%3D%20%22(.*)%22&replace=%241&label=License&color=a2c93e)](https://spdx.org/licenses/MIT.html) [![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20Windows-a2c93e)](#compatibility) [![Forum: Discussion](https://img.shields.io/badge/forum-discussion-5865F2.svg?logo=discourse)](https://forum.setdef.com/tags/c/proof/15/discussion) [![Forum: Bug Reports](https://img.shields.io/badge/forum-bug_reports-4954d5.svg?logo=discourse)](https://forum.setdef.com/tags/c/proof/15/bug) [![Forum: Announcements](https://img.shields.io/badge/forum-announcements-3b44ac.svg?logo=discourse)](https://forum.setdef.com/tags/c/proof/15/announcement) [![Certified Shovelware](https://justin.searls.co/img/shovelware.svg)](https://justin.searls.co/shovelware/)

Run your project's tests and builds on your spare computers, from your working tree or any commit.

## Introduction

Proof sends your project from the computer you work on to the other Linux, Windows, and macOS computers you have, which Proof calls hosts, runs its tests and builds there, streams their output back, and exits with their status. It's for developers whose coding agents check every change. When five agents each run a one-minute test suite after every change, the computer they work on is running tests most of the time. With Proof, each agent sends its run to a host with room for it, and no agent has to push to GitHub, or wait for a hosted CI service, to find out whether a change works.

Proof sends your working tree as it is, uncommitted changes included, or an exact commit with its history. It runs work that needs a real GPU, a desktop session where it can open windows, or [KVM](https://linux-kvm.org/) for Android emulators, and it never runs anything as root. Proof can also run your tasks on every commit after it's pushed, on the same hosts, so you pay for no CI minutes for a private repository.

A person using one of those hosts comes first. While someone is at its keyboard, mouse, or screen, Proof keeps part of the host free for them and runs other work in what's left; work that needs their display, GPU, or speakers waits until they stop.

### What Proof replaces

- **Running the suite where you work.** On your laptop, an agent's test suite slows down everything else, opens windows, steals the keyboard focus, and plays sound while you're trying to work, and five agents running it at once bog down the whole computer. Proof sends those runs to hosts with room for them.
- **Pushing to hosted CI and waiting.** You learn the result only after you push, often minutes later, and GitHub charges for a private repository's minutes past a monthly allowance. With Proof, an agent learns the result before it pushes, and gets the same exit status as it would from running the suite itself, and no service bills you by the minute.
- **Scripts that ssh to another computer.** A script like that works for one computer at a time, and you need a different one for each operating system. Proof is one command for Linux, Windows, and macOS, with a queue, reused workspaces, artifacts, and cleanup after every run.
- **Self-hosted CI runners.** [GitHub Actions self-hosted runners](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners) and [Buildkite](https://buildkite.com/) agents run on computers you manage, but only code you've pushed, and they take their work from GitHub's or Buildkite's service. Proof runs code you haven't pushed, and Proof's server runs on one of your computers.

## A first example

[Lota](https://github.com/setdef/Lota) is a Ruby library for 2D games. The compiler that builds its native extension builds only for the operating system it runs on, so building each operating system's gem takes a host running that system. From a Mac, this command builds Lota's Linux and Windows gems at the same time, on a Linux host and a Windows host, and downloads both:

<!-- Placeholder: replace queued= and ran= with those of real runs of Lota's package task. -->
```console
% proof run package --os linux --os windows --download
proof: Lota at 3f9c2e1 (clean), task package
proof: run m3d8q on nuc-linux (reused workspace)
proof: run p9x2k on pc-windows (reused workspace)
[nuc-linux] Built pkg/lota-0.0.1.dev-x86_64-linux-gnu.gem
[pc-windows] Built pkg/lota-0.0.1.dev-x64-mingw-ucrt.gem
proof: downloaded pkg/lota-0.0.1.dev-x86_64-linux-gnu.gem from run m3d8q to ./pkg/
proof: downloaded pkg/lota-0.0.1.dev-x64-mingw-ucrt.gem from run p9x2k to ./pkg/
proof: exit=0 run=20261125-0336-m3d8q task=package runner=nuc-linux queued=0s ran=0s artifacts=1
proof: exit=0 run=20261125-0336-p9x2k task=package runner=pc-windows queued=0s ran=0s artifacts=1
```

Lines that start with `proof:` are Proof's, written to standard error. The task's output goes to standard output, each line marked with the runner it came from when more than one run is going. Each run ends with one result line, with its exit status and its full ID, for an agent to read. Here every run succeeded, so `proof` exits with 0. When runs fail, it exits with one status chosen in [a fixed order](docs/guides/several-operating-systems.md#exit-status-with-several-runs). Anywhere Proof asks for a run's ID, its last five characters are enough: `proof logs m3d8q`. A script that needs more than the result lines can pass `--json`, and Proof then prints one JSON object per run in their place.

## Compatibility

| Role | Supported systems |
| --- | --- |
| Where you run `proof` | Linux or macOS, with [Git](https://git-scm.com/) |
| The server, on one always-on computer with no runner | Linux or macOS |
| A runner, on each host that runs your tasks and scripts | Linux (Debian 13, Ubuntu 24.04, or Fedora 40 and later) on x86-64 or ARM64; Windows on x86-64, with Linux in [WSL](https://learn.microsoft.com/windows/wsl/) (the Windows Subsystem for Linux) as a second runner on the same host; macOS on Apple silicon |

Proof runs a project's named tasks with [mise](https://mise.jdx.dev/), which Proof installs on each runner. You don't need mise where you run `proof`.

### Limitations

- Whoever holds a token for running work can run any command, as the runner account, on every host in the pool. Keep such a token as you would an SSH key.
- Runs on one runner share the runner's account. Each run gets a separate workspace, home folder, and temporary folder, but a run's command can read another project's files in that account. Set up each runner as an account set aside for Proof, so no run can read the files of a person who uses the host.
- The server is one computer. While it's asleep or off the network, no new run starts.

## Installation

Download the archive for your computer from [the releases page](https://github.com/setdef/Proof/releases), check it against the release's `SHA256SUMS` file, unpack it anywhere, and put `proof` on your `PATH`. The archive contains everything Proof needs, so you install no Ruby or other runtime. Proof talks only to your server, and sends no usage data anywhere.

To uninstall Proof from a computer, run `proof runner uninstall` or `proof server uninstall` there if you set one up, which stops Proof's service and deletes its files. Then delete the unpacked folder and `~/.config/proof`.

## Usage

1. **Set up a server.** On the always-on computer, as an account set aside for Proof (the docs call it `proof`), run `proof server setup`. It checks the computer and lists every change it will make before it makes any. With `--dry-run`, it stops after the list. It then starts the server as a service of your account and prints a one-time code for signing in.
2. **Add each host,** each computer that will run tasks. On it, as an account set aside for Proof, run `proof runner setup server.home.arpa`. It prints a short code, such as `XK7P-42MQ`, so you never type a long token at a text console. Where a step needs an administrator, such as adding the account to the `kvm` group, setup prints the exact commands for you to run, and checks them when you run setup again.
3. **Sign in where you work, and let each runner in:**

   ```console
   $ proof login server.home.arpa
   $ proof runner approve XK7P-42MQ
   $ proof verify
   ```

   `proof login` asks for the code from step 1, and never takes a secret as an argument. `proof verify` sends a known run to every runner and reports each result.
4. **Run a task** from anywhere in the project: `proof run test`. `test` can be a task in the project's `mise.toml` or a task defined in `.config/proof.kdl`. In that optional file, you say which operating systems each task works on, what hardware it needs, the CPUs and memory it requests, and which files to keep from its runs. Without `--os`, Proof places the run on any operating system with a runner free, or only on those the project file lists for the task. Words for the task follow `--`, as with `cargo run` and `npm run`: `proof run test -- --seed 1234` gives the task a flag. `:::` starts the next task, as with `mise run`: `proof run lint ::: test` runs two tasks, and `proof run lint -- --fix ::: test -- --seed 1234` gives each task different words. Proof's flags go anywhere before `--`, and Proof refuses a flag it doesn't have, such as `--oss`, and suggests the nearest one it has, `--os`. To try something without a task, run a script: `proof run --script bench.sh --os linux`.
5. **Come back to a run** by its ID from any terminal. `proof watch m3d8q` streams it and exits with its status, `proof logs m3d8q` prints its whole output, and `proof cancel m3d8q` stops it. In `proof run`, press Ctrl-C to cancel the run. In `proof watch`, press Ctrl-C to stop watching without canceling it. `proof run --detach` starts a run and exits at once with its ID. `proof status` shows every runner, and what each queued run is waiting behind.
6. **Check before each push.** `proof hook install test` adds a Git pre-push hook to your clone, and Git stops the push when the `test` run fails.
7. **Run tasks on every pushed commit** by listing a repository, its branches, and its tasks in the server's pool file.
8. **Upgrade** by running `proof server upgrade` on the server. The runners upgrade themselves to match.

[Getting started](docs/getting-started.md) covers steps 1 to 4 with one Linux runner.

## Documentation

- In the terminal: `proof help` lists every command with examples, and `proof help run` explains one command.
- [Getting started](docs/getting-started.md): set up a server and one Linux runner, and run a first task.
- [Guides](docs/guides/index.md): adding a Mac or a Windows PC, GPUs and desktops, teaching your agents to use Proof, the pre-push hook, artifacts, caches, running tasks on pushed commits, sharing a host with the person who uses it, containers and emulators, upgrading, and troubleshooting.
- [How Proof works](docs/how-proof-works.md): the server, the runners, how your code reaches them, and why Proof is built that way.
- [Command reference](docs/reference/cli.md): every command, flag, and exit status.
- [Project file reference](docs/reference/project-file.md) and [pool file reference](docs/reference/pool-file.md): every setting in `.config/proof.kdl` and in the server's pool file.
- [Glossary](docs/glossary.md): the word Proof uses for each idea, and the words it avoids.

## Reporting problems

Ask questions and report problems on the [Proof forum](https://forum.setdef.com/c/proof). Include the output of `proof status`, the run's ID, and `proof logs RUN_ID` for the run that went wrong. When Proof hits an error it can't explain, it saves a debug log under `~/.local/state/proof/` and prints a link to a new topic in the forum category with the details filled in. GitHub Issues are open to the project's collaborators only.

Report a security problem privately, as [SECURITY.md](SECURITY.md) says, never in the forum category.

To send a patch, post it on the forum, or email it with `git send-email` to `replies+proof@forum.setdef.com`. [git-send-email.io](https://git-send-email.io) shows how to set that up.

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) holds the working rules for everyone who changes Proof, people and AI agents alike: the values Proof serves, how to commit to `trunk` and run the gate, the commit message format, and the rules for code, documentation, security, and licensing. It doesn't say how to install the tools or how to propose a change. This section does.

To set up a clone on Linux or macOS, install [mise](https://mise.jdx.dev/) 2026.10.11 or later, then run these in the clone:

```console
$ mise install
$ BUNDLE_PATH=$HOME/.cache/proof-bundle mise exec -- bundle install
```

`mise install` installs the tools `mise.toml` pins: Ruby, Python, pre-commit, the REUSE tool, usage, actionlint, and shellcheck. Keep `BUNDLE_PATH` outside the clone, because RuboCop and REUSE read every gem installed inside it. `bin/setup` runs those two commands without a `BUNDLE_PATH`, and then runs `reuse download --all`, `pre-commit install`, and `bundle exec rake rdoc`. `pre-commit install` adds a Git pre-commit hook that runs `bundle exec rake`. Every worktree of a clone shares the clone's hooks, so don't run `bin/setup` in a worktree.

Before you push or send a patch, run the gate. It runs the checks CI runs, on your computer, at a low priority:

```console
$ BUNDLE_PATH=$HOME/.cache/proof-bundle bin/ci
```

To propose a change, send a patch as [Reporting problems](#reporting-problems) says. Pull requests and GitHub Discussions are off, and GitHub Issues are open to collaborators only.

## License

Proof is released under the [MIT License](LICENSE). It places no conditions on the projects you check with it.

## How this was made

I use four words for how code and prose comes to exist. Code or prose I wrote, I typed by hand, with nothing generated. Code or prose I wrought, an AI agent generated while I iterated with it, and I reviewed every change before committing it, so I own every diff. Code or prose I requested, an agent built with little or no review from me, but I take ownership of the outcome or product because I tested and iterated. Code or prose I rushed, an agent built with little or no feedback from me, and may or may not be useful (or safe).

Proof's code, tests, and documentation are requested. In place of review, the project's rules require every line of Ruby to be covered by tests meant to stand up to mutation testing, tests that never touch the network, and a check of each change before its push. This README is wrought. [declare-ai.org](https://declare-ai.org/1.0.0/creative.html)

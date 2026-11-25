# Proof

Proof runs your project's tests and builds on the Linux, Windows, and macOS computers you already have, before you push, with one command that streams the output and exits with the result. It's for developers who work with coding agents and have a few computers to spare. When five agents each run a one-minute test suite after every change, the computer they work on spends most of its time running tests. With Proof, each agent sends its run to a computer with room for it and gets the suite's exit status back, without pushing anything to GitHub or waiting on hosted CI.

Here an agent checks a change to [Lota](https://github.com/setdef/Lota), a Ruby library for 2D games, on a Linux runner. Lota's test suite opens windows, plays sound, and goes full screen, so on the computer the agent works on, nobody could use the keyboard or mouse until it finished:

<!-- Placeholder: replace the finish time, queued=, and ran= with those of a full run of Lota's suite. -->
```console
$ proof run test --os linux
proof: project ~/src/Lota at 3f9c2e1 with 2 uncommitted changes
proof: run 20261124-1402-k7q2, task test, on linux
proof: running on nuc-linux (workspace reused)
Run options: --seed 10614

# Running:

....................................S.S.....................S........S..........F............

Finished in 0s
2623 runs, 455936 assertions, 1 failures, 0 errors, 18 skips

You have skipped tests. Run with --verbose for details.
rake aborted!
Command failed with status (1)
proof: exit=1 run=20261124-1402-k7q2 runner=nuc-linux queued=0s ran=0s
```

One of the 2,623 tests failed, so `proof` exits with 1, as `rake` did on the runner. The failing test's report is left out of this example.

Proof's first lines say what it sent and where the run went, the test's output follows as the test prints it, and the last line is the result.

Proof can also build every commit after it's pushed, on the same computers, so a private repository needs no paid CI minutes. And a person using one of those computers comes first: while someone is at its keyboard, Proof keeps part of it free for them and runs other work in what's left.

## How Proof compares

- [GitHub Actions self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners) and [Buildkite](https://buildkite.com/docs/agent/v3) agents run on computers you manage, but only for code you've pushed, and both need a hosted service. Proof checks your working tree as it is, or any commit, before it leaves your computer, and Proof's server runs on one of your computers too.
- [Concourse](https://concourse-ci.org/)'s `fly execute` also uploads a local tree and returns the task's status. Its Linux tasks reach a GPU or KVM only when they run privileged, as root on the worker. Proof never runs anything as root: a runner reaches the GPU and KVM through its account's membership in groups such as `kvm` and `render`.
- [HTCondor](https://htcondor.org/) and [BOINC](https://boinc.berkeley.edu/) also give way to the person at a computer. Both suspend or stop work while someone is there; Proof goes on with a smaller share of the computer. HTCondor's macOS builds are for Intel Macs only, and its Windows install needs an administrator.

## What you need

| Role | Where it runs |
| --- | --- |
| The `proof` command, where you or your agents work | Linux or macOS, with Git |
| The **server**, on one computer that's always on and takes no runs | Linux or macOS |
| A **runner**, on each computer that takes runs | Linux (Debian 13, Ubuntu 24.04, or Fedora 40 and later) on x86-64 or ARM64; Windows on x86-64, with Linux in WSL as a second runner on the same computer; macOS on Apple silicon |

Every runner runs as an ordinary account, never as root. Where a runner needs a one-time change only an administrator can make, such as adding its account to the `kvm` group, setup prints the exact commands for you to run and checks them the next time you run setup.

Proof runs a project's tasks with [mise](https://mise.jdx.dev/). A project defines its tasks in `mise.toml`, in Proof's project file, or in both. Setup installs mise on each runner; you don't need mise where you run `proof`.

## Install

Download the archive for your computer from [the releases page](https://github.com/setdef/Proof/releases), unpack it anywhere, and put its `proof` on your `PATH`. Proof needs no Ruby or other runtime installed; the archive contains everything Proof needs to run.

## Set up a pool

A **pool** is your runners and the server that hands them runs. Setting one up takes one command per computer, and each command is safe to run again.

1. On the computer that will be the server, run:

   ```console
   $ proof setup server
   ```

   Setup checks the computer, says what it will change, and starts the server as a service of your account. It writes the **pool file**, `~/.config/proof/pool.kdl`, which lists your hosts, their disk budgets, and what to keep free for a person using each one. Last, it prints a one-time code for signing in from where you work.

2. On each computer that will take runs, run setup with the server's address:

   ```console
   $ proof setup runner proof-server.local
   proof: this runner asks to join proof-server.local as code XK7-42P
   proof: approve it from any computer with `proof approve XK7-42P`
   ```

   You never type or paste a long token on that computer, so this works from a text console on a freshly installed server. On a Windows PC, the same command also sets up a runner in WSL, and Proof counts both as one host.

3. Where you work, sign in to the server with the code from step 1, then approve each runner by its code:

   ```console
   $ proof login proof-server.local
   $ proof approve XK7-42P
   ```

4. Check that every runner works:

   ```console
   $ proof verify
   ```

   `proof verify` sends one known run to each runner and reports each result.

The runners upgrade themselves to the server's version, so upgrading the pool means running `proof upgrade` on the server.

## Use it

### Run a task

A **task** is a named command in your project. Run one from anywhere inside the project's Git repository:

```console
$ proof run test
```

Proof sends your working tree as it is, with uncommitted changes and with untracked files that Git doesn't ignore. To check an exact commit, with its history, send it instead:

```console
$ proof run test --commit HEAD
```

Proof's first lines say which project and commit it sent, and its last line is always the result:

```text
proof: exit=1 run=20261124-1402-k7q2 runner=nuc-linux queued=0s ran=0s
```

`proof` exits with the task's exit status. When the pool itself fails, such as a runner that disappears mid-run, `proof` exits with 75, and you can run the task again.

### Say where a task runs

Proof runs each task in `mise.toml` as `mise run NAME`. In a project file, `.config/proof.kdl`, you give Proof what only Proof needs: which operating systems a task supports, what hardware it needs, the CPUs and memory it requests, and which files to keep. You can also define a task with a command in the project file, and Proof then runs that command instead of `mise run`. The project file is optional, and a fork or a collaborator without a pool can ignore it.

Say Lota's `mise.toml` defines a `test` task that runs `bundle exec rake test` and a `package` task that runs `bundle exec rake package:native`. A project file can then say where they run. In this one, every task supports all three operating systems and requests 4 CPUs and 8 GB. The `test` task needs a runner that can open windows, and the `package` task keeps the gems it builds:

```kdl
defaults cpus=4 memory="8GB" {
  os linux macos windows
}

task test {
  label desktop
}

task package {
  artifact "pkg/*.gem"
}
```

With this file, `proof run test --os any` runs on whichever operating system has a runner free that can open windows.

### Run a script

To try something without defining a task, run a script:

```console
$ proof run --script bench.sh --os linux
```

Give `-` in place of a file name to read the script from standard input.

### Watch, cancel, and read a run again

Every run has an ID. Use it to come back to a run from any terminal:

```console
$ proof watch 20261124-1402-k7q2
$ proof cancel 20261124-1402-k7q2
$ proof logs 20261124-1402-k7q2
```

`proof watch` streams a run's output while it runs and exits with its status, so an agent whose command was interrupted can pick the run up again. `proof logs` prints the whole output of any run, finished or not. `proof status` shows every runner, the queue for each operating system, and what each queued run is behind.

### Keep files from a run

A run can keep **artifacts**, files that you download later or give to another run. The compiler that builds Lota's native extension builds only for the operating system it runs on, so building Lota's gems for Linux and Windows takes a run on each, even from a Mac:

<!-- Placeholder: replace queued= and ran= with those of a real run of Lota's package task on Linux. -->
```console
$ proof run package --os linux
proof: project ~/src/Lota at 3f9c2e1
proof: run 20261124-1431-m3d8, task package, on linux
proof: running on nuc-linux (workspace reused)
✅ Built pkg/lota-0.0.1.dev-x86_64-linux.gem
proof: exit=0 run=20261124-1431-m3d8 runner=nuc-linux queued=0s ran=0s
$ proof download 20261124-1431-m3d8
pkg/lota-0.0.1.dev-x86_64-linux.gem
```

`proof run package --os windows` builds the Windows gem the same way. To give one run's artifacts to another run, name the earlier run with `--input RUN_ID`.

### Check every push

`proof hook install test` adds a Git pre-push hook to your clone. The hook runs the `test` task on the commits you're pushing, and Git stops the push when the task fails. You install the hook in each clone yourself, so Proof never changes what a collaborator's `git push` does.

### Build every pushed commit

To use your pool in place of hosted CI, list a repository, its branches, and the tasks to run in the pool file, and give the server read access to the repository. The server fetches those branches every minute and runs the tasks on each new commit, and `proof status` shows the results.

## Who comes first on a shared computer

On a computer someone uses, that person comes first. While a person is using a host's keyboard, mouse, or screen, Proof keeps a share of its CPUs and memory free for them, and runs other work in what's left. Runs that need the person's display or GPU wait until the person stops. When nobody has touched the host for a few minutes, runs get the whole computer back. On Linux and Windows, a run that opens windows gets a separate display or desktop, so it can't take the person's mouse pointer or keyboard focus.

## Limits

- **Whoever holds a token for running work can run code on every runner.** They can run any command, as the runner account, on every host in the pool. Keep such a token as you would an SSH key.
- **Runs on one runner share an account.** Each run gets a separate workspace, home folder, and temporary folder, but one run's command can read another project's files in that account.
- **The server is a single computer.** While it's asleep or off the network, no new run starts.
- Windows isn't supported as the server or as the computer you run `proof` on.

## Documentation

- [Getting started](doc/getting-started.md): set up a server and one Linux runner, and run your first task.
- [Guides](doc/guides/index.md): task-by-task instructions, from adding a Mac or a Windows PC to keeping caches between runs.
- [How Proof works](doc/how-proof-works.md): the server, the runners, how your code reaches them, and why.
- [Command reference](doc/reference/cli.md): every command and flag.
- [Project file reference](doc/reference/project-file.md) and [pool file reference](doc/reference/pool-file.md): every setting.
- [Glossary](doc/glossary.md): the word Proof uses for each idea, and the words it avoids.

## Reporting problems

Open an issue at [github.com/setdef/Proof/issues](https://github.com/setdef/Proof/issues). Include the output of `proof status`, the run ID, and `proof logs RUN_ID` for the run that went wrong.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to build Proof, run its tests, and propose a change.

## License

Proof is released under the [MIT License](LICENSE). It places no conditions on the projects you check with it.

## How this was made

I use three words for how code and prose comes to exist. Code or prose I wrote, I typed by hand, with nothing generated. Code or prose I wrought, an AI agent generated while I iterated with it, and I reviewed every change before committing it, so I take responsibility for every diff. Code or prose I requested, an agent built with little or no review from me, in the style of a "dark factory."

All of Proof (its code, tests, and documentation, this README included) was requested. Agents built it from my goals and decisions, with little review of the diffs. In place of review, the project's rules require every line of Ruby to be covered by tests meant to stand up to mutation testing, tests that never touch the network, and a check of each change before its push. [declare-ai.org](https://declare-ai.org/1.0.0/total.html).

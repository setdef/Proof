<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Getting started

In this tutorial, we set up a Proof pool of one server and one Linux runner, and run a project's tests on it from the computer you work on. By the end, you'll have run a task on another computer, seen a failing run and what `proof` does with it, and checked a commit apart from your uncommitted changes. It takes about 30 minutes, most of it waiting for downloads.

If you get stuck, [open an issue](https://github.com/setdef/Proof/issues) with the command you ran and everything it printed. Words in bold are defined in the [glossary](glossary.md).

## What you need

- **The computer you work on,** running Linux or macOS, with [Git](https://git-scm.com/) and a project in a Git repository. The examples use a Ruby project called `invoices` whose tests run with `bundle exec rake test`; use your project's test command wherever this page shows that one.
- **An always-on computer for the server,** running Linux or macOS. It runs no tasks, so an old laptop is enough. The examples call it `proof-server.local`.
- **A Linux computer for the runner:** Debian 13, Ubuntu 24.04, or Fedora 40 or later. The examples call it `nuc`. You'll need someone who can run `sudo` on it, once.

The server and the runner can't be the same computer. All three need to reach the server's computer over the network; the server needs to reach neither of the others.

## Install Proof on each computer

On each of the three computers, download the archive for that computer from [the releases page](https://github.com/setdef/Proof/releases), check it against the release's `SHA256SUMS` file, unpack it, and put `proof` on your `PATH`. Then check that the shell finds it:

```console
$ proof --version
proof 1.0.0
```

## Set up the server

On the server's computer, ask setup what it would change, without changing anything:

```console
$ proof server setup --dry-run
proof: setup would make these changes on proof-server.local:
proof:   create ~/.config/proof/pool.kdl
proof:   create ~/.local/share/proof for runs, their output, and their artifacts
proof:   create a certificate for proof-server.local
proof:   start the Proof server as a service of your account, on port 7443
proof: nothing changed, because of --dry-run
```

Setup touches only your account's folders and services. When the list looks right, run it for real:

```console
$ proof server setup
proof: created ~/.config/proof/pool.kdl
proof: created ~/.local/share/proof
proof: created a certificate for proof-server.local
proof: started the Proof server on port 7443
proof: sign in from where you work with `proof login proof-server.local`, and give it this one-time code: Q8M-2RT
```

Keep that code for later; we'll use it to sign in from the computer you work on.

## Set up the runner

On `nuc`, run setup with the server's address:

```console
$ proof runner setup proof-server.local
proof: checking nuc for a Linux runner
proof: an administrator must run this command, then run `proof runner setup proof-server.local` again:
proof:   sudo loginctl enable-linger kerrick
proof: nothing changed
```

This is where most people stop and wonder whether something went wrong. Nothing did: the runner runs as an ordinary account, and setup never runs anything as root. It prints the one command it needs an administrator for, here the one that keeps your account's services running after you log out, and changes nothing until it's done. Run the command it printed, or ask someone who can, then run setup again:

```console
$ sudo loginctl enable-linger kerrick
$ proof runner setup proof-server.local
proof: checked: kerrick's services keep running after logout
proof: installed mise for the runner
proof: started the runner nuc-linux as a service of your account
proof: nuc-linux asks to join proof-server.local as code XK7-42P
proof: approve it from where you work with `proof runner approve XK7-42P`
```

The code is short so that you can read it off a text console and type it elsewhere. Nobody types or pastes a token on `nuc`.

## Sign in and approve the runner

On the computer you work on, sign in with the code from the server, then approve the runner with its code:

```console
$ proof login proof-server.local
proof: enter the one-time code from `proof server setup`: Q8M-2RT
proof: signed in to proof-server.local
$ proof runner approve XK7-42P
proof: approved nuc-linux
proof: added host nuc to the pool file, with the default budget and share
```

Now check that the runner works, by sending it a known run:

```console
$ proof verify
proof: nuc-linux passed (4s)
proof: exit=0 runners=1 passed=1 failed=0
```

If `proof verify` reports a failure, its message says which step failed and what to do. That message, with the output of `proof status`, is what to put in an issue if it doesn't help.

## Run a task

Proof runs a project's tasks with [mise](https://mise.jdx.dev/). If your project has no `mise.toml` yet, add one at the project's root. It says which Ruby the project needs, and defines a `test` task that first runs a `setup` task to install the project's gems:

```toml
[tools]
ruby = "3.4"

[tasks.setup]
run = "bundle install"

[tasks.test]
depends = ["setup"]
run = "bundle exec rake test"
```

The runner starts from nothing, so a task has to install what it needs, as it would on a hosted CI service. You don't need mise installed where you work; the runner has it.

Now let's run the tests. From anywhere in the project, run:

```console
$ proof run test
proof: refused: no operating system is given for task test
proof: add `--os linux`, or list the operating systems it works on in .config/proof.kdl:
proof:   defaults {
proof:     os linux
proof:   }
```

`proof` exits with 2, and sends nothing. Proof doesn't guess where a task works: plenty of projects run only on Linux, and a run sent to Windows to find out would fail in its setup. Before you run it again, think about which of the two fixes in the message you'd use for a task you'll run every day.

The flag works for one run. The project file says it once for every run. Create `.config/proof.kdl` at the project's root:

```kdl
defaults {
  os linux
}
```

Run the task again:

```console
$ proof run test
proof: invoices at 9b1e44a (clean), task test
proof: run k7q2 on nuc-linux (empty workspace)
Run options: --seed 31877

# Running:

............................................

Finished in 2.413771s, 18.2289 runs/s, 41.4291 assertions/s.
44 runs, 100 assertions, 0 failures, 0 errors, 0 skips
proof: exit=0 run=20261124-1402-k7q2 task=test runner=nuc-linux queued=0s ran=1m52s
```

The first run took almost two minutes because the workspace was empty: mise installed Ruby, and the `setup` task installed the project's gems. The `ran=` time in the last line is the whole run, setup included. Run the same command again, and the second run reuses the workspace:

```console
$ proof run test
proof: invoices at 9b1e44a (clean), task test
proof: run w3n8 on nuc-linux (reused workspace)
Run options: --seed 4410

# Running:

............................................

Finished in 2.388152s, 18.4243 runs/s, 41.8734 assertions/s.
44 runs, 100 assertions, 0 failures, 0 errors, 0 skips
proof: exit=0 run=20261124-1405-w3n8 task=test runner=nuc-linux queued=0s ran=6s
```

## See a run fail

Proof sends your working tree as it is, so a change you haven't committed is part of the run. Make a change that breaks one test, without committing it, and run the task:

```console
$ proof run test
proof: invoices at 9b1e44a with 1 uncommitted change, task test
proof: run r5c1 on nuc-linux (reused workspace)
Run options: --seed 52931

# Running:

.......................F....................

  1) Failure:
InvoiceTest#test_total_includes_tax [test/invoice_test.rb:18]:
Expected: 107.0
  Actual: 100.0

44 runs, 100 assertions, 1 failures, 0 errors, 0 skips
rake aborted!
proof: exit=1 run=20261124-1409-r5c1 task=test runner=nuc-linux queued=0s ran=6s
proof: read the whole output with `proof logs r5c1`
```

What will the shell say `proof` exited with? Check:

```console
$ echo $?
1
```

`proof` exits with the task's status, so an agent, a script, or a Git hook can use `proof run test` exactly as it would use `bundle exec rake test`.

Now check the last commit instead, without your change:

```console
$ proof run test --commit HEAD
proof: invoices at 9b1e44a, task test
proof: run h2v6 on nuc-linux (reused workspace)
Run options: --seed 17203

# Running:

............................................

Finished in 2.402215s, 18.3165 runs/s, 41.6283 assertions/s.
44 runs, 100 assertions, 0 failures, 0 errors, 0 skips
proof: exit=0 run=20261124-1411-h2v6 task=test runner=nuc-linux queued=0s ran=7s
```

The run passes, because `--commit HEAD` sends the commit with its history and leaves out what you haven't committed. Undo the change that broke the test before you go on.

## Check your work

You've finished when all of these are true:

- `proof status` lists `nuc-linux`, with nothing in the queue.
- `proof run test` in your project exits with 0.
- `proof logs r5c1`, with your failing run's ID in place of `r5c1`, prints the failing run's whole output again.

You should now be comfortable setting up a server and a runner, running a project's task on it, and telling a failing run from a pool problem by its exit status. To add a Mac or a Windows PC, or to check every push before it leaves your computer, continue with the [guides](guides/index.md).

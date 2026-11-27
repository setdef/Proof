# Getting started

In this tutorial, we set up a Proof pool of one server and one Linux runner, and run a project's tests on it from the computer you work on. By the end, you'll have run a task on another host, seen a failing run and what `proof` does with it, and checked a commit apart from your uncommitted changes. It takes about 30 minutes, most of it waiting for downloads.

If you get stuck, [post in Proof's forum category](https://forum.setdef.com/c/proof) with the command you ran and everything it printed. Words in bold are defined in the [glossary](glossary.md).

## What you need

- **The computer you work on,** running Linux or macOS, with [Git](https://git-scm.com/) and a project in a Git repository. The examples call it `laptop`, and use a Ruby project called `invoices` whose tests run with `bundle exec rake test`; use your project's test command wherever this page shows that one.
- **An always-on Linux computer for the server.** It runs no tasks, so an old laptop is enough. The examples call it `server`, at the address `server.home.arpa`. A server on macOS works too; its setup differs, and this tutorial doesn't cover it.
- **A Linux host for the runner:** a computer running Debian 13, Ubuntu 24.04, or Fedora 40 or later. The examples call it `nuc`.
- **Someone who can run `sudo`** on the server's computer and on `nuc`, for two commands on each.

The server's computer can't also be a host. The other two computers need to reach the server's computer over the network; the server needs to reach neither of them.

## How to read the prompts

The commands on this page run on three computers, as two different accounts, so each prompt says which:

| Prompt | Where, and as whom |
| --- | --- |
| `you@laptop $` | Your account, on the computer you work on |
| `you@server $`, `you@nuc $` | Your account, on the server's computer or the runner's host |
| `proof@server $`, `proof@nuc $` | The account Proof runs as, on the server's computer or the runner's host |

Type only what follows the `$`. Lines without a prompt are what the command printed.

## Create an account for Proof

The server and each runner run as a separate account, not as the account of whoever uses the computer, so a run's command can't read your files. These examples name that account `proof`; any name works.

On the server's computer, create the account, let its services keep running after it logs out, and switch to it:

```console
you@server $ sudo useradd --create-home proof
you@server $ sudo loginctl enable-linger proof
you@server $ sudo -iu proof
proof@server $
```

Do the same on `nuc`:

```console
you@nuc $ sudo useradd --create-home proof
you@nuc $ sudo loginctl enable-linger proof
you@nuc $ sudo -iu proof
proof@nuc $
```

These are the only commands on this page that need an administrator.

## Install Proof

As `proof` on the server's computer and on `nuc`, and as yourself on `laptop`, download the archive for that computer from [the releases page](https://github.com/setdef/Proof/releases), check it against the release's `SHA256SUMS` file, unpack it, and put `proof` on the account's `PATH`. Then check that the shell finds it:

```console
proof@server $ proof --version
proof 1.0.0
```

## Set up the server

As `proof` on the server's computer, ask setup what it would change, without changing anything:

```console
proof@server $ proof server setup --dry-run
proof: setup would make these changes on server.home.arpa:
proof:   create ~/.config/proof/pool.kdl
proof:   create ~/.local/share/proof for runs, their output, and their artifacts
proof:   create a certificate for server.home.arpa
proof:   start the Proof server as a service of this account, on port 7443
proof: nothing changed, because of --dry-run
```

Setup touches only the `proof` account's folders and services. When the list looks right, run it for real:

```console
proof@server $ proof server setup
proof: created ~/.config/proof/pool.kdl
proof: created ~/.local/share/proof
proof: created a certificate for server.home.arpa
proof: started the Proof server on port 7443
proof: sign in from where you work with `proof login server.home.arpa`, and give it this one-time code: Q8MR-2T4W
```

Keep that code for later; we'll use it to sign in from `laptop`.

## Set up the runner

As `proof` on `nuc`, run setup with the server's address:

```console
proof@nuc $ proof runner setup server.home.arpa
proof: checking nuc for a Linux runner
proof: checked: proof's services keep running after logout
proof: installed mise for the runner
proof: started the runner nuc-linux as a service of this account
proof: nuc-linux asks to join server.home.arpa as code XK7P-42MQ
proof: approve it from where you work with `proof runner approve XK7P-42MQ`
```

The code is short so that you can read it off a text console and type it elsewhere. Nobody types or pastes a token on `nuc`.

If you skipped `loginctl enable-linger`, setup stops before it changes anything, prints the command for an administrator to run, and asks you to run setup again. This is where people most often wonder whether something went wrong. Nothing did: setup never runs anything as root itself. Run the command it printed as yourself, switch back to `proof`, and run setup again.

## Sign in and approve the runner

On `laptop`, sign in with the code from the server, then approve the runner with its code:

```console
you@laptop $ proof login server.home.arpa
proof: enter the one-time code from `proof server setup`: Q8MR-2T4W
proof: signed in to server.home.arpa
you@laptop $ proof runner approve XK7P-42MQ
proof: approved nuc-linux
proof: added host nuc to the pool file, with a budget of 230GB, half its free disk space
```

Now check that the runner works, by sending it a known run:

```console
you@laptop $ proof verify
proof: nuc-linux passed (4s)
proof: exit=0 runners=1 passed=1 failed=0
```

If `proof verify` reports a failure, its message says which step failed and what to do. That message, with the output of `proof status`, is what to put in a forum topic if it doesn't help.

From here on, every command runs on `laptop`.

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
you@laptop $ proof run test
proof: invoices at 9b1e44a (clean), task test
proof: run k7q2w on nuc-linux (empty workspace, any operating system)
Run options: --seed 31877

# Running:

............................................

Finished in 2.413771s, 18.2289 runs/s, 41.4291 assertions/s.
44 runs, 100 assertions, 0 failures, 0 errors, 0 skips
proof: exit=0 run=20261125-0336-k7q2w task=test runner=nuc-linux queued=0s ran=1m52s
```

Proof sent the run to `nuc-linux` because it was free, and it is the only runner in this pool. Nothing in the project says which operating systems the task works on, so any of them will do; when you add a Mac or a Windows PC, the [project file](reference/project-file.md) is where to say otherwise.

The first run took almost two minutes because the workspace was empty: mise installed Ruby, and the `setup` task installed the project's gems. The `ran=` time in the last line is the whole run, setup included. Run the same command again, and the second run reuses the workspace:

```console
you@laptop $ proof run test
proof: invoices at 9b1e44a (clean), task test
proof: run w3n8r on nuc-linux (reused workspace)
Run options: --seed 4410

# Running:

............................................

Finished in 2.388152s, 18.4243 runs/s, 41.8734 assertions/s.
44 runs, 100 assertions, 0 failures, 0 errors, 0 skips
proof: exit=0 run=20261125-0336-w3n8r task=test runner=nuc-linux queued=0s ran=6s
```

## See a run fail

Proof sends your working tree as it is, so a change you haven't committed is part of the run. Make a change that breaks one test, without committing it, and run the task:

```console
you@laptop $ proof run test
proof: invoices at 9b1e44a with 1 uncommitted change, task test
proof: run r5c6t on nuc-linux (reused workspace)
Run options: --seed 52931

# Running:

.......................F....................

  1) Failure:
InvoiceTest#test_total_includes_tax [test/invoice_test.rb:18]:
Expected: 107.0
  Actual: 100.0

44 runs, 100 assertions, 1 failures, 0 errors, 0 skips
rake aborted!
proof: exit=1 run=20261125-0336-r5c6t task=test runner=nuc-linux queued=0s ran=6s
proof: read the whole output with `proof logs r5c6t`
```

What will the shell say `proof` exited with? Check:

```console
you@laptop $ echo $?
1
```

`proof` exits with the task's status, so an agent, a script, or a Git hook can use `proof run test` exactly as it would use `bundle exec rake test`.

Now check the last commit instead, without your change:

```console
you@laptop $ proof run test --commit HEAD
proof: invoices at 9b1e44a, task test
proof: run h2v6y on nuc-linux (reused workspace)
Run options: --seed 17203

# Running:

............................................

Finished in 2.402215s, 18.3165 runs/s, 41.6283 assertions/s.
44 runs, 100 assertions, 0 failures, 0 errors, 0 skips
proof: exit=0 run=20261125-0336-h2v6y task=test runner=nuc-linux queued=0s ran=7s
```

The run passes, because `--commit HEAD` sends the commit with its history and leaves out what you haven't committed. Undo the change that broke the test before you go on.

## Check your work

You've finished when all of these are true:

- `proof status` lists `nuc-linux`, with nothing in the queue.
- `proof run test` in your project exits with 0.
- `proof logs r5c6t`, with your failing run's ID in place of `r5c6t`, prints the failing run's whole output again.

You should now be comfortable setting up a server and a runner, running a project's task on it, and reading a failing run's exit status. To add a Mac or a Windows PC, or to check every push before it leaves your computer, continue with the [guides](guides/index.md).

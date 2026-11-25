<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Build every pushed commit

Use your pool in place of hosted CI: the server watches a repository's branches, and runs tasks on every commit pushed to them, by anyone. This catches what the [pre-push hook](pre-push-hook.md) can't: pushes from clones without the hook, merges made on the forge, and commits pushed with `--no-verify`.

## List the repository

On the server's computer, as the account Proof runs as, add a `repository` entry to the [pool file](../reference/pool-file.md#repository), `~/.config/proof/pool.kdl`:

```kdl
repository invoices url="https://github.com/example/invoices.git" {
  credentials-file "~/.config/proof/credentials/invoices"
  branch main
  task test
  task lint
}
```

For a private repository, put a read-only token in the credentials file, and make the file readable only by the server's account:

```console
$ chmod 600 ~/.config/proof/credentials/invoices
```

On GitHub, a fine-grained personal access token with read access to the repository's contents is enough. The server reads the token from this file only, and never passes it to a runner: runners fetch the commit from the server, as for any other run.

The server reads the pool file again when it changes, and starts watching within a minute.

## What happens on a push

Every minute, unless `poll` says otherwise, the server fetches the listed branches. For each new commit, it runs each listed task once on every operating system the commit's project file lists for it, or on any one operating system when it lists none. The tasks come from the commit itself, so a commit that changes `mise.toml` or `.config/proof.kdl` is checked with those changes.

These runs wait in the same queue as everyone else's, with no priority over them.

## Read the results

`proof status` shows each listed repository's newest commits and their runs:

```console
$ proof status
...
repositories:
  invoices main 4e7a0c2  test: succeeded  lint: failed (run 7hq2k)
```

Read a run's whole output with `proof logs 7hq2k`, as for any other run. A run that was `lost`, because its host went away, shows as `lost`: Proof never runs it again by itself. To run a task on a commit again, run it yourself with `proof run test --commit 4e7a0c2`.

## What this doesn't do

Proof doesn't report results to the forge: GitHub shows no check marks for these runs, and nobody is notified when one fails. Read `proof status`, or have an agent read it. The server fetches by polling, so it needs no address reachable from the internet, and a run starts up to one `poll` interval after a push.

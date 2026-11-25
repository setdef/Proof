<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Pool file reference

The pool file is `~/.config/proof/pool.kdl`, on the computer that runs the **server**. It describes the whole **pool**: each **host**, with its disk **budget**, the **share** Proof keeps free for a **person** who is **active** there, and any **labels** it must not offer; each repository whose pushed commits Proof builds; and how long the server keeps runs. Words in bold are defined in the [glossary](../glossary.md).

`proof server setup` writes the file, and `proof runner approve` adds a host to it, saying what it added. Everything else in it is yours to change. The server reads the file again whenever it changes, so a change takes effect for the next run without a restart.

The examples on this page describe a pool of two hosts: `nuc`, a Linux computer with one runner, `nuc-linux`; and `pc`, a Windows PC someone uses for games, with a runner for Windows, `pc-windows`, and one for Linux in WSL, `pc-wsl`.

## A complete example

```kdl
server port=7443

retention runs="90d" output="14d" artifacts="7d"
limits output="1GB" artifacts="16GB"

defaults {
  budget "100GB"
  share cpus=2 memory="4GB"
  active-for "5m"
}

host nuc {
  runner nuc-linux
  budget "400GB"
}

host pc {
  runner pc-windows
  runner pc-wsl
  budget "250GB"
  share cpus=4 memory="16GB"
  withhold gpu
}

repository lota url="https://github.com/setdef/Lota.git" {
  credentials-file "~/.config/proof/credentials/lota"
  branch trunk
  task test
  task package
}
```

The server listens on port 7443. It keeps each run's record for 90 days, its output for 14 days, and its artifacts for 7 days, and it keeps at most 1 GB of output and 16 GB of artifacts from any one run. On `nuc`, Proof may use 400 GB of disk. On `pc`, Proof may use 250 GB, keeps 4 CPUs and 16 GB free while someone is active there, and never offers the PC's GPU to a task. Every commit pushed to Lota's `trunk` branch gets a run of its `test` and `package` tasks.

## What happens when the file has a mistake

The server checks the whole file before it uses any of it. When the file has a mistake, the server keeps running with the last version that had none, and `proof status` shows the mistake, with its line, until you fix it. A server that starts with a mistake in the file runs no runs until you fix it.

The pool file is [KDL](https://kdl.dev/) 2.0, so a repeated property keeps only its last value, and a size such as `4GB` needs quotes. The [project file reference](project-file.md#mistakes-proof-catches-and-one-it-cant) shows both mistakes with their fixes.

## `server`

```kdl
server port=7443
```

| Property | Value | Default | Meaning |
| --- | --- | --- | --- |
| `port` | A port number | `7443` | The TCP port the server listens on. Every runner, and every computer where you run `proof`, connects to it. Changing it takes effect after `proof server setup` runs again. |

## `retention`

```kdl
retention runs="90d" output="14d" artifacts="7d"
```

How long the server keeps what each run leaves. Each value is a quoted duration in days, such as `"30d"`.

| Property | Default | Meaning |
| --- | --- | --- |
| `runs` | `"90d"` | A run's record: its ID, task, commit, runner, state, exit status, and times. A run's record never holds its command's arguments or environment. |
| `output` | `"14d"` | A run's whole output, which `proof logs` prints. |
| `artifacts` | `"7d"` | A run's artifacts, which `proof download` and `--input` fetch. |

After a run's output or artifacts expire, `proof logs` or `proof download` for that run says when they were deleted.

## `limits`

```kdl
limits output="1GB" artifacts="16GB"
```

| Property | Default | Meaning |
| --- | --- | --- |
| `output` | `"1GB"` | The most output the server keeps from one run. Past it, the server keeps the first and last halves, and puts a line between them saying how much it left out. The run itself goes on, and you still see all of it while you watch. |
| `artifacts` | `"16GB"` | The most artifacts the server keeps from one run. A run whose artifacts would exceed it fails with exit status 78, and the message says how large they were. |

## `defaults`

```kdl
defaults {
  budget "100GB"
  share cpus=2 memory="4GB"
  active-for "5m"
}
```

The settings every `host` gets unless its entry has a different value. It takes the same children as a `host`, except `runner`.

## `host`

```kdl
host NAME {
  runner RUNNER...
  budget "SIZE"
  share cpus=N memory="SIZE"
  active-for "DURATION"
  withhold LABEL...
}
```

One entry for each physical computer. `proof status` shows the host under `NAME`. `proof runner approve` writes the entry with the host's runners and nothing else, so the host starts with the settings in `defaults`.

| Child | Default | Meaning |
| --- | --- | --- |
| `runner` | Written by `proof runner approve` | The runners on this host. The server counts their CPUs, memory, and disk as one host's, so the server never gives a Windows PC and its WSL more runs together than the PC can run. |
| `budget` | `"50GB"` | The disk space Proof may use on this host for workspaces and caches. When Proof's files exceed it, the host's runners delete the workspaces used least recently, never one in use. |
| `share` | `cpus=2 memory="4GB"` | The CPUs and memory Proof keeps free on this host while a person is active there. Runs go on with the rest, and runs that need the person's display or GPU wait. |
| `active-for` | `"5m"` | How long after the last use of the host's keyboard, mouse, or trackpad a person still counts as active. |
| `withhold` | None | Labels this host's runners must not offer, even when they find the hardware. |

Proof still runs tasks on a host whose budget is smaller than one workspace: the runner deletes the workspace after each run instead of keeping it.

> [!WARNING]
> With a share of `cpus=0 memory="0GB"`, Proof keeps nothing free, so runs can use the whole host while someone is using it. Proof accepts it, for a host nobody sits at, but on a host someone uses, the runs make it slow for them.

## `repository`

```kdl
repository NAME url="URL" {
  credentials-file "PATH"
  branch BRANCH...
  task TASK...
  poll "DURATION"
}
```

A repository whose pushed commits Proof builds, in place of hosted CI. `proof status` shows its runs under `NAME`.

| Child or property | Default | Meaning |
| --- | --- | --- |
| `url` | Required | The repository's clone URL. The server fetches from it; runners never do. |
| `credentials-file` | None | A file holding a read-only token for the repository, for a private one. The server reads the token from this file and never from the pool file itself. |
| `branch` | Required | The branches to build. The server builds each new commit on them. |
| `task` | Required | The tasks to run on each new commit. Each task runs once on every operating system listed for it in the project file, so a task that works on Linux and macOS gets two runs per commit. |
| `poll` | `"1m"` | How often the server fetches the branches. |

The tasks come from the commit being built: its `mise.toml` and its `.config/proof.kdl`. A commit that changes a task's operating systems changes where that commit's runs go.

## Examples

### Keep more of the PC free while someone is gaming

```kdl
host pc {
  runner pc-windows
  runner pc-wsl
  share cpus=8 memory="32GB"
}
```

While someone uses the PC, runs share what's left after 8 CPUs and 32 GB. When nobody has used it for 5 minutes, runs get the whole PC back.

### Keep runs' output longer

```kdl
retention output="30d"
```

`proof logs` works for a run's output for 30 days. The `runs` and `artifacts` values keep their defaults.

### Build two branches of a public repository

```kdl
repository lota url="https://github.com/setdef/Lota.git" {
  branch trunk release
  task test
}
```

Every commit pushed to `trunk` or `release` gets runs of `test`. A public repository needs no `credentials-file`.

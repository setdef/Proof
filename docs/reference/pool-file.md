# Pool file reference

The pool file is `~/.config/proof/pool.kdl`, on the computer that runs the **server**, or `$XDG_CONFIG_HOME/proof/pool.kdl` when `XDG_CONFIG_HOME` is set to an absolute path in the server's environment. It describes the whole **pool**: each **host**, with its disk **budget**, the **share** of its CPUs and memory that Proof keeps free for a **person**, and any **labels** it must not offer; each repository whose pushed commits Proof runs tasks on; and how long the server keeps runs. Words in bold are defined in the [glossary](../glossary.md).

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

The server listens on port 7443. It keeps each run's record for 90 days, its output for 14 days, and its artifacts for 7 days, and it keeps at most 1 GB of output and 16 GB of artifacts from any one run. On `nuc`, Proof may use 400 GB of disk. On `pc`, Proof may use 250 GB, keeps 16 GB of memory free always and 4 CPUs free while someone is active there, and never offers the PC's GPU to a task. Every commit pushed to Lota's `trunk` branch gets a run of its `test` and `package` tasks.

## What happens when the file has a mistake

The server checks the whole file before it uses any of it. When the file has a mistake, the server keeps running with the last version that had none, and `proof status` shows the mistake, with its line, until you fix it. A file the server can't read, such as one that isn't there, is a mistake too.

A server that starts with a mistake in the file runs no runs until you fix it. It still listens on the file's `server port` when the `server` node itself has no mistake, so every computer and runner set to that port can see the mistake, and on port 7443 only when it can't read the port.

The pool file is [KDL](https://kdl.dev/) 2.0, so a repeated property keeps only its last value, and a size such as `4GB` needs quotes. The [project file reference](project-file.md#mistakes-proof-catches-and-one-it-cant) shows both mistakes with their fixes.

Proof refuses a pool file, with the line and the reason, when:

- a node, property, or child isn't one this page lists, or a property is written as a child, as in `server { port 7443 }`, or a child as a property, as in `host nuc budget="400GB"`: the message says how to write it;
- a node has a different number of arguments than the page shows, such as a `budget` with two sizes;
- a `host` has no `runner`, or has no `budget` in its entry or in `defaults`, or a `repository` has no `url`, no `branch`, or no `task`;
- `server`, `retention`, `limits`, or `defaults` is given twice, or a child is given twice in one entry, except `runner` and `task`, which can be written in several nodes: give every other child's values as arguments to one node, as in `branch trunk release`;
- two hosts have one name, two repositories have one name, a runner is on two hosts or twice on one, or a repository lists a branch or a task twice;
- the name of a host, a runner, a repository, a branch, or a task, a repository's `url`, or a `credentials-file`'s path is empty or only white space;
- a `port` isn't a whole number from 1 to 65535, or `cpus` isn't a whole number from 0.

Proof compares the names of hosts, runners, and repositories without regard to case, as it does labels, so `nuc` and `NUC` are one host, and a second entry for it is refused. Each name is shown as its entry writes it. Branch and task names compare as written, as Git and mise compare them.

## Sizes and labels

A size in the pool file, in `budget`, `keep-free`, `share`, or `limits`, is a number, an optional space, and a unit: `MB`, `GB`, `TB`, `MiB`, `GiB`, or `TiB`, in any case, all counted in 1,024s. The number is whole or decimal, and a size that isn't a whole number of megabytes rounds up to the next whole megabyte. A budget can run to terabytes. The [project file reference](project-file.md#sizes) gives the whole rule.

| Written | Result |
| --- | --- |
| `budget "1.5TB"` | Valid: 1,572,864 MB. |
| `keep-free "50 GiB"` | Valid: 51,200 MB. |
| `limits output="512mb"` | Valid: 512 MB. |
| `share cpus=2 memory="0.1GB"` | Valid: 103 MB, rounded up from 102.4 MB. |
| `budget "400G"` | Refused: `G` isn't a unit. |
| `budget 400GB` | Refused: KDL reads `400GB` as the number 400 followed by `GB`. |
| `keep-free "25 GB "` | Refused: at most one space, between the number and the unit. |

A label in `withhold` is 1 to 63 characters: ASCII letters, digits, `-`, `_`, and `.`, beginning and ending with a letter or a digit, with no space. Proof compares labels without regard to case, so `withhold GPU` withholds `gpu` too. The [project file reference](project-file.md#labels) gives the whole rule.

| Written | Result |
| --- | --- |
| `withhold gpu desktop` | Valid. |
| `withhold GPU` | Valid, and the same as `withhold gpu`. |
| `withhold "nvidia gpu"` | Refused: a label has no space. |
| `withhold gpu-` | Refused: a label ends with a letter or a digit. |

A size or a label that breaks its rule is a mistake in the file, and [what happens when the file has a mistake](#what-happens-when-the-file-has-a-mistake) applies, with the forms that work in the message.

## Durations

A duration in `active-for` and `poll` is a whole number from 1 and one of `s`, `m`, or `h`, in lowercase, with no space. In `retention`, a duration is a whole number of days, with the unit `d`. The [project file reference](project-file.md#durations) gives the whole rule.

| Written | Result |
| --- | --- |
| `active-for "5m"`, `poll "90s"` | Valid. |
| `retention output="30d"` | Valid. |
| `active-for "1h30m"` | Refused: a duration has one unit. |
| `poll "1.5m"` | Refused: the number is whole. |
| `active-for "5 m"` | Refused: no space. |
| `active-for "5M"` | Refused: the unit is lowercase. |
| `active-for "1d"` | Refused: `d` is the unit of `retention` only. |
| `retention output="14h"` | Refused: `retention` takes days. |

A duration that breaks its rule is a mistake in the file, and [what happens when the file has a mistake](#what-happens-when-the-file-has-a-mistake) applies, with the forms that work in the message.

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
| `artifacts` | `"16GB"` | The most artifacts the server keeps from one run. A run whose artifacts would exceed it fails with exit status 78, and the message says how large they were. The server also needs this much free space when a run starts: with less, the run fails before its command starts, with exit status 78, and the message says the server is short of space. |

## `defaults`

```kdl
defaults {
  budget "100GB"
  share cpus=2 memory="4GB"
  active-for "5m"
}
```

The settings every `host` gets unless its entry has a different value. It takes the same children as a `host`, except `runner`. A `withhold` in `defaults` and a `withhold` in a host add up, so the host withholds the labels of both.

## `host`

```kdl
host NAME {
  runner RUNNER...
  budget "SIZE"
  keep-free "SIZE"
  share cpus=N memory="SIZE"
  active-for "DURATION"
  withhold LABEL...
}
```

One entry for each physical computer. `proof status` shows the host under `NAME`. `proof runner approve` writes the entry with the host's runners and its budget, so the host starts with the other settings in `defaults`.

| Child | Default | Meaning |
| --- | --- | --- |
| `runner` | Required. Written by `proof runner approve` | The runners on this host. The server counts their CPUs and memory as one host's, so the server never gives a Windows PC and its WSL more runs together than the PC can run. A run must also fit the runner's capacity: WSL can have less memory than the PC, and the server doesn't place a run on the WSL runner that doesn't fit what WSL has. |
| `budget` | Required, in the entry or in `defaults`. `proof runner approve` writes half the host's free disk space into the entry when it adds the host | The disk space Proof may use on this host for workspaces and caches. When Proof's files exceed it, the host's runners delete the workspaces used least recently, never one in use. |
| `keep-free` | `"25GB"` | The disk space the host's runners always leave free, whatever the budget, so a disk that fills for other reasons never fills completely because of Proof. |
| `share` | `cpus=2 memory="4GB"` | The CPUs and memory Proof keeps free on this host for a person. The memory is free always, and the CPUs only while a person is active there. Runs go on with the rest, and runs that need the person's display, GPU, or speakers wait. |
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

A repository whose pushed commits Proof runs tasks on, in place of hosted CI. `proof status` shows its runs under `NAME`.

| Child or property | Default | Meaning |
| --- | --- | --- |
| `url` | Required | The repository's clone URL. The server fetches from it; runners never do. |
| `credentials-file` | None | A file holding a read-only token for the repository, for a private one. The server reads the token from this file and never from the pool file itself. |
| `branch` | Required | The branches to watch. The server runs the tasks on each new commit on them. |
| `task` | Required | The tasks to run on each new commit. Each task runs once on every operating system listed for it in the project file, so a task that works on Linux and macOS gets two runs per commit. |
| `poll` | `"1m"` | How often the server fetches the branches. |

The tasks come from the commit they run on: its `mise.toml` and its `.config/proof.kdl`. A commit that changes a task's operating systems changes where that commit's runs go.

## Examples

### Keep more of the PC free for someone who games on it

```kdl
host pc {
  runner pc-windows
  runner pc-wsl
  share cpus=8 memory="32GB"
}
```

Runs never use 32 GB of the PC's memory, whether or not anyone is there. While someone uses the PC, runs also leave 8 CPUs free and share what's left. When nobody has used it for 5 minutes, runs can use all the CPUs again, and the 32 GB stays free.

### Keep runs' output longer

```kdl
retention output="30d"
```

`proof logs` works for a run's output for 30 days. The `runs` and `artifacts` values keep their defaults.

### Run tasks on two branches of a public repository

```kdl
repository lota url="https://github.com/setdef/Lota.git" {
  branch trunk release
  task test
}
```

Every commit pushed to `trunk` or `release` gets runs of `test`. A public repository needs no `credentials-file`.

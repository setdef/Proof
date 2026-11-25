<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Project file reference

The project file is `.config/proof.kdl`, at the root of a project's Git repository. It contains what only Proof needs to know about the project's **tasks**: which operating systems each one works on, which **labels** it needs a runner to have, the **resources** it requests, its time limit, the files to keep from its runs as **artifacts**, and the folders to keep between its runs as **caches**. It can also define tasks that the project's `mise.toml` doesn't have. Words in bold are defined in the [glossary](../glossary.md).

The file is optional. Without it, `proof run NAME` runs `mise run NAME` with Proof's built-in defaults, on any operating system with a runner free. Someone who doesn't use Proof can leave the file alone: no other tool reads it.

The examples on this page are from [Lota](https://github.com/setdef/Lota), a Ruby library for 2D games, which has two tasks in its `mise.toml`: `test`, which runs `bundle exec rake test`, and `package`, which runs `bundle exec rake package:native`.

## A complete example

```kdl
defaults cpus=4 memory="8GB" timeout="45m" {
  os linux macos windows
  cache "tmp/engine/build"
}

task test {
  label desktop
}

task package {
  artifact "pkg/*.gem"
}

task docs "bundle exec rake rdoc" {
  os linux
  artifact "doc/api/**"
}
```

Every task in this file works on all three operating systems, requests 4 CPUs and 8 GB of memory, ends after 45 minutes, and keeps its `tmp/engine/build` folder between runs. The `test` task also needs a runner that can open windows. The `package` task keeps the gems it builds. The `docs` task isn't in Lota's `mise.toml`: Proof runs its command, `bundle exec rake rdoc`, on Linux only, and keeps the generated API docs.

## Where Proof reads the file

Proof reads `.config/proof.kdl` from what it sends, not from your disk: from the working tree when you run `proof run`, and from the commit when you run `proof run --commit REV`. A change to the project file is in effect for the next run, committed or not.

Proof reads only this one file. It never reads a project file from a subfolder, from your home folder, or from another `.config` file, and nothing in `mise.toml` overrides it.

The file is [KDL](https://kdl.dev/) 2.0. Proof reads it before it sends anything, and refuses the run with exit status 2 when the file has a mistake, naming the file, the line, and what's wrong.

## How values combine

For each value of a run, Proof uses the first of these that has it:

| Source | Example |
| --- | --- |
| A flag on `proof run` | `--memory 16GB` |
| The task's entry in the project file | `task test memory="12GB"` |
| The `defaults` node | `defaults memory="8GB"` |
| Proof's built-in defaults | Any operating system, 2 CPUs, 4 GB, 60 minutes |

Lists combine differently from single values:

- **`os`** replaces: a task's `os` replaces the `defaults` node's `os`, and `--os` replaces both.
- **`label`, `artifact`, and `cache`** add: a task's entries add to those in `defaults`, and `--label` and `--keep` add to both.

## `defaults`

```kdl
defaults cpus=4 memory="8GB" timeout="45m" {
  os linux macos windows
}
```

The values every task gets unless its entry or a flag has another. A file has at most one `defaults` node. It takes the same properties and children as a `task`, except a command.

## `task`

```kdl
task NAME [COMMAND] [cpus=N] [memory="SIZE"] [timeout="DURATION"] {
  os OS...
  label LABEL...
  artifact PATTERN...
  cache PATH...
}
```

One entry per task. `NAME` is the name you run with `proof run NAME`.

- **Without `COMMAND`,** the entry adds Proof's settings to the mise task of the same name, and Proof runs `mise run NAME` on the runner.
- **With `COMMAND`,** the entry defines a task with that command. Proof runs `COMMAND` from the root of the workspace, with `sh -o errexit -c` on Linux and macOS and with `cmd /c` on Windows, the same shells mise uses for its tasks by default. A mise task with the same name is then not run.

A task that's neither in the project file nor in `mise.toml` fails on the runner with mise's error message, and `proof` exits with that run's status.

A name can appear in only one `task` entry. Task names follow mise's rules, so `test`, `lint:ruby`, and `package-native` are all valid.

### Properties

| Property | Value | Built-in default | Meaning |
| --- | --- | --- | --- |
| `cpus` | A whole number from 1 | `2` | The CPUs the task requests. The server places a run only on a host with this many CPUs free. |
| `memory` | A quoted size, such as `"512MB"` or `"8GB"` | `"4GB"` | The memory the task requests. The server places a run only where this much is free, and the runner holds the run to it. |
| `timeout` | A quoted duration, such as `"90s"`, `"30m"`, or `"2h"` | `"60m"` | How long a run may take. After this long, the runner ends the run, and its state is `timed_out`. |

A size counts 1 GB as 1,024 MB. A request larger than every host in the pool has is refused before anything is sent, with the largest host's size in the message.

### Children

| Child | Arguments | Meaning |
| --- | --- | --- |
| `os` | One or more of `linux`, `macos`, `windows` | The operating systems the task works on. Without `os`, a task can run on any of them. `proof run NAME` with no `--os`, and with `--os any`, places the run on whichever of these has a runner free; `--os all` runs once on each. |
| `label` | One or more labels, such as `gpu`, `kvm`, or `desktop` | The labels a runner must have to run the task. The [pool file](pool-file.md) can withhold a label from a host. |
| `artifact` | One or more file patterns, relative to the workspace's root | The files to keep after a run succeeds. `*` matches within a folder and `**` matches across folders. A pattern that matches no file makes the run fail with exit status 78. |
| `cache` | One or more folders, relative to the workspace's root | Folders to keep between the project's runs on a runner, saved only after a run succeeds. |

## Mistakes Proof catches, and one it can't

Proof refuses a project file, with the line and the reason, when:

- a node or property isn't one this page lists;
- a value has the wrong type, such as `cpus="four"`;
- an `os` node lists an operating system other than `linux`, `macos`, or `windows`;
- two `task` entries have the same name;
- a `cache` or `artifact` path starts with `/` or contains `..`.

> [!WARNING]
> A repeated property keeps only its last value, and that is valid KDL, so Proof can't tell it apart from what you meant. Give a list as arguments to a child node instead.
>
> ```kdl
> // Wrong: this task works on Windows only.
> defaults os=linux os=macos os=windows
>
> // Right:
> defaults {
>   os linux macos windows
> }
> ```

KDL also needs quotes around a value that starts with a digit and continues with letters:

```kdl
// Wrong: a KDL parser reads 8GB as the number 8 followed by GB, and Proof refuses the file.
task package memory=8GB

// Right:
task package memory="8GB"
```

## Several tasks on one command line

The words after a task's name go to `mise run` on the runner as they are, so `proof run lint ::: test` runs both tasks in one run, as `mise run lint ::: test` would: in parallel, unless one task lists another in its `depends` in `mise.toml`. When a command line names several tasks, the run gets settings that suit all of them:

| Setting | For several tasks |
| --- | --- |
| `os` | The operating systems every one of them works on |
| `label` | Every label any of them needs |
| `cpus`, `memory`, `timeout` | The largest of their values |
| `artifact`, `cache` | All of them |

When the tasks have no operating system in common, Proof refuses the run before sending anything, and lists each task's operating systems.

## Tasks without a project file

| You run | Without a project file | With the complete example on this page |
| --- | --- | --- |
| `proof run test` | Runs `mise run test` on any operating system with a runner free, with 2 CPUs, 4 GB, and 60 minutes. | Runs `mise run test` on whichever operating system has a runner free that can open windows. |
| `proof run test --os linux` | Runs `mise run test` on Linux, with 2 CPUs, 4 GB, and 60 minutes. | Runs `mise run test` on Linux, with 4 CPUs, 8 GB, and 45 minutes, on a runner that can open windows. |
| `proof run docs --os linux` | Fails on the runner: mise has no `docs` task. | Runs `bundle exec rake rdoc` on Linux and keeps `doc/api/**`. |

## Examples

### Request more memory for one task

```kdl
task package memory="12GB"
```

The `package` task requests 12 GB. Every other value comes from `defaults` or Proof's built-in defaults.

### A task for one operating system

```kdl
task ios "bin/test-ios" {
  os macos
  label desktop
}
```

`proof run ios` waits for a Mac whose runner can open windows. `proof run ios --os linux` runs it on Linux anyway, and the first line of the run says so, since naming an operating system on the command line is how you try a task somewhere it hasn't run before.

### Keep the gems a build makes, and download them

```kdl
task package {
  artifact "pkg/*.gem"
}
```

`proof run package --os linux --download` builds on Linux and copies the gem into the project's `pkg` folder.

### Keep a compiler cache between runs

```kdl
defaults {
  cache ".cache/ccache"
}
```

Each runner keeps `.cache/ccache` for the project's next run there. Point the compiler's cache at that folder in the task's command; Proof doesn't set any tool's cache location for you.

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
| `memory` | A quoted [size](#sizes), such as `"512MB"`, `"8GB"`, or `"1.5 GiB"` | `"4GB"` | The memory the task requests. The server places a run only where this much is free, and the runner holds the run to it. |
| `timeout` | A quoted [duration](#durations), such as `"90s"`, `"30m"`, or `"2h"` | `"60m"` | How long a run may take. After this long, the runner ends the run, and its state is `timed_out`. |

A request larger than every host in the pool has is refused before anything is sent. The message says which host fits the most of the request, the one whose worst shortfall is the smallest, and lists every resource that host lacks, with what it could ever have free and what the task requests.

### Sizes

A size is a number, an optional space, and a unit. Proof reads the same sizes everywhere a file or a flag takes one: `memory` here, and the budget, the share, and the limits in the [pool file](pool-file.md).

- **The number** is whole, such as `8`, or decimal with digits on both sides of the point, such as `1.5`. It has no sign, no exponent, and no thousands separator.
- **The space** is none or one space, so `8GB` and `8 GB` are the same size.
- **The unit** is `MB`, `GB`, or `TB`, or `MiB`, `GiB`, or `TiB`, in any case, so `gb` and `Gb` work. Proof counts every unit in 1,024s, so `MB` and `MiB` are the same unit, `1GB` is 1,024 MB, and `1TB` is 1,048,576 MB.
- **A size that isn't a whole number of megabytes** rounds up to the next whole megabyte, so a request is never smaller than what you wrote: `"0.1GB"` is 0.1 × 1,024 = 102.4 MB, which rounds up to 103 MB.

When a size breaks these rules, Proof refuses it with the forms that work.

| Written | Size | Note |
| --- | --- | --- |
| `"512MB"` | 512 MB | |
| `"8GB"`, `"8 GB"`, `"8gb"`, `"8GiB"` | 8,192 MB | One size, written four ways. |
| `"1.5GB"` | 1,536 MB | |
| `"0.1GB"` | 103 MB | Rounded up from 102.4 MB. |
| `"1TB"` | 1,048,576 MB | |
| `"0GB"` | 0 MB | Valid: a host's share can keep nothing free. |
| `8GB`, unquoted | Refused | KDL reads `8GB` as the number 8 followed by `GB`. |
| `"8"` | Refused | A size needs a unit. |
| `"8G"`, `"8 gigabytes"` | Refused | `G` and `gigabytes` aren't units. |
| `"1,5GB"`, `".5GB"`, `"5.GB"` | Refused | A decimal has digits on both sides of a point. |
| `"1e3MB"`, `"-1GB"`, `"+1GB"` | Refused | No exponent and no sign. |
| `"8  GB"`, `" 8GB"`, `"8GB "` | Refused | At most one space, between the number and the unit. |

### Durations

A duration is a whole number from 1 and one unit. Proof reads the same durations everywhere a file or a flag takes one: `timeout` here and `--timeout` on `proof run`, and `active-for` and `poll` in the [pool file](pool-file.md). The pool file's `retention` takes days.

- **The number** is whole and starts at 1, with no leading zero, no sign, and no fraction.
- **The unit** is `s` for seconds, `m` for minutes, or `h` for hours, in lowercase. `retention` takes `d` for days instead.
- **There is one number and one unit,** with no space between them.

When a duration breaks these rules, Proof refuses it with the forms that work.

| Written | Result |
| --- | --- |
| `"90s"`, `"30m"`, `"2h"` | Valid. |
| `"1h30m"` | Refused: a duration has one unit. |
| `"1.5h"` | Refused: the number is whole. |
| `"90 s"` | Refused: no space. |
| `"2H"`, `"30M"` | Refused: the unit is lowercase. |
| `"1d"` | Refused for a time limit: `d` is the unit of `retention` only. |
| `"01m"`, `"0m"` | Refused: the number starts at 1, with no leading zero. |
| `"90"` | Refused: a duration needs a unit. |
| `30m`, unquoted | Refused: KDL reads `30m` as the number 30 followed by `m`. |

### Children

| Child | Arguments | Meaning |
| --- | --- | --- |
| `os` | One or more of `linux`, `macos`, `windows` | The operating systems the task works on. Without `os`, a task can run on any of them. `proof run NAME` with no `--os`, and with `--os any`, places the run on whichever of these has a runner free; `--os all` runs once on each. |
| `label` | One or more [labels](#labels), such as `gpu`, `kvm`, or `desktop` | The labels a runner must have to run the task. The [pool file](pool-file.md) can withhold a label from a host. |
| `artifact` | One or more file patterns, relative to the workspace's root | The files to keep after a run succeeds. `*` matches within a folder and `**` matches across folders. A pattern that matches no file makes the run fail with exit status 78. |
| `cache` | One or more folders, relative to the workspace's root | Folders to keep between the project's runs on a runner, saved only after a run succeeds. |

### Labels

A label is 1 to 63 characters: ASCII letters, digits, `-`, `_`, and `.`, beginning and ending with a letter or a digit. It has no space. Proof compares labels without regard to case, so `GPU` and `gpu` are one label, and a task that asks for one matches a runner that offers the other. The same rule holds for `--label` and for `withhold` in the [pool file](pool-file.md).

| Written | Result |
| --- | --- |
| `gpu`, `kvm`, `desktop` | Valid. |
| `GPU` | Valid, and the same label as `gpu`. |
| `cuda-12.4`, `nested_kvm`, `a` | Valid. |
| `"4k"` | Valid. KDL needs quotes around a value that starts with a digit. |
| `"gpu "`, `" gpu"`, `"nvidia gpu"` | Refused: a label has no space. |
| `-gpu`, `gpu-`, `.gpu`, `gpu_` | Refused: a label begins and ends with a letter or a digit. |
| `gpu!`, `"gpu/2"`, `gpu:2` | Refused: `!`, `/`, and `:` aren't characters a label has. KDL needs quotes around `gpu/2`. |
| A name of 64 or more characters | Refused: a label has at most 63. |
| A name with an accented letter | Refused: only ASCII letters count. |
| `""` | Refused: a label has at least one character. |

Proof refuses a label that breaks the rule, so a stray space or symbol becomes an error, not a run that waits for a runner that can't have the label.

## Mistakes Proof catches, and one it can't

Proof refuses a project file, with the line and the reason, when:

- a node or property isn't one this page lists, as when `os=linux` is written as a property: `os` is a child node, and the message says how to write it;
- a value has the wrong type, such as `cpus="four"`;
- an `os` node lists an operating system other than `linux`, `macos`, or `windows`;
- a `label` breaks the [label rule](#labels), a size breaks the [size rule](#sizes), or a duration breaks the [duration rule](#durations);
- two `task` entries have the same name, or a `task` has a blank name;
- a task's command is empty or only spaces;
- a child node is given twice in one entry, such as two `os` nodes: give every value as arguments to one node;
- a child node has no arguments, such as a bare `label`: each takes one or more;
- a `cache` or `artifact` path starts with `/` or contains `..` anywhere, so `v1..2.txt` is refused too. A Windows path such as `C:\x` isn't refused, because only a leading `/` makes a path absolute here;
- `.config/proof.kdl` is committed as a symbolic link: Proof reads only a regular file there.

> [!WARNING]
> A repeated property keeps only its last value, and that is valid KDL, so Proof can't tell it apart from what you meant. Don't repeat a property. And `os` is a child node, not a property: Proof refuses it written as one, and says how to write it.
>
> ```kdl
> // Wrong, and Proof doesn't catch it: the task requests 4 CPUs, because the second cpus replaces the first.
> task test cpus=2 cpus=4
>
> // Wrong, and refused: os is a child node, not a property.
> defaults os=linux os=macos os=windows
>
> // Right: give a list as arguments to a child node.
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

Words for a task follow `--` and go to `mise run` on the runner as they are. `:::` starts the next task, so `proof run lint ::: test` runs both tasks in one run, as `mise run lint ::: test` would: in parallel, unless one task lists another in its `depends` in `mise.toml`. When a command line has several tasks, the run gets settings that suit all of them:

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

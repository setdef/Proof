<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Run a task on several operating systems

Once a pool has hosts with more than one operating system, a task can run on any of them. This guide makes a project's setup work on Linux, macOS, and Windows alike, and says where each task works, so Proof never places a run where it can't succeed.

## Where a task runs by default

Without `--os` and without a [project file](../reference/project-file.md), `proof run test` goes to any operating system with a runner free. A project whose tests only work on Linux would then sometimes land on Windows and fail in setup: a `bundle install` that needs a C compiler, or a setup step that calls `bash`. You have two ways to deal with that, and most projects use both: write setup that works everywhere, and list the operating systems each task works on.

Such a failure is a real fault, not bad luck: a collaborator on that operating system would hit it the first time they ran the task. Proof places tasks on any operating system by default so that you find it first.

## Write setup that works everywhere

mise runs a task's `run` line with `sh` on Linux and macOS and with `cmd` on Windows, so a shell one-liner that works in one fails in the other. Write setup in a language the project already pins in `mise.toml`, and have the task run it through `mise x`, which runs a command with the project's tools on `PATH`:

```toml
[tools]
ruby = "3.4"

[tasks.setup]
run = "mise x -- ruby bin/setup.rb"

[tasks.test]
depends = ["setup"]
run = "bundle exec rake test"
```

`bin/setup.rb` runs the same way on every operating system, and can branch where they differ:

```ruby
system("bundle", "install", exception: true)

if Gem.win_platform?
  # Install what only the Windows build needs here.
end
```

A Node.js project does the same with `mise x -- node scripts/setup.mjs`. Many projects need no setup task at all: `mise run` installs the tools `mise.toml` pins before it runs a task.

## List where each task works

For a task that works on some operating systems and not others, say which in `.config/proof.kdl`:

```kdl
defaults {
  os linux macos windows
}

task package {
  os linux macos windows
  artifact "pkg/*.gem"
}

task "test:gui" {
  os linux macos
  label desktop
}
```

Now `proof run test:gui` never goes to Windows, and `proof run test:gui --os all` runs once on Linux and once on macOS, in parallel, exiting with the worse of the two statuses.

## Try a task somewhere new

To find out whether a task works on an operating system it isn't listed for, name it:

```console
$ proof run test --os windows
```

Naming an operating system on the command line overrides the project file for that run, and the first line of the run says so. When the run passes, add the operating system to the task's `os` in the project file.

## Check every operating system before a release

`--os all` runs a task once on every operating system it works on. Use it, with `--commit`, before you tag a release:

```console
$ proof run package --os all --commit v1.4.0 --download
```

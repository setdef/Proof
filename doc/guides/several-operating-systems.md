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

<!-- skip-example: runs bundle install and checks the operating system -->
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

Now `proof run test:gui` never goes to Windows, and `proof run test:gui --os all` runs once on Linux and once on macOS, in parallel. [Exit status with several runs](#exit-status-with-several-runs) says which status `proof` exits with.

## Exit status with several runs

With several runs, from several `--os` flags or from `--os all`, `proof` exits with one status: the first of these that applies.

| Order | Status | When | Why it comes here |
| --- | --- | --- | --- |
| 1 | 130, 141, or 143 | Proof canceled the runs: you pressed Ctrl-C, standard output was closed, or Proof received `TERM`. | The whole command was stopped, so no status says how the tasks fared. |
| 2 | The status of the first failing run | A task failed. | A task's failure is a definite answer that running again won't change. |
| 3 | 78 | A run succeeded, but Proof couldn't keep its artifacts. | A mistake in configuration, which a person has to fix. |
| 4 | 75 | The pool failed after Proof sent the runs. | Running again may fix it. |
| 5 | 0 | Every run succeeded. | |

"First" follows the order of the `--os` flags, not the order the runs finish. With `--os all`, the order is `linux`, `macos`, `windows`. A refusal, status 2, comes before anything is sent, so it never mixes with these.

For example, when the `test` task fails with 1 on Linux and times out with 124 on Windows, the status depends on the order of the flags:

```console
$ proof run test --os linux --os windows
$ echo $?
1
$ proof run test --os windows --os linux
$ echo $?
124
```

A status of 75 means no run failed but the pool lost at least one, so run the same command again.

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

# Editing .config/proof.kdl

Read this before you create or change a project's `.config/proof.kdl`. The file holds what only Proof needs to know about the project's tasks; the tasks themselves are usually in `mise.toml`. It's [KDL](https://kdl.dev/) 2.0.

## Shape

```kdl
defaults cpus=4 memory="8GB" timeout="45m" {
  os linux macos windows
  cache "node_modules"
}

task test {
  label desktop sound
}

task package {
  artifact "pkg/*.gem"
}

task docs "bundle exec rake rdoc" {
  os linux
  artifact "doc/api/**"
}
```

- `defaults` holds values for every task. A file has at most one.
- `task NAME` adds Proof's settings to the mise task of that name. `task NAME "COMMAND"` defines a task mise doesn't have; Proof runs the command with `sh -o errexit -c` on Linux and macOS and `cmd /c` on Windows.
- Properties: `cpus` (a whole number), `memory` (a quoted size such as `"8GB"`), `timeout` (a quoted duration such as `"30m"`).
- Children: `os` (any of `linux`, `macos`, `windows`), `label` (such as `gpu`, `kvm`, `desktop`, `sound`, `podman`, `xcode`), `artifact` (file patterns to keep after a run passes), `cache` (folders to keep between runs).
- A task's `os` replaces the `defaults` `os`. Its `label`, `artifact`, and `cache` add to the defaults. Values on the command line win over both.
- Without any `os`, a task runs on any operating system.

## Two mistakes that look valid

A repeated property keeps only its last value, and KDL accepts it, so Proof can't tell you meant a list. Give a list as arguments to a child:

```kdl
// Wrong: this means windows only.
defaults os=linux os=macos os=windows

// Right:
defaults {
  os linux macos windows
}
```

A value that starts with a digit and continues with letters needs quotes:

```kdl
// Wrong: Proof refuses the file, because 8GB isn't a KDL value.
task package memory=8GB

// Right:
task package memory="8GB"
```

## After you edit it

Run the task with `proof run`: Proof reads the file from what it sends, so your edit counts at once, committed or not, and a mistake in it stops the run with exit status 2 and the line that's wrong.

Tell the human what you changed in the file and why, in the same message as the change: Proof places every run of the project by what the file says, so a wrong `os` or `label` sends other people's runs astray.

- Don't declare a build's output folder (`target`, `build`, `dist`) as a `cache`: leftovers from another commit can make a run pass that should fail. Dependency folders and compiler caches are the right kind.
- Don't raise `memory` or `timeout` to make a failure go away without telling the human what the run held or how long it took.

# Keep and download artifacts

Keep files a run makes, such as a built package or a test report, download them to the computer you work on, and give them to another run. The examples use [Lota](https://github.com/setdef/Lota), whose native extension builds only for the operating system it builds on.

## Keep files from a run

Name the files to keep in the project file, so every run of the task keeps them:

```kdl
task package {
  artifact "pkg/*.gem"
}
```

Or for one run, on the command line:

```console
$ proof run package --os linux --keep 'pkg/*.gem'
```

Patterns are relative to the project's root: `*` matches within a folder, and `**` matches across folders. Quote a pattern on the command line, so your shell doesn't expand it first.

A run keeps its artifacts only when it succeeds. When the command exits with 0 but a pattern matches no file, the run is `failed` and `proof` exits with 78, because a pattern that matches nothing is almost always a mistake: a path that changed, or a build that put its output somewhere else.

## Download them

Add `--download` to a run, and Proof copies its artifacts into the project's folder, at the same paths, when the run succeeds:

```console
$ proof run package --os linux --os windows --download
```

Or download them later, by the run's ID:

```console
$ proof download m3d8q
proof: downloaded pkg/lota-0.0.1.dev-x86_64-linux-gnu.gem from run m3d8q to ./pkg/
```

`--output DIR` puts them in another folder. Give patterns after the ID to download only some:

```console
$ proof download m3d8q 'pkg/*-linux-gnu.gem' --output dist
```

Proof checks each file against the SHA-256 the runner recorded, and refuses a file that doesn't match. It never overwrites a file you have without saying which.

## Give them to another run

Another run can take an earlier run's artifacts as **inputs**, on the same operating system or another. For example, build the Linux gem, then install and test it in a clean environment:

```console
$ proof run package --os linux
proof: exit=0 run=20261125-0336-m3d8q task=package runner=nuc-linux queued=0s ran=0s artifacts=1
$ proof run install-test --os linux --input m3d8q
```

The second run finds the first run's artifacts in the folder named by its `PROOF_INPUTS` variable, under the earlier run's ID: `$PROOF_INPUTS/20261125-0336-m3d8q/pkg/lota-0.0.1.dev-x86_64-linux-gnu.gem`.

To give a run a file from your computer instead, such as a large data file the tests need, use `--input-file`:

```console
$ proof run test --input-file fixtures/large-sample.db
```

The run finds it at `$PROOF_INPUTS/files/large-sample.db`.

## How long artifacts last

The server keeps artifacts for 7 days, and at most 16 GB from one run, unless the [pool file](../reference/pool-file.md) says otherwise. After that, `proof download` says when they were deleted. Download what you want to keep.

The server checks that limit and its free space when a run starts, and reserves no space for the run. Two runs that each fit can together fill the server's disk, and the second then fails when its artifacts arrive.

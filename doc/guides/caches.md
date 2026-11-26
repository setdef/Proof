# Keep caches between runs

Make a project's runs faster by keeping what's slow to make again between them, and know when to start a run from nothing instead.

## What a runner keeps without asking

Each runner keeps a workspace per project and reuses it. Before each run, it updates the workspace to the run's commit and removes every file Git doesn't track, including ignored ones, so nothing a different commit built can change the result. What survives:

- the Git clone, so a run fetches only what changed;
- the tools mise installed, and anything else the project's setup installed in the run's home folder, such as Ruby gems installed with `gem install` or Bundler's default settings;
- one download cache per project, shared by its runs on the host, which mise and tools that honor `XDG_CACHE_HOME` use;
- the caches the project declares.

Folders inside the project that Git ignores, such as `node_modules`, `vendor/bundle`, `target`, or `build`, are removed before every run, unless the project declares them as caches.

## Declare a cache

In the project file, list the folders worth keeping, relative to the project's root:

```kdl
defaults {
  cache "node_modules" ".cache/ccache"
}
```

The runner keeps these folders between the project's runs on that runner, and saves them only after a run succeeds, so a failed run can't leave a broken cache behind.

Good candidates are folders that are slow to make and that tools check before they trust: dependency folders whose tool installs only what changed, such as `node_modules` with `npm install`, and compiler caches such as ccache or sccache, which compare each input before reusing an output. Point the tool at the folder in the task's command or its configuration; Proof doesn't set any tool's cache location.

> [!WARNING]
> Don't declare a build's output folder, such as `target` or `build`, as a cache unless the build tool checks every input before it reuses an output. A stale build output from another commit can make a run pass that fails from nothing, or fail when it should pass.

## Start from nothing

A reused workspace can hide a fault, such as a setup step that never installs what an earlier run left behind. Start a run in an empty workspace, with no clone, tools, dependencies, or caches, to see whether the project builds from nothing:

```console
$ proof run test --empty
```

An empty run is slower: it downloads and installs everything again. Use it before a release, or when a run fails in a way a fresh checkout wouldn't explain.

## How much disk it takes

Workspaces and caches count against the host's budget in the pool file. When Proof's files go over it, the runner deletes the workspaces used least recently, never one in use, and the next run there starts empty. `proof runner list` shows how much of each host's budget Proof uses.

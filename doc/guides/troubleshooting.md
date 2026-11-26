# When a run fails or waits

Find out why a run failed, waited, or never started, from what Proof prints, and what to put in an issue when that isn't enough.

## Start with the exit status

With one run, the last line `proof run` prints is the result, and `proof` exits with the status it shows. The status says whose problem it is:

| Status | What happened | What to do |
| --- | --- | --- |
| 0 | The task succeeded. | Nothing. |
| 2 | Proof refused the run and sent nothing: a mistake on the command line or in the project file, or a request no host can meet. | Read the message: it says what the mistake is. |
| 75 | The pool failed: a runner or its host went away, or Proof couldn't reach the server. | Run the same command again. If it keeps happening, check `proof status`. |
| 78 | The run succeeded, but Proof couldn't keep its artifacts: a `--keep` or `artifact` pattern matched no file, or the artifacts exceeded the pool's limit. | Fix the pattern, or the build that should have made the file, or keep fewer files. |
| 124 | The run reached its time limit. | Find what took so long with `proof logs RUN_ID`, or raise the task's `timeout`. |
| 130 | You pressed Ctrl-C, and Proof canceled the run. | Nothing. |
| 137 | The run held more memory than it requested while its host ran short, or was killed. | Raise the task's `memory` to what the message says it held. |
| 141 | Standard output was closed, as by a pipe into `head`, and Proof canceled the run. | Run `proof` without a pipe, and read the output afterward with `proof logs RUN_ID`. |
| 143 | Proof received `TERM`, as when an agent harness stops it, and canceled the run. | Nothing, unless the harness stopped it by mistake. |
| Anything else | The task's command exited with it. | Read the output: the failure is the task's. |

With several runs, such as `--os all`, `proof` exits with one status for all of them: [Exit status with several runs](several-operating-systems.md#exit-status-with-several-runs) gives the order.

When `proof` itself fails, it prints no result line, saves a debug log under `~/.local/state/proof/`, and prints a link to a new issue with the details filled in.

## Read the whole output

`proof logs RUN_ID` prints a run's whole output, for as long as the server keeps it. For a long output, read the end:

```console
$ proof logs r5c6t --tail 100
```

## A run waits in the queue

A queued run isn't hung. `proof status` says what each queued run is waiting behind:

| `proof status` says | Why it waits | What to do |
| --- | --- | --- |
| behind runs on its hosts | Every host that can run it is busy. | Wait, or add a host. |
| a person is active at its only host | The host keeps its share free for them, or the run needs their display, GPU, or speakers. | Wait until they stop, or add a host. |
| no runner of its operating system is connected | The hosts are asleep, off, or off the network, or a Mac with FileVault is waiting at its unlock screen after a restart. | Wake one, or unlock the Mac's disk. |
| a host needs signing in | A Windows runner needs its account signed in after a restart. A Mac runner needs it only for work that opens windows. | Sign the account in. |
| no runner offers a label it needs | No host has the hardware, or the runner hasn't found it. | Run setup on the host again, which says what's missing. |

`proof watch RUN_ID` picks the run up again from any terminal, and exits with its status when it ends. If you no longer have the run's ID, `proof status` lists your recent runs with theirs.

## A run fails in setup

A run that fails before the task's tests start usually fails in the project's setup: a tool mise can't install for that operating system, or a setup step that assumes another operating system's shell. Check whether the task is meant to run there; if it isn't, list where it works in the project file, as [Run a task on several operating systems](several-operating-systems.md) describes.

A run that passes in an empty workspace but fails in a reused one, or the other way around, has a fault the reuse hides or causes. Run it with `--empty` to see which.

## A run was lost

A run whose runner or host went away mid-run is `lost`, and `proof` exits with 75. Proof never runs it again by itself. Run it again; if the same host keeps losing runs, `proof status` shows when it last connected.

## Setup stops

Setup checks everything before it changes anything, and stops with a message saying what's missing: an administrator step, a group, a package, a signed-in session. Do what it says, and run setup again. Setup is safe to run any number of times.

## What to put in an issue

Open an issue at [github.com/setdef/Proof/issues](https://github.com/setdef/Proof/issues), with:

- the command you ran, and everything it printed;
- the output of `proof status`;
- the run's ID, and the output of `proof logs RUN_ID`;
- the debug log under `~/.local/state/proof/`, if `proof` printed that it saved one.

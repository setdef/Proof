# Check every push

Add a Git pre-push hook to a clone, so every `git push` from it runs a task on the commits being pushed, and Git stops the push when the run fails. Nothing leaves your computer that hasn't passed.

## Install the hook

In the clone, name the task the hook should run:

```console
$ proof hook install test
proof: installed .git/hooks/pre-push, which runs `proof run test` on each commit you push
```

The hook lives in the clone's `.git` folder, which Git never pushes, so it changes nothing for a collaborator or a fork. Install it in each clone where you want it, and in each linked worktree's main clone.

If the clone already has a pre-push hook that Proof didn't install, Proof leaves it in place and says so. Combine the two by hand, or pass `--force` to replace it.

## What a push does

```console
$ git push
proof: invoices at 4e7a0c2, task test
proof: run x8b3m on nuc-linux (reused workspace)
Run options: --seed 61204

# Running:

............................................

Finished in 2.398820s, 18.3424 runs/s, 41.6871 assertions/s.
44 runs, 100 assertions, 0 failures, 0 errors, 0 skips
proof: exit=0 run=20261125-0336-x8b3m task=test runner=nuc-linux queued=0s ran=6s
To github.com:example/invoices.git
   9b1e44a..4e7a0c2  main -> main
```

The hook runs the task once for each branch or tag you push, on the commit being pushed, with `--commit`, so uncommitted changes in your working tree don't count. When more than one ref is pushed, the runs go in parallel, and any failure stops the whole push.

A push of a new branch, or of a tag that points at a commit already checked, still runs the task: the hook checks what is pushed, not what changed.

## Skip the hook once

To push without the check, for example to share a branch that is known to fail:

```console
$ git push --no-verify
```

`--no-verify` is Git's, and skips every pre-push hook.

## When the pool can't run the task

If the pool fails, such as when the server can't be reached, the hook exits with 75 and Git stops the push, the same as for a failing run. Proof never lets a push through on a check that didn't happen. Run `git push` again once `proof status` shows the pool working, or skip the check once with `--no-verify`.

## Remove the hook

```console
$ proof hook uninstall
```

Proof removes only a hook it installed.

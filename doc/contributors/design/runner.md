# Runner design

What the runner must guarantee, and the traps between a design that looks right and one that is. How to meet each requirement is the implementer's choice. [How Proof works](../../how-proof-works.md) describes the behavior people see; this page is for the people building it. Each requirement here becomes an acceptance test.

## Time limits

- A run's time limit starts when its command starts. Time spent queued, setting up the workspace, or waiting for a desktop or for a person to leave doesn't count against it, and `proof` shows that waiting as it happens.

## A run's end

- **Nothing a run starts may outlive it.** This includes grandchildren, processes that left the command's process group, and daemons that forked themselves away.
- **Don't trust `timeout` to do it.** GNU coreutils' `timeout` and uutils' both return 124 and leave a child and grandchild that ignore `SIGTERM` running. GNU's `-k` kills the process group it's in, the runner included, so the runner dies with no status.
- **On Linux, a process that becomes the child subreaper (`prctl(PR_SET_CHILD_SUBREAPER)`) inherits orphans, and must reap them as they exit.** A zombie still answers `kill -0`, so a test that waits for a process to go away hangs forever when its parent's orphans aren't reaped.
- **macOS has no subreaper,** and `ps -E` doesn't show the environment of system programs. There, the process group and its descendants are what the runner can find. A program that clears its environment and double-forks out of the tree escapes on any system without cgroups.
- **Escalate in steps:** a time limit sends `TERM` (and `CONT`, for a stopped process), then `KILL` after a grace period. A cancel does the same. Report the processes that had to be killed.
- **The status of a run must come from the command,** never from a component that can lose evidence. A tracer or wrapper that exits 0 when the command was killed by a signal turns a failure into a pass.

## Memory

- A run must not be able to take its host down. A host that swaps hard stops answering the server, its other runs, and SSH, before the kernel's out-of-memory killer acts.
- Where a limit can be set without root, set it: a systemd user scope with `MemoryMax` on Linux (tested on Debian 13; it needs the account's user manager, so lingering must be on), a job object's memory limit on Windows (per Microsoft's documentation; untested). macOS has no limit an ordinary account can set: `RLIMIT_AS`, `RLIMIT_DATA`, and `RLIMIT_RSS` return `EINVAL` or aren't enforced (tested).
- Where no limit can be set, end a run only when it holds more than it requested **and** the host is short: on Linux, pressure stall information (`/proc/pressure/memory`) and available memory are the signals. A run within its request is never ended.
- Count a run's memory as its processes' proportional set size plus swap (`smaps_rollup`'s `Pss` and `SwapPss` on Linux), not resident size, which counts shared pages once per process.
- A run ended for memory has the state `out_of_memory`, exits 137, says what to request next time, and is never rerun.
- Runs start at a lower scheduling priority, and on Linux with a higher OOM score, so that the host's system services outlive them.
- A container's processes leave the run's process tree (Podman's `conmon` does), so a run's memory measurement misses them unless the container runs in the run's scope.

## Measuring a run

- Measure CPU time exactly from the child's accounting (`RUSAGE_CHILDREN`, or a job object's accounting on Windows), not by summing samples.
- Sample memory and CPU rate about once a second, and sample once at the start, so a command that ends in its first second is measured.
- The measuring must not be counted as the run's. A `ps` the runner starts for every sample costs measurable CPU when the host has a thousand processes.

## Output and status

- The runner owns the command's output pipe. It merges standard output and standard error in the order the command wrote them, because people and agents read a run top to bottom.
- It keeps a copy of the output, so output survives the loss of the connection to the server, and sends the copy when the connection returns. When the server has already made the run `lost`, it refuses the copy, and the runner still ends everything the run started and reports that it ended, so the server can release the host's resources.
- A run counts as `succeeded` only when the server has the whole output, as the runner counted it: its length, and an end marker after the last byte. Output that is cut off makes the run `lost`, whatever the exit status.
- No step may wait forever on a reader. A consumer that stops reading gets a bounded wait, then the runner says so and carries on.
- Bound every read: a command can print hundreds of megabytes in a second.

## A run's folders and environment

- **Home:** one per workspace, so tools that install into the home install there, and one writer at a time uses it. The home's Git configuration includes the account's, so identity settings still apply.
- **Temporary folder:** one per run, mode 700, exported as `TMPDIR` (and `TMP` and `TEMP` on Windows), and deleted when the run ends, including after a timeout or a cancel. Programs that write to `/tmp` directly ignore `TMPDIR`, so a shared `/tmp` still fills: it needs pruning of entries no process holds open, never of anything in use.
- **Unix socket paths** are limited to 104 bytes on macOS and 108 on Linux. A deep per-run folder breaks every tool that binds a socket in it.
- **Runtime folder (Linux):** one per workspace, under `/run/user/UID`, because Podman's network helper `pasta` may only use `/run/user/UID` or `/tmp` under Debian's and Ubuntu's AppArmor profiles, and a name under `/tmp` can be taken by another user first. Podman keeps the runtime folder its storage first used, so it must be the same for every run of a workspace.
- **Session bus (Linux):** a run gets a separate D-Bus session bus, and `SSH_AUTH_SOCK` is unset, so a run can't use the account's agent or keyring.
- **Environment:** `CI=true` unless the project's task sets it; Proof's variables named `PROOF_*`.
- **With `CI` set, mise loads the `[env]` of a `mise.toml` nobody has trusted on the runner,** and a project's own settings can't stop it (tested with mise 2026.11.14 on Debian 13). mise refuses such a file when `paranoid` is set in the runner account's global configuration, or when `MISE_SAFE` is set, so the runner's account must have neither. The runner relies on this instead of refusing it: Proof runs a project's tasks as the project defines them, and a run already runs the project's code, so mise loading the project's `[env]` gives it nothing a run doesn't already have.
- **mise is the latest release, on every runner at once.** A runner that updated mise only at setup would leave hosts set up months apart on different versions, so one commit could behave differently by host. Each Proof release requires a minimum mise version, as each Kamal release requires a minimum kamal-proxy version, and every runner updates mise to the latest release when Proof upgrades, or before its next run when its mise is older than that minimum.
- **Clean up at the start as well as at the end.** A runner killed outright never runs its cleanup, so the next run of the workspace removes the previous run's temporary and runtime folders first.

## Workspaces

- One run at a time per workspace. Concurrent runs of one project get separate workspaces, numbered, kept warm, and reused least recently used first.
- Before each run, update the workspace to the run's commit and remove every file Git doesn't track, ignored ones included (`git clean -ffdx`), keeping the project's declared caches.
- Write files byte for byte: turn off Git's line-ending and filter conversions for the workspace (`* -text -filter -ident`, `core.autocrlf=false`), so a run sees exactly the commit.
- **Mark a workspace as in use before the command starts,** and clear the mark when the run ends. A workspace that still has the mark when it's next leased was left by a run that was killed outright: half-written files and stale Git locks fail every later run there, so delete it and start empty, with a line saying so.
- **A broken workspace must not fail every run that leases it.** When Git operations on the workspace itself fail (a zeroed index, a stale lock), discard the workspace and retry the run once in another, and only before the run's command starts, so no command runs twice. A failure to fetch from the server is not the workspace's fault, and is `lost`.
- `--empty` reuses the least recently used free workspace, emptied, rather than making a new one, so repeated empty runs don't grow the number of workspaces without bound.
- Deleting a large workspace costs per file, not per byte. Leftovers written by rootless containers are owned by the account's subordinate IDs, so a plain delete fails: delete again inside the user namespace (`podman unshare rm -rf`), and never reuse a workspace that couldn't be emptied.
- Locks and prunes race with leases. A prune must never delete a workspace a lease has just taken, and must not follow a symbolic link a run planted out of the workspaces folder.

## Caches and the download cache

- The download cache is shared by a project's concurrent runs on a host. Tools whose caches aren't safe for concurrent writers corrupt it: write each entry to a temporary name and rename it into place.
- A declared cache is saved only after a run succeeds, so a failed run can't poison it.

## Disk

- Prune by age, by the host's budget, and to keep the host's `keep-free` space free, least recently used first, never a workspace in use.
- Stop pruning when what's deleted covers the overage. Concurrent prunes each freeing the whole overage delete far too much, so one prune runs at a time per host.
- On a Windows host, the WSL runner's files live in a virtual disk on the Windows drive. `df /` inside WSL doesn't show the Windows drive filling, so the WSL runner has to count the Windows drive's free space too.
- Sizes recorded by runs are hints, not facts: a run can write anything beside its workspace. Check them, and count again when they don't add up.

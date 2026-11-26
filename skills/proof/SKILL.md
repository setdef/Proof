---
name: proof
description: Use before you run a project's tests, builds, linters, or any check, and before you call a change done or push it, in a project whose computer has `proof` installed, even when the user only says "run the tests" or "check it passes". Also use for work that needs another operating system, a GPU, a desktop that opens windows, KVM, containers, or an iOS Simulator; when a run fails, waits, or exits 75; and when you need a file a run built. Not for setting up a pool's server or hosts, which a human does from Proof's guides, and not for how commits are pushed or landed (use trunk-based-development).
license: CC-BY-4.0
compatibility: Needs the proof command on PATH, signed in to a pool with `proof login`.
---

# Proof

Proof runs a project's tasks on other computers (hosts) in a pool, and streams the output back. This skill is for coding agents running a project's checks with it. You know how to run tests and read their output; these rules add how to do it through Proof without losing results, wasting the pool, or disturbing the humans whose computers the hosts are. Where a rule here conflicts with how you usually run checks, follow the rule here.

## Run a check

1. **Find the task.** A task is a named entry in the project's `mise.toml` (`[tasks.NAME]`) or in `.config/proof.kdl`. The project's agent instructions usually name the ones to run before a change is done.
2. **Run it through Proof, from inside the project:**

   ```console
   $ proof run test
   ```

   This sends the working tree as it is, uncommitted changes included. To check exactly what you committed, add `--commit HEAD`.
3. **Read the first line.** It shows the project and the commit Proof sent. If it shows another project, your shell is in the wrong folder: stop, and run again with `-C PATH_TO_PROJECT`.
4. **Read the last line and the exit status.** The last line is the result, such as `proof: exit=1 run=20261125-0336-r5c6t task=test runner=nuc-linux …`. With one run, `proof` exits with that status. Act on it by the table in **Exit statuses**, which also says what several runs exit with.
5. **On a failure, read the output.** If the output you saw was cut short, print the end of it with `proof logs r5c6t --tail 200`, using the run's last five characters.

Words for the task follow `--`, as with `cargo run` and `npm run`: `proof run test -- --seed 1234`. Proof's flags go anywhere before `--`, and a flag Proof doesn't have is refused with exit status 2, naming the flag and the nearest one Proof has. `:::` starts the next task, and each task's words follow a `--` after its name: `proof run lint -- --fix ::: test -- --seed 1234`. For any command or flag this file doesn't show, read [references/cli.md](references/cli.md), which matches the installed version of `proof`.

## Choose where it runs

- **Without `--os`, let Proof choose.** It places the run on any operating system the project file allows. This is right for almost every check.
- **Name an operating system only for work specific to that system:** code that runs only on Windows, a failure seen only on macOS, a package built for Linux. `--os windows`, `--os macos`, `--os linux`.
- **Don't run a check on every operating system to be sure.** `--os all` is for a release, or for a change to code that differs by system. Each extra run takes a host from someone else.
- **Ask for what a task needs with a label:** `--label desktop` (opens windows), `--label sound` (plays sound), `--label gpu`, `--label kvm`, `--label podman` (containers on Linux), `--label xcode` (iOS Simulator on a Mac). When the task needs it every time, add the label to the task in `.config/proof.kdl`. Read [references/project-file.md](references/project-file.md) before you edit that file.

## Exit statuses

| Status | Meaning | What you do |
| --- | --- | --- |
| 0 | Passed. | Continue. |
| 2 | Proof refused and sent nothing: a mistake in your command line or the project file, or a request no host can meet. | Read the message, fix the mistake, run again. |
| 75 | The pool failed, not the task: a host went away or the server couldn't be reached. | Run the same command once more. If it fails with 75 again, stop and tell the human, quoting the output. |
| 78 | Failed: the command passed, but Proof couldn't keep the artifacts because a pattern matched no file, or they exceeded the pool's limit. | Fix the pattern or the build, or keep fewer files. |
| 124 | The run hit its time limit. | Read the end of the output to see what was slow. Raise the limit only if the work is legitimately long. |
| 137 | The run held more memory than it requested while its host ran short. | Request what the message says it held: `--memory 12GB` for one run, and tell the human so the task's `memory` in `.config/proof.kdl` can change. |
| 130 | A human pressed Ctrl-C, and Proof canceled the run. | Stop. Tell the human the run was interrupted, and run it again only if they ask. |
| 141, 143 | Proof canceled the run because its output pipe closed (141), or it received `TERM` (143). | Run it again without a pipe, and don't stop it early. |
| Any other | The task failed. | Fix your change. Never treat it as the pool's fault. |

With several runs, as with `--os all`, `proof` exits with the first of these that applies: 130, 141, or 143 when Proof canceled the runs; the status of the first run whose command failed, in the order of the `--os` flags; 78; 75; 0. A 75 then means no run failed but the pool did, so run the same command once more. An earlier run's failure hides the status of a later one, such as 124, so read each run's result line, not only the exit status.

A run Proof can't vouch for never reports 0: a pass you see happened.

## Keep the result

- **Never pipe `proof` into `head`, `tail`, `grep`, or `less`.** A reader that closes early cancels the run, and a pipe hides the exit status. Run `proof` alone, then use `proof logs RUN_ID --tail N` or `proof logs RUN_ID | grep PATTERN` on the finished run.
- **Never wrap it in `bash -c` or `sh -c`.** Agent harnesses refuse compound commands. A one-off experiment goes in a script file in the project, then `proof run --script path/to/script.sh --os linux`.
- **If your command is interrupted or you run in the background,** the run goes on, or is canceled if your harness signaled it. The run's ID is in the second line, and if you lost it, `proof status` lists your recent runs with their IDs. `proof watch RUN_ID` picks up a run still going and exits with its status. `proof run --detach` starts a run and returns its ID at once, for when you have other work meanwhile.

## While a run waits

A run waiting in the queue isn't hung. `proof status` shows what it waits behind: other runs, a host with no runner connected, or a human using the host. A run a host already has shows what it is doing: getting its code, waiting for a desktop or for a human to leave, running its command, or sending its output. Keep working on something else, and come back with `proof watch`. Never cancel another agent's run to make room, and never move your run to a different operating system to skip the queue unless the change is specific to that system.

## Humans at hosts

Hosts are computers that humans use, and a human at a host comes first. If your run waits because a human is using a host, wait or let Proof place it elsewhere; never ask the human to stop using their computer.

Tests that open windows, go full screen, play sound, or drive a GPU are what Proof is for: they belong on a host, not on the computer the human is working at. Write them, and give their task the labels it needs, so Proof runs it where it can't disturb a human: on a separate display, desktop, or audio device, or, where a system can't separate them, only while no human is active.

On Windows, a test server that listens on any address but `127.0.0.1` makes Windows add a firewall rule that only an administrator can remove. Bind test servers to `127.0.0.1`.

## Hosts are not yours to fix

- **Never ssh into a host, and never change a host by hand** to make a run pass. A failure that only one host shows is the pool's to fix: tell the human which runner and what failed, with the run's ID.
- **Never run `sudo`, and never run anything as root.** When Proof prints a command for an administrator, give it to the human exactly as printed.
- **A task that installs what it needs is the project's job.** A runner starts with mise and the operating system's tools; if a run fails because a tool is missing, add it to the project's `mise.toml` or its setup task.

## Files in and out of a run

- Keep files a run makes with `--keep 'pkg/*.gem'`, quoted; `--download` copies them into the project when the run passes, and `proof download RUN_ID` fetches them later.
- Give a run an earlier run's files with `--input RUN_ID`, or a local file with `--input-file PATH`. The run finds them in the folder named by `$PROOF_INPUTS`.

## Gotchas

- When a test fails, running the check again until it passes hides the fault. Fix the test, or report it as flaky with the run IDs of a pass and a failure.
- A run that passes in a reused workspace and fails with `--empty`, or the other way around, has a real fault: leftover files hid one, or caused one. Report both results.
- `--commit HEAD` checks only what you committed. After editing, either commit first or drop `--commit`.
- A task that lists no operating system can land on any of them, and the first line says which. When it fails on one, check whether it also fails there on the commit before your change. If it does, the failure isn't yours: report it to the human, or list where the task works in `.config/proof.kdl`. Don't debug that operating system as part of your change.

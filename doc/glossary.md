# Glossary

In Proof's documentation, commands, and messages, each idea has one word. This page defines each word, says what other tools call the same idea, and lists the words to avoid for it, with the reason. Each word in **bold** inside a definition is defined on this page.

## The pool

### pool

Every **host** that takes **runs** for you, together with the **server** that hands runs to them.

- Elsewhere: HTCondor says pool; Nomad and Slurm say cluster.
- Don't say: cluster, which suggests Kubernetes and racks of servers; fleet; farm.

### host

One physical computer in the **pool**. A Windows PC that also runs Linux in WSL is one host.

- Elsewhere: Kamal and BOINC say host.
- Don't say: machine, which stays a plain English word in Proof's docs; node, which other tools use for one operating system on a computer; box; workstation, which suggests a fixed role (see **person**).

### runner

One operating system on a **host** that takes **runs**, together with the Proof program running there. A Windows PC with WSL has two runners, one for Windows and one for Linux, and they share the host's CPUs, memory, and disk.

- Elsewhere: GitHub Actions and GitLab say runner. Buildkite and Jenkins say agent.
- Don't say: agent, which in Proof's docs always means a coding agent; node; worker; client, which in Nomad and BOINC means the program that does the work and elsewhere means the program that asks for it.

### server

The one Proof program, on an always-on computer, that keeps the **queue**, receives your code, places each **run** on a **runner**, and keeps every run's record, output, and **artifacts**. The server takes no runs.

- Elsewhere: Nomad and Woodpecker say server. Jenkins says controller.
- Don't say: controller; coordinator; master; control host; staging host.

### label

A name for something a **runner** offers beyond its operating system, such as `gpu`, `kvm`, or `desktop`. A **task** can require labels, and the server then places its runs only on runners that have all of them. Each runner finds which labels it can offer by checking the host, and you can withhold any of them in the **pool file**.

- Elsewhere: GitHub Actions and Jenkins say label. GitLab and Buildkite say tag.
- Don't say: tag, which in mise means something else; capability; property; feature; attribute; constraint.

### OS

A runner's operating system: `linux`, `macos`, or `windows`. In flags and files, the key is `os`.

- Elsewhere: mise uses the same three names.
- Don't say: system, which is vague; platform, which also covers the processor.

### token

A secret that lets a person, an agent, or a runner act in the pool. Each token is issued to one person, agent, or runner, and Proof records which. Whoever holds a token issued for running work can run code as the runner account on every runner in the pool, so keep tokens as you would an SSH key.

- Elsewhere: every tool says token, qualified by kind: registration token, personal access token, API token.
- Don't say: API token or access token as the name of one kind, because both are categories that cover every kind; secret; key; credential.

### pool file

The one configuration file for the whole pool, kept on the server. It lists each host with its **budget**, its **share** for a **person**, and any **labels** it must not offer, and each repository whose pushed commits the pool builds.

- Don't say: config, which is ambiguous between the pool file and the **project file**.

## The project

### task

A named command a project defines, which you run by name with `proof run NAME`. A task is either a task in the project's `mise.toml`, or a task in the **project file** that gives its command.

- Elsewhere: mise and Concourse say task. GitLab and GitHub Actions say job.
- Don't say: job, which means a definition in some tools and one execution in others; check; step; pipeline; workflow; target.

### project file

The file `.config/proof.kdl` in a project. It contains what only Proof needs: which **OS** each task supports, the **labels** it requires, the **resources** it requests, its time limit, and which files the runner keeps as **artifacts**. It can also define tasks that `mise.toml` doesn't have. A project needs no project file: without one, Proof runs each mise task with Proof's defaults. Someone who doesn't use Proof can ignore the file.

- Don't say: Proof config; `.proof.yml`.

### defaults

The values in a project file's `defaults` node. They apply to every task whose entry lacks that value. Without a project file, Proof's built-in defaults apply.

### resources

The CPUs and memory a task requests. The server places a run only where a host has the resources free, and the runner holds the run to its memory request.

- Elsewhere: Nomad says resources; Slurm and HTCondor say CPUs and memory, and HTCondor calls asking for them a request.
- Don't say: reservation; slots; sizing; limits.

### request

To ask for **resources**: a task requests 2 CPUs and 4 GB. Also the amount asked for.

- Don't say: reserve; allocate.

## Runs

### run

One execution of a **task** or a **script** on one runner, with an ID, its output, and its exit status. A run ID looks like `20261124-1402-k7q2`.

- Elsewhere: GitHub Actions says run. Jenkins, Buildkite, and Concourse say build.
- Don't say: build, which suggests compiling; job; execution; allocation; check.

### script

A file, or text on standard input, that you run once with `proof run --script FILE` or `proof run --script -`, without defining a task.

- Elsewhere: Slurm says batch script.
- Don't say: ad hoc run; one-off; command string; snippet.

### queue

The runs that are waiting for a runner. A run in the queue is **queued**. `proof status` shows the queue for each OS, and what each queued run is behind.

- Don't say: backlog; waiting, as the name of a state.

### run states

A run is in exactly one of these states. The first two can change; the rest are final.

| State | Meaning |
| --- | --- |
| `queued` | The run waits for a runner. |
| `running` | A runner is running the run's command. |
| `succeeded` | The command exited with status 0, and its whole output arrived. |
| `failed` | The command exited with another status. |
| `timed_out` | The run reached its time limit, and the runner ended it. |
| `out_of_memory` | The run held more memory than it requested while its host ran short, and the runner ended it. |
| `canceled` | Someone canceled the run, and the runner ended it. |
| `lost` | The run ended without a status from its command, because its runner or host went away or Proof failed. |

- Elsewhere: GitHub Actions says queued; Slurm, GitLab, and Kubernetes say pending. GitLab, Buildkite, and Nomad spell canceled with one l.
- Don't say: waiting or pending for `queued`; passed or green for `succeeded`; aborted or killed for `canceled`.

### artifact

A file a run keeps after it ends, matched by a pattern in the task or a flag. You download artifacts with `proof download RUN_ID`, and another run can take them as **inputs**.

- Elsewhere: GitHub Actions, GitLab, Buildkite, and Jenkins say artifact.
- Don't say: kept file; output, which means what the command prints.

### input

A file a run receives before its command starts: a file from where you run `proof`, or the artifacts of an earlier run.

- Elsewhere: Concourse says input.
- Don't say: payload; attachment.

### output

Everything a run's command prints, standard output and standard error together, in the order the command printed it. Proof keeps each run's whole output, which you can read again with `proof logs RUN_ID`.

- Don't say: log, except in the name of the `logs` command; console.

## Workspaces

### workspace

The directory on a runner where a project's code sits while a run's command runs. A runner keeps workspaces between a project's runs, and no two runs use one workspace at the same time.

- Elsewhere: Jenkins and Woodpecker say workspace.
- Don't say: checkout; build directory; sandbox; slot.

### reuse

What survives in a workspace from one run to the next: the git clone, the tools and dependencies the project installed, and the project's **caches**. Before each run, the runner removes every file Git doesn't track, ignored files included. Reuse makes most runs several times faster. It can also hide a fault, such as a setup step that never installs what an earlier run left behind, and it can cause one, such as a file left over from another commit.

- Don't say: warm, which makes reuse sound better than **empty**; incremental; dirty.

### empty

To start a run in a workspace with nothing reused: no clone, no installed tools or dependencies, and no caches. A run in an empty workspace is slower, and shows whether the project builds from nothing.

- Elsewhere: GitLab calls this the empty strategy.
- Don't say: clean, which makes the alternative sound dirty; cold; fresh; pristine.

### cache

Files a project declares worth keeping between its runs on a runner, such as a compiler cache or a compiled runtime. A runner also keeps one download cache per project, shared by that project's runs, so a large download arrives once per host.

- Elsewhere: GitLab, GitHub Actions, CircleCI, Buildkite, Bitbucket, and Azure Pipelines say cache.
- Don't say: kept files; persisted directories.

### budget

The disk space Proof may use on a host for workspaces and caches. You set each host's budget in the pool file. When a host goes over its budget, its runners delete the workspaces used least recently, never one in use.

- Don't say: quota; cap.

## People at hosts

### person

A human at a host, using its keyboard, mouse, trackpad, or screen. Proof never counts input from runs as a person.

- Don't say: owner, because anyone at the keyboard counts; user, which in Proof's docs means you, the person who runs `proof`; workstation, because a person's presence at a host comes and goes.

### active

A person is active at a host while they have used its input devices within the last few minutes. You set how many in the pool file. While a person is active, Proof keeps a **share** of the host for them: runs go on, with less of the host, and runs that need the person's display or GPU wait. When the person stops, the share returns to runs.

- Elsewhere: BOINC says the user is active; HTCondor puts a machine in its Owner state.
- Don't say: idle or busy alone, because both also describe how hard a computer's processors work; in use; present; on console.

### share

The CPUs and memory Proof keeps free on a host for a person while they are active. You set each host's share in the pool file.

- Don't say: reservation, which suggests runs; headroom.

### input idle time

How long it has been since anyone used a host's keyboard, mouse, or trackpad.

- Elsewhere: Windows calls checking it input idle detection; HTCondor calls it `KeyboardIdle`.

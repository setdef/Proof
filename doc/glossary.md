# Glossary

In Proof's documentation, commands, and messages, each idea has one word. This page defines each word, says what other tools call the same idea, and lists the words to avoid for it, with the reason. Each word in **bold** inside a definition is defined on this page.

## The pool

### pool

Every **host** whose **runners** run your tasks and scripts, together with the **server** that places each **run** on a runner.

- Elsewhere: called a pool in HTCondor, and a cluster in Nomad and Slurm.
- Don't say: cluster, which suggests Kubernetes and racks of servers; fleet; farm.

### host

One physical computer in the **pool**. A Windows PC that also runs Linux in WSL is one host.

- Elsewhere: called a host in Kamal and BOINC.
- Don't say: computer or machine, which stay plain English words in Proof's docs; node, which other tools use for one operating system on a computer; box; workstation, which suggests a fixed role (see **person**).

### runner

One operating system on a **host**, together with the Proof program there that runs **tasks** and **scripts**. Each execution is a **run**. A Windows PC with WSL has two runners, one for Windows and one for Linux, and they share the host's CPUs, memory, and disk.

- Elsewhere: called a runner in GitHub Actions and GitLab, and an agent in Buildkite and Jenkins.
- Don't say: agent, which in Proof's docs always means a coding agent; node; worker; client, which in Nomad and BOINC means the program that does the work and elsewhere means the program that asks for it.

### server

The one Proof program, on an always-on computer, that keeps the **queue**, receives your code, places each **run** on a **runner**, and keeps every run's record, output, and **artifacts**. The server's computer has no runner.

- Elsewhere: called a server in Nomad and Woodpecker, and a controller in Jenkins.
- Don't say: controller; coordinator; master; control host; staging host.

### label

A name for something a **runner** offers beyond its operating system, such as `gpu`, `kvm`, or `desktop`. A **task** can require labels, and the server then places its runs only on runners that have all of them. Each runner finds which labels it can offer by checking the host, and you can withhold any of them in the **pool file**.

- Elsewhere: called a label in GitHub Actions and Jenkins, and a tag in GitLab and Buildkite.
- Don't say: tag, which in mise means something else; capability; property; feature; attribute; constraint.

### OS

A runner's operating system: `linux`, `macos`, or `windows`. In flags and files, the key is `os`.

- Elsewhere: mise has the same three names.
- Don't say: system, which is vague; platform, which also covers the processor.

### token

A secret that a person, an agent, or a runner gives the server to act in the pool. Each token is issued to one person, agent, or runner, and Proof records which. Whoever holds a token issued for running work can run code as the runner account on every runner in the pool, so keep tokens as you would an SSH key.

- Elsewhere: called a token in every tool, with a word for its kind: registration token, personal access token, API token.
- Don't say: API token or access token as the name of one kind, because both are categories that cover every kind; secret; key; credential.

### pool file

The one configuration file for the whole pool, kept on the server. It lists each host with its **budget**, its **share** for a **person**, any **labels** its runners must not offer, and each repository whose pushed commits Proof builds.

- Don't say: config, which is ambiguous between the pool file and the **project file**.

### place

To choose the **runner** a queued **run** goes to, and hold the CPUs and memory it **requests** on that runner's **host**. A run leaves the **queue** when the **server** places it.

- Elsewhere: called place in Nomad, Kubernetes, and Concourse; allocate in Slurm and Jenkins; match in HTCondor; assign in GitHub Actions; and dispatch in Buildkite. Nomad calls the result of placing an allocation.
- Don't say: schedule, which Buildkite and Jenkins also use for a time trigger; dispatch, which in Nomad means making an instance of a parameterized job; allocate, which **request** also avoids, and which is Nomad's word for the result of placing; assign, which suggests the choice ends when the runner is named, where placing also holds the CPUs and memory.

### approval

What a person does to let a **runner** that asked to join into the **pool**: they run `proof runner approve` with the **one-time code** the runner printed.

- Elsewhere: called approve in HTCondor, for an administrator letting a token request in, and in Kubernetes, for a certificate signing request. GitHub Actions and Woodpecker also use approve for permission to run a workflow or a pipeline, which Proof has no equivalent of.
- Don't say: register, which in GitHub Actions, GitLab, and Buildkite means a runner enrolls itself with a token, and no person approves it.

### one-time code

A code of 8 characters that `proof server setup` and `proof runner setup` print, and that `proof login` and `proof runner approve` ask for. It works once, for 15 minutes.

- Elsewhere: called a user code in RFC 8628, which defines the device authorization grant, and in GitHub's and Microsoft's device sign-in.
- Don't say: user code, because Proof's docs use user for the person who runs `proof`; code alone, which in Proof's docs also means a project's source (see "How your code reaches a runner"); PIN, which is a number someone keeps and reuses, where this code works once and expires; OTP, an abbreviation of "one-time password" that the docs would have to explain, where "one-time code" says it in plain words.

## The project

### project

The Git repository a run's code comes from, which the **server** keeps one copy of.

- Elsewhere: called a project in GitLab and CircleCI, and a repository in GitHub Actions and Woodpecker. In Nx, a project is a unit inside a repository, where a project in Proof is the whole repository.
- Don't say: pipeline, which in Buildkite is a definition of work, not the repository the work runs on.

### working-tree commit

The commit `proof` makes of the working tree without touching the clone's index, branch, or `HEAD`.

- Elsewhere: `git stash create` makes the same kind of commit, a stash entry, and returns it without storing it in any ref.
- Don't say: synthetic commit, because the docs call it a commit of your working tree; stash, which is Git's word for what it keeps under a ref.

### task

A named command defined in a project, which you run by name with `proof run NAME`. It is defined either in the project's `mise.toml` or, with its command, in the **project file**.

- Elsewhere: called a task in mise and Concourse, and a job in GitLab and GitHub Actions.
- Don't say: job, which means a definition in some tools and one execution in others; check; step; pipeline; workflow; target.

### task words

The words that go to a **task** as they are: the words after `--` on `proof run`, and any plain word before it. `:::` ends one task's words and starts the name of the next task.

- Elsewhere: called arguments in mise.
- Don't say: arguments, which in Proof's docs means what a command takes, apart from its flags; params.

### project file

The file `.config/proof.kdl` in a project. It contains what only Proof needs: which **OS** each task works on, the **labels** it requires, the **resources** it requests, its time limit, and which files the runner keeps as **artifacts**. It can also define tasks that `mise.toml` doesn't have. You don't need a project file: without one, Proof runs each mise task with Proof's defaults. Someone who doesn't use Proof can ignore the file.

- Don't say: Proof config; `.proof.yml`.

### defaults

The values in a `defaults` node. In a project file, they apply to every task whose entry lacks that value; in the pool file, to every host. Without a project file, Proof's built-in defaults apply.

### resources

The CPUs and memory a task requests. The server places a run only where a host has the resources free, and the runner holds the run to its memory request.

- Elsewhere: called resources in Nomad, and CPUs and memory in Slurm and HTCondor, where asking for them is a request.
- Don't say: reservation; slots; sizing; limits.

### request

To ask for **resources**: a task requests 2 CPUs and 4 GB. Also the amount asked for.

- Don't say: reserve; allocate.

## Runs

### run

One execution of a **task** or a **script** on one runner, with an ID, its output, and its exit status. A run ID is the minute the run was created, in UTC, then five random characters: `20261125-0336-k7q2w`. Wherever Proof asks for a run's ID, the five characters alone work, matched against the last 7 days of runs. They come from [Crockford's Base32](https://www.crockford.com/base32.html), which has no `i`, `l`, `o`, or `u`, so Proof reads a typed `o` as `0` and an `i` or `l` as `1`.

A run of a pushed commit, which the **server** starts for a commit on a branch the **pool file** lists, is a run like any other.

- Elsewhere: called a workflow run in GitHub Actions, a pipeline in GitLab, Woodpecker, and CircleCI, and a build in Jenkins, Buildkite, and Concourse.
- Don't say: build, which suggests compiling; job; execution; allocation; check.

### script

A file, or text on standard input, that you run once with `proof run --script FILE` or `proof run --script -`, without defining a task.

- Elsewhere: called a batch script in Slurm.
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
| `lost` | The run ended without a status from its command, because its runner or host went away or Proof failed, or its command exited but its whole output never reached the server. |

- Elsewhere: `queued` is queued in GitHub Actions and pending in Slurm, GitLab, and Kubernetes. Canceled has one l in GitLab, Buildkite, and Nomad.
- Don't say: waiting or pending for `queued`; passed or green for `succeeded`; aborted or killed for `canceled`.

### artifact

A file the runner keeps from a run after the run ends, matched by a pattern in the task or a flag. You download artifacts with `proof download RUN_ID`, and another run can take them as **inputs**.

- Elsewhere: called an artifact in GitHub Actions, GitLab, Buildkite, and Jenkins.
- Don't say: kept file; output, which means what the command prints.

### input

A file a run receives before its command starts: a file from where you run `proof`, or the artifacts of an earlier run.

- Elsewhere: called an input in Concourse.
- Don't say: payload; attachment.

### output

Everything a run's command prints, standard output and standard error together, in the order the command printed it. Proof keeps each run's whole output, which you can read again with `proof logs RUN_ID`.

- Don't say: log, except in the name of the `logs` command; console.

### short ID

A run ID's last five characters, which work wherever Proof asks for a run's ID.

- Elsewhere: Nomad, GitLab, and Git also shorten an ID to its leading characters. Proof's short ID is the last five.
- Don't say: prefix, which means the leading characters Nomad, GitLab, and Git keep; abbreviation, which Git uses for that prefix (`--abbrev-commit`).

### result line

The line `proof` writes to standard error when a run ends, with the run's exit status, its full ID, and other `key=value` fields. Fields are only ever added to it, never renamed or removed.

- Elsewhere: Buildkite shows exit status information in the footer of each job, and mise can write a run's result to a JSON report with `--report-file`. Neither is one closing line with a run's status and ID.
- Don't say: output, which means what the run's command prints; summary, which mise uses for an output style.

### record

What the **server** keeps of a run apart from its **output** and **artifacts**.

- Elsewhere: Slurm calls the same thing an accounting record, and HTCondor a job's entry in its history. In Kubernetes, an object is a "record of intent", a desired state, where Proof's record is what the server kept after the run.

### invocation

What a **runner** needs to start a run's command that the **record** never keeps: the task's arguments, a script's text, the run's **inputs**.

- Elsewhere: Bazel's remote execution API calls what a worker needs an action, with a command's arguments and its input files. In Bazel, an invocation is one run of the `bazel` command, which is a **run** in Proof.

### follow

To read a run's **output** as it arrives, from a byte offset, as `proof run` and `proof watch` do. Whoever follows is a follower.

- Elsewhere: called follow in Nomad (`-f`), Kubernetes (`--follow`), and HTCondor (`-follow`). Nomad's API also takes a byte offset to start from.
- Don't say: tail, the word in `proof logs --tail`, a flag that prints the last lines of a run's output; attach, which in Slurm means connecting to a running job step's input and output streams, where following only reads.

### end marker

What the runner sends after a run's last byte of **output**, with the number of bytes it sent.

### manifest

The sorted list of a run's **artifacts**, with each file's SHA-256 and size, after which no artifact is added.

- Elsewhere: an OCI image manifest is the same kind of list, of an image's layers by digest. In Kubernetes, a manifest is a resource's YAML file, which is something else.

### wait reason

What a queued run waits behind, as `proof status` shows it.

- Elsewhere: Slurm shows a reason for each pending job, such as `Resources` or `Priority`.

### queue position

A run's place in arrival order, given by the server when the run is queued.

- Elsewhere: in Slurm, a job's order in the queue changes with its priority. In Proof it never changes, because there are no priorities.

### random source

What gives Proof the unpredictable characters in a **run** ID and in a **one-time code**.

- Elsewhere: Ruby's documentation calls such an object a random number generator. `Random` and `SecureRandom` are two, and `Array#sample` takes one as its `random:` argument.

## Workspaces

### workspace

The directory on a runner where a project's code sits while a run's command runs. A runner keeps workspaces between a project's runs, and no two runs use one workspace at the same time.

- Elsewhere: called a workspace in Jenkins and Woodpecker.
- Don't say: checkout; build directory; sandbox; slot.

### lease

One run's use of one **workspace**, from before its command starts until it ends.

- Elsewhere: a Kubernetes Lease is a node heartbeat or a leader election, and an HTCondor job lease keeps a job running while its submitter is out of contact. Neither is one run's use of a workspace.
- Don't say: lock, which is what keeps a second run out of the workspace while the lease lasts.

### reuse

What survives in a workspace from one run to the next: the Git clone, what the project's setup installed in the run's home folder, such as the tools mise installs, and the project's **caches**. Before each run, the runner removes every file Git doesn't track, ignored files included. With reuse, most runs are several times faster. It can also hide a fault, such as a setup step that never installs what an earlier run left behind, and it can cause one, such as a file left over from another commit.

- Don't say: warm, which makes reuse sound better than **empty**; incremental; dirty.

### empty

To start a run in a workspace with nothing reused: no clone, no installed tools or dependencies, and no caches. A run in an empty workspace is slower, and its result shows whether the project builds from nothing.

- Elsewhere: called the empty strategy in GitLab.
- Don't say: clean, which makes the alternative sound dirty; cold; fresh; pristine.

### cache

Files listed in a project file as worth keeping between a project's runs on a runner, such as a compiler cache or a compiled runtime. A runner also keeps one download cache per project, shared by that project's runs, so a large download arrives once per host.

- Elsewhere: called a cache in GitLab, GitHub Actions, CircleCI, Buildkite, Bitbucket, and Azure Pipelines.
- Don't say: kept files; persisted directories.

### budget

The disk space Proof may use on a host for workspaces and caches. You set each host's budget in the pool file. When Proof's files on a host exceed its budget, the host's runners delete the workspaces used least recently, never one in use.

- Don't say: quota; cap.

## People at hosts

### person

A human at a host, using its keyboard, mouse, trackpad, or screen. On Linux and Windows, Proof never counts input from runs as a person.

- Don't say: owner, because anyone at the keyboard counts; user, which in Proof's docs means you, the person who runs `proof`; workstation, because a person's presence at a host comes and goes.

### active

A person is active at a host while they have used its input devices within the last few minutes. You set how many in the pool file. While a person is active, Proof keeps a **share** of the host for them: runs go on, with less of the host, and runs that need the person's display, GPU, or speakers wait. When the person stops, runs get the share back.

- Elsewhere: in BOINC, the user is active; in HTCondor, the machine is in its Owner state.
- Don't say: idle or busy alone, because both also describe how hard a computer's processors work; in use; present; on console.

### share

The CPUs and memory Proof keeps free on a host for a person while they are active. You set each host's share in the pool file.

- Don't say: reservation, which suggests runs; headroom.

### input idle time

How long it has been since anyone used a host's keyboard, mouse, or trackpad.

- Elsewhere: called `KeyboardIdle` in HTCondor. Microsoft's documentation calls checking it input idle detection.

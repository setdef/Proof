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

### capacity

The CPUs and memory a **runner** can use, which it reports to the **server**. A runner in a virtual machine, such as WSL, can have less than its **host**. A host's capacity is the most that any of its runners reports, of each.

- Elsewhere: called capacity in Kubernetes, for a node's CPUs and memory.
- Don't say: size, which Proof keeps for amounts of memory and disk; total; limit, which in Proof's docs is a time limit or one of the pool file's `limits`.

### server

The one Proof program, on an always-on computer, that keeps the **queue**, receives your code, places each **run** on a **runner**, and keeps every run's record, output, and **artifacts**. The server's computer has no runner.

- Elsewhere: called a server in Nomad and Woodpecker, and a controller in Jenkins.
- Don't say: controller; coordinator; master; control host; staging host.

### label

A name for something a **runner** offers beyond its operating system, such as `gpu`, `kvm`, or `desktop`. A **task** can require labels, and the server then places its runs only on runners that have all of them. Each runner finds which labels it can offer by checking the host, and you can withhold any of them in the **pool file**.

- Elsewhere: called a label in GitHub Actions and Jenkins, and a tag in GitLab and Buildkite.
- Don't say: tag, which in mise means something else; capability; property; feature; attribute; constraint.

### name

The text that a **host**, a **runner**, a **repository**, a branch, or a **task** goes by in the **pool file** and the **project file**: at least one character that isn't white space, such as `nuc`, `nuc-linux`, `lota`, `trunk`, or `test`. Proof compares the names of hosts, runners, and repositories without regard to case, so `nuc` and `NUC` are one host, and shows each as its entry writes it. It compares branch and task names as written. A **label** has a rule of its own.

- Don't say: ID, which in Proof's docs is a **run**'s ID; handle; key.

### OS

A runner's operating system: `linux`, `macos`, or `windows`. In flags and files, the key is `os`.

- Elsewhere: mise has the same three names.
- Don't say: system, which is vague; platform, which also covers the processor.

### token

A secret that a person, an agent, or a runner gives the server to act in the pool. Each token is issued to one person, agent, or runner, and Proof records which: that is the token's kind, and what a token may do depends on it. A person's token may approve and revoke runners and cancel any run. An agent's may run, watch, download, and cancel its own runs. A runner's may do only a runner's work. Whoever holds a token issued for running work can run code as the runner account on every runner in the pool, so keep tokens as you would an SSH key.

- Elsewhere: called a token in every tool, with a word for its kind: registration token, personal access token, API token.
- Don't say: API token or access token as the name of one kind, because both are categories that cover every kind; secret; key; credential.

### pool file

The one configuration file for the whole pool, kept on the server. It lists each host with its **budget**, its **share** for a **person**, any **labels** its runners must not offer, and each repository whose pushed commits Proof runs tasks on.

- Don't say: config, which is ambiguous between the pool file and the **project file**.

### repository

The pool file's name for a **project** that the **server** also fetches from: its entry has the clone URL, the branches to watch, and the **tasks** to run on each new commit.

- Elsewhere: called a repository in GitHub Actions and Woodpecker, where it is the unit of work, as a **project** is in Proof.
- Don't say: project, which means the repository a **run**'s code comes from, whoever sends it; watch list.

### retention

How long the **server** keeps what each **run** leaves: its **record**, its **output**, and its **artifacts**. You set each in days in the **pool file**.

- Elsewhere: GitHub Actions has `retention-days` for artifacts, and GitLab has `expire_in`.
- Don't say: expiry; TTL; cleanup.

### place

To choose the **runner** a queued **run** goes to, and hold the CPUs and memory it **requests** on that runner's **host**. A run leaves the **queue** when the **server** places it.

- Elsewhere: called place in Nomad, Kubernetes, and Concourse; allocate in Slurm and Jenkins; match in HTCondor; assign in GitHub Actions; and dispatch in Buildkite. Nomad calls the result of placing an allocation.
- Don't say: schedule, which Buildkite and Jenkins also use for a time trigger; dispatch, which in Nomad means making an instance of a parameterized job; allocate, which **request** also avoids, and which is Nomad's word for the result of placing; assign, which suggests the choice ends when the runner is named, where placing also holds the CPUs and memory.

### shortfall

How much less of a resource a **host** could ever have free than a run **requests**, as a part of the request: 4 CPUs of the 8 requested is a shortfall of half the CPUs. A host can fall short in CPUs, in memory, or in both. What a host could ever have free is its **capacity** less the memory of its **share**, and no more than the capacity of the runner the run would go to. Proof refuses a run that every host falls short of, and names the host whose worst shortfall is the smallest.

- Don't say: deficit; gap; missing resources.

### approval

What a person does to let a **runner** that asked to join into the **pool**: they run `proof runner approve` with the **one-time code** the runner printed.

- Elsewhere: called approve in HTCondor, for an administrator letting a token request in, and in Kubernetes, for a certificate signing request. GitHub Actions and Woodpecker also use approve for permission to run a workflow or a pipeline, which Proof has no equivalent of.
- Don't say: register, which in GitHub Actions, GitLab, and Buildkite means a runner enrolls itself with a token, and no person approves it.

### one-time code

A code of 8 characters that `proof server setup` and `proof runner setup` print, and that `proof login` and `proof runner approve` ask for. It works once, for 15 minutes.

- Elsewhere: called a user code in RFC 8628, which defines the device authorization grant, and in GitHub's and Microsoft's device sign-in.
- Don't say: user code, because Proof's docs use user for the person who runs `proof`; code alone, which in Proof's docs also means a project's source (see "How your code reaches a runner"); PIN, which is a number someone keeps and reuses, where this code works once and expires; OTP, an abbreviation of "one-time password" that the docs would have to explain, where "one-time code" says it in plain words.

### fingerprint

The SHA-256 of the **server**'s public key. The command and every **runner** keep it after their first contact, and trust a server only while its key has that fingerprint.

- Elsewhere: Git's `http.pinnedPubkey` takes the same hash, written after `sha256//` in Base64. SSH and GnuPG also call a hash of a key its fingerprint.
- Don't say: thumbprint, which Windows uses for a hash of a whole certificate; pin, which is what the command and the runners do with a fingerprint.

### runner key

The EC P-256 key pair a **runner** makes when it asks to join. Its join request carries the public key, the server encrypts the runner's **token** to it, and only the runner, which keeps the private key, can decrypt the token.

- Elsewhere: HPKE (RFC 9180) calls such a key the recipient's public key, and age calls it a recipient.
- Don't say: runner token, which is the **token** the key decrypts; key alone, because the **server** has a key too.

### slow tag

A value Proof computes from a **one-time code** with scrypt, over the server's **fingerprint** and other fields, to show that whoever computed it knows the code. The server shows one before `proof login` sends a code, and the computer that approves a **runner** sends one to the runner, so the command and the runner keep a fingerprint only from someone who knows the code. Each tag takes about a third of a second and 128 MiB to compute, which makes trying every code against one take thousands of years on one processor.

- Elsewhere: RFC 7914 calls what scrypt computes a derived key. In cryptography a tag is what a MAC computes, and a slow tag is one keyed by the code and slow on purpose.
- Don't say: hash, because a hash has no key; MAC or HMAC, which take microseconds, where a slow tag is slow on purpose; tag alone, which can be read as a **label**.

## The project

### project

The Git repository a run's code comes from, which the **server** keeps one copy of. Proof identifies a project by its repository's root commit, so two clones of one repository are one project, and so is a fork of it until their histories part.

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

The words that `proof run` gives to a **task** as they are: the plain words after the task's name, and the words after `--`. The word `:::` marks the end of a task's words, and the word after it is the next task's name.

- Elsewhere: called arguments in mise.
- Don't say: arguments, which in Proof's docs means what a command takes, apart from its flags; params.

### project file

The file `.config/proof.kdl` in a project. It contains what only Proof needs: which **OS** each task works on, the **labels** it requires, the **resources** it requests, its time limit, and which files the runner keeps as **artifacts**. It can also define tasks that `mise.toml` doesn't have. You don't need a project file: without one, Proof runs each mise task with Proof's defaults. Someone who doesn't use Proof can ignore the file.

- Don't say: Proof config; `.proof.yml`.

### defaults

The values in a `defaults` node. In a project file, they apply to every task whose entry lacks that value; in the pool file, to every host. Without a project file, Proof's built-in defaults apply.

### setting

One of the values a **run** gets: its **OS**es, **labels**, CPUs, memory, time limit, **artifacts**, and **caches**. A flag on `proof run`, the **task**'s entry in the **project file**, the **defaults**, and Proof's built-in defaults each give settings, in that order of precedence. CPUs, memory, and the time limit come from the first of them that has one, and so do the **OS**es. **Labels**, **artifacts**, and **caches** add up from all of them.

A **host** has settings too: its **budget**, its `keep-free` disk space, its **share**, how long a **person** counts as **active**, and the **labels** it withholds. The host's entry in the **pool file**, the **defaults** node, and Proof's built-in defaults each give them, in that order. The budget, the `keep-free` space, the share, and the time a person counts as active come from the first of them that has one. The withheld labels add up from all of them.

- Don't say: option, which most tools use for a flag; property, which in the project file means a `name=value` entry on a node, such as `cpus=4`, where `os` and `label` are children.

### resources

The CPUs and memory a task requests. The server places a run only where a host has the resources free, and the runner holds the run to its memory request.

- Elsewhere: called resources in Nomad, and CPUs and memory in Slurm and HTCondor, where asking for them is a request.
- Don't say: reservation; slots; sizing; limits.

### size

An amount of memory or disk: a number, an optional space, and a unit, such as `512MB`, `8 GB`, or `1.5TiB`, counted in megabytes and rounded up to a whole megabyte. A **task**'s memory, a host's **budget**, and a pool file's `limits` are sizes.

- Elsewhere: Kubernetes calls the same thing a quantity.
- Don't say: capacity, which is what a **runner** reports; weight; volume.

### duration

A length of time written as a whole number from 1 and one unit, in lowercase, with no space: `90s`, `30m`, `2h`, or `7d`. A task's `timeout`, a host's `active-for`, and a repository's `poll` take seconds, minutes, or hours, and **retention** takes days. A form with two units, such as `1h30m`, or a fraction, such as `1.5h`, is refused.

- Elsewhere: called a duration in Go, Nomad, and Kubernetes, whose parsers also read `1h30m` and `1.5h`.
- Don't say: interval; period; time span.

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

A file, or text on standard input, that you run once with `proof run --script FILE` or `proof run --script -`, without defining a task. The words for a script follow `--`, as a task's do, and go to the script as its arguments.

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
| `running` | A runner has the run, from its placement until it ends. |
| `succeeded` | The command exited with status 0, its whole output arrived, and Proof kept the run's artifacts. |
| `failed` | The command exited with another status, Proof couldn't keep the run's artifacts, or the server was short of space for them when the run started. |
| `timed_out` | The run reached its time limit, and the runner ended it. |
| `out_of_memory` | The run held more memory than it requested while its host ran short, and the runner ended it. |
| `canceled` | Someone canceled the run. A runner ended it, or no runner had it yet: a run that is still `queued` ends `canceled` without one. |
| `lost` | The run ended without a status from its command, because the server lost contact with its runner for 10 minutes (the runner or its host went away) or Proof failed, or its command exited but its whole output never reached the server. |

The 10 minutes count only while the server is up, so a server restart or outage never makes a run `lost`. A `lost` run stays `lost`: the server refuses a report that arrives later, even a complete one. The host's CPUs and memory stay held until the runner reports that the run's processes ended, or the runner is revoked.

A run that is `running` is doing one of these: fetching its code, waiting for a desktop or for a person to leave, running its command, or sending its output. `proof status` shows which.

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

- Elsewhere: Slurm calls the same thing an accounting record, and HTCondor a job's entry in its history. In Kubernetes, an object is a "record of intent", a desired state, where Proof's record is what the server keeps of a run while it goes on and after it ends.

### fact

One thing that happened to a run, as the **server** recorded it, with the time on the server's clock: the run was queued at its **queue position**, placed on a runner, its command started, its command ended with a status, its whole **output** arrived, its **artifacts** were kept or not kept, a cancel was asked for, it reached a final state, or its processes ended after it was `lost`. A run's **record** is its list of facts, which the server only ever adds to, and its state follows from them.

- Elsewhere: called an event in event sourcing, and a fact in Datomic.
- Don't say: event, which in Proof's docs means what the server publishes once a fact is stored; log entry, because **output** is what a run prints; history.

### invocation

What a **runner** needs to start a run's command that the **record** never keeps: the **task words**, a script's text, the run's **inputs**.

- Elsewhere: Bazel's remote execution API calls what a worker needs an action, with a command's arguments and its input files. In Bazel, an invocation is one use of the `bazel` command, which Proof has no word for.

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

A run's place in arrival order, given by the server when the run is queued. The server places the earliest run among those that fit, so a run with a later position can start first.

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

A person is active at a host while they have used its input devices within the last few minutes. You set how many in the pool file. While a person is active, Proof keeps the CPUs of the host's **share** free for them: runs go on, with less of the host, and runs that need the person's display, GPU, or speakers wait. When the person stops, runs get the share's CPUs back.

- Elsewhere: in BOINC, the user is active; in HTCondor, the machine is in its Owner state.
- Don't say: idle or busy alone, because both also describe how hard a computer's processors work; in use; present; on console.

### share

The CPUs and memory Proof keeps free on a host for a person. The memory is free always, because a run can't give memory back, and the CPUs are free while a person is **active**, because priority takes CPU back. You set each host's share in the pool file.

- Don't say: reservation, which suggests runs; headroom.

### input idle time

How long it has been since anyone used a host's keyboard, mouse, or trackpad.

- Elsewhere: called `KeyboardIdle` in HTCondor. Microsoft's documentation calls checking it input idle detection.

# Architecture

How Proof is built: the libraries, the layout of the code, and how the parts fit. This page is the place for mechanism, which [the design pages](design/README.md) never hold. They say what must hold, and [the decision records](decisions/README.md) hold the architectural decisions, such as Ruby, placement without an external scheduler, Git as the transport, connections out to the server, and no root. Choices of tool and library never reach the bar for a record, so they are here.

Each section states how Proof is built, then lists the options weighed and why each lost. A measurement is stated with its numbers. The words are [the glossary's](../glossary.md).

## Layout and model

### One model for the command, the server, and the runner

Proof has one bounded context. It has a shared kernel, which holds the ideas all three roles use (runs, tasks, resources, labels, the run states), and one module each for the command, the server, and the runner. The three always run one version and share one glossary, so the kernel's words mean the same in every module. The modules show which rule needs which guarantee. The server's modules need a store that can refuse a second decision. The runner's need a workspace lease that a prune can't race ([the runner design](design/runner.md#workspaces)) and one prune at a time across a host's runners ([the runner design](design/runner.md#disk)).

Options weighed:

- Three separate models, translated at the protocol: nothing would differ between them to translate. Every translation would be code that can drift, with nothing gained.
- One model with no modules: it works, and it hides which rule needs which guarantee from a reader who has to change one.

### The domain gem and the code around it

The domain lives in a gem in this repository, `gems/proof-domain`. It has no runtime dependencies, only Ruby's standard library, and a test fails if the gem loads anything outside itself.

- Value objects are `class Foo < Data.define(...)`, each with an RBS signature. Each boundary's rules are checked in its constructor, so an invalid value can't exist.
- Domain services receive their ports by keyword.
- A port is an RBS interface and nothing more. Every port that stores something has an in-memory adapter and a Minitest contract module. The contract tests also cover two threads at once and reopening the store after a restart.

Everything that touches the outside lives in `lib/proof`, and depends on the domain gem, never the reverse: the use cases, the unit of work that owns transactions, the adapters, and three composition roots, one each for the command, the server, and the runner.

```text
gems/proof-domain/   value objects, domain services, port interfaces,
                     in-memory adapters, contract modules
lib/proof/           use cases, unit of work, adapters, composition roots
```

[Fledge](https://github.com/setdef/Fledge) ships an in-project path gem as part of the app. Three traps:

- The folder on disk ships, not the list of files in the gemspec, so a file left in the folder ships.
- Fledge evaluates the gemspec at build time and writes the result into the app. A `files` list the gemspec computes, for example from `git ls-files`, comes from the build machine's checkout, and the app needs no Git where it runs.
- Fledge refuses a path gem whose version differs from the one in `Gemfile.lock`.

Options weighed:

- Folders in one gem: no boundary a test can hold, so a dependency in the wrong direction goes unnoticed until someone reads the diff.
- A separate gem for use cases: each use case has one front end, so nothing shares them, and a gem boundary would only add a version to keep in step.
- A gem per role: the shared kernel is used by all three, and the roles never ship apart.

### A run as a consistency boundary

A run is stored as an append-only list of facts, each with the server's time. The run's constructor checks every rule about a run, including when the run is rebuilt from storage. A record changed behind Proof's back therefore fails to load, instead of reporting a pass. The list also shows afterwards how a run reached `succeeded`. Which states a run can pass through, and what each ending needs, are in [the server design](design/server.md#runs-and-their-records) and [the runner design](design/runner.md#a-runs-end), and the facts record them.

Options weighed:

- A record of plain fields with a version number: it meets every requirement in [the server design](design/server.md#runs-and-their-records), but it can't show afterwards how a run reached `succeeded`, and nothing in it fails when a field is edited by hand.

### Placing a run

Choosing a run's runner is a domain service. It checks the rules that span runs and hosts: a host's resources counted once across its runners, arrival order, labels, and the share. It then writes one fact to one run. Three things keep the decision safe:

- The store itself refuses a second placement fact for a run.
- The server's unit of work serializes placement decisions.
- A host's resources in use are computed from its runs, and never stored on the host, so there is no second copy to disagree with the runs.

How placement orders and counts is in [the server design](design/server.md#placement), which says what must hold.

Options weighed:

- A consistency boundary per host that holds its resources: one placement would write to the host and to the run, so no single boundary would cover it.
- One consistency boundary for the whole queue: every byte of output would wait on its lock.

### Output and artifacts

A run's output and its artifacts are separate consistency boundaries, kept consistent with the run by ordering, not by a shared lock:

- A piece of output is durable before the server acknowledges it.
- A run becomes `succeeded` only after its whole output and its artifacts' manifest are stored.

A run therefore never reports a pass over output that is missing.

Options weighed:

- Output as facts in the run's list: each piece would rebuild and recheck the whole run, and would contend with every placement decision on it.

### Events

The server publishes an event only after the unit of work that produced it commits. A listener therefore never acts on a fact that a rollback later removes.

Options weighed:

- Publishing inside the unit of work: a listener could start work, such as sending output to a follower, on a fact the rollback then erases.

## Libraries

### Command line

The command uses Ruby's OptionParser with `require_exact`, which refuses an abbreviation of a flag's name, and finds the command by hand: it follows the words down the commands of the spec, and a table maps a command's words to the class that holds its flags and arguments. OptionParser takes its flags from `lib/proof/command_line/spec.json`, which `usage generate json` writes from [`proof.usage.kdl`](../../proof.usage.kdl), so a flag added to the spec reaches the parser and the help together. The help is written from the same file, with no KDL read at run time and no `kdl` gem, so the command starts on Ruby's standard library alone. For a flag it doesn't know, OptionParser raises an error that gives the flag (`invalid option: --oss`, with `--oss` in the error's `args`). Ruby's did_you_mean gives the suggestion: `DidYouMean::SpellChecker`, given the command's flags, answers `--os`. A short flag gets no suggestion, because one letter is near every other. The command prints both and exits 2, the status [`proof.usage.kdl`](../../proof.usage.kdl) gives to a mistake on the command line.

`proof run` takes Proof's flags anywhere before `--`. The words for the task follow `--`, as for `cargo run` and `npm run` ([issue #18](https://github.com/setdef/Proof/issues/18)). A plain word before `--`, as in `proof run test foo`, goes to the task, as `proof.usage.kdl` reads it: `usage` can mark a word after the task as a mistake only by requiring `--`, which would also refuse `proof run lint ::: test`. The parser is tested against the spec, so it does the same. Only a flag before `--` is refused, which is where typos of Proof's own flags happen. `:::` starts the next task, before or after `--`. After `--`, words go to the current task until a `:::`, the word after `:::` is the next task's name, and that task's words again follow `--`. OptionParser stops reading flags at the first `--`, so the command splits what follows by hand: the first `--` after a task's name separates its words from Proof's flags, and a later `--` is one of the task's words. The tests compare the parser with `usage explain --format json` for command lines made from the spec, and a difference in whether a line is accepted or in what a word binds to fails the test. They include the front of each flag, command, and choice, which usage refuses and which OptionParser takes for a flag unless `require_exact` is set. What usage can't say, such as the nearest flag in a mistake and where `:::` has no task before it or no name after it, has its own tests.

Options weighed:

- Samovar: reads options only before positional arguments, so it refused `proof run test --os linux`.
- dry-cli, at 1.4.1: a repeated `--os linux --os windows` kept only `windows`, silently. Every yes-or-no flag also gained a `--no-` form that the spec doesn't have, and it accepted the abbreviation `--dry` for `--dry-run`. `--os beos` and a missing task or script got no specific error, or none. It has no global flags, and it exits 1 for a command-line mistake where the spec gives 2.
- Thor: its list options took the task's flags.
- tty-option: has no subcommands, and has had no release since 2023.

### KDL

The `kdl` gem reads KDL, always called with `version: 2`. One reader in `lib/proof` wraps it, outside the domain gem, which has no dependencies. Errors carry the line and column.

### Git

Proof runs the `git` program as a subprocess, with every inherited `GIT_*` variable removed so that a hook or a parent Git process can't redirect it.

Options weighed:

- Rugged: builds libgit2 from source, its certificate check can't see the certificate, and it has no check that a commit is complete, which [the decision on code](decisions/0003-code-travels-as-git-commits-through-the-server.md) needs.
- The `git` gem: wraps the same program, and pulls in ActiveSupport.

#### A submodule in a working-tree commit

A working-tree commit records each submodule at the commit its checkout is at, as `git add -A` records it. A submodule the developer has moved to another commit goes at that commit, even when the project hasn't committed the move. Changes to files inside a submodule are not sent, as [the command design](design/command.md#which-project-and-which-code) says. A run of `--commit REV` uses the tree of that commit, so it sends the submodule commits that tree records.

Options weighed:

- Pinning each submodule to the commit `HEAD` records: it drops a submodule bump the developer hasn't committed, and a working-tree run sends the working tree as it is.

#### A project with no commit

A project with no commit yet gets a working-tree commit made from an empty index, with no parent. `--commit` of any revision in such a project is refused as an unknown revision, because the project has no commit for a revision to point to.

Options weighed:

- Refusing a working-tree run: it stops a run in a new repository for no reason the run needs, because the run needs only the files.

#### The index a working-tree commit starts from

A working-tree commit starts its temporary index as a copy of the clone's index file, then runs `git add --all`, `git write-tree`, and `git commit-tree`. A project with no index file starts from an empty index. Every Git command that writes the temporary index runs with `core.splitIndex=false`, so the temporary index never refers to a shared index file in the clone's `.git`, and never adds one, whatever the clone's settings are.

A probe on `rails/rails` at v8.0.2, with 4,762 tracked files, took the median of five runs:

| State | `read-tree HEAD` | Copy of the clone's index | `read-tree HEAD`, `diff-index`, and `ls-files -o` |
| --- | --- | --- | --- |
| Nothing changed | 0.39 s | 0.11 to 0.13 s | 0.15 s |
| One tracked file changed | 0.39 s | 0.11 to 0.12 s | 0.17 s |

Every existing file under `.git` stayed byte for byte the same in every case. With `core.splitIndex=true`, `read-tree HEAD` alone and with `diff-index` and `ls-files -o` each added a `sharedindex` file to the clone's `.git` for each tree state, and the copy added none. `read-tree HEAD` dropped a file the developer staged with `git add -f` that `.gitignore` matches. The copy and the three-command way kept it.

The copy is the fastest, and it sends a staged file the way `git commit` would, which is what "your working tree as it is" means to someone who staged it.

Options weighed:

- `read-tree HEAD`, as Proof first did: it hashes every tracked file on every run, and it drops a file the developer staged that `.gitignore` matches.
- `read-tree HEAD` plus `diff-index` and `ls-files -o`: it is slower than the copy, and it is three commands where the copy is one.

### Requests to the server

The command and the runners call the server with Ruby's Net::HTTP, pinned through its certificate-verification callback. It didn't block other fibers in a measurement: three one-second requests at once took 1.03 seconds.

Options weighed:

- httpx and async-http: dependencies for nothing Proof needs.

### The HTTP server

The server is Falcon, which serves each connection on a fiber. Measured on Ruby 4.1.0-preview1, with 4 and with 40 long-lived streams open, Falcon answered a new request in 3 ms and 2 ms. `git push` and `git clone` through `git http-backend` worked with 40 streams open. Git's smart HTTP is served by `git http-backend`, because no maintained Rack library serves it.

A handler that blocks without yielding to the fiber scheduler stalls every request. Every wait in the server, on a socket, a subprocess, or a lock, has to yield.

Options weighed:

- Puma 8.1.3 with 4 threads, Iodine, and Agoo: each answered nothing with 4 streams open.
- WEBrick: passed the same measurement, but gives each connection a thread with no limit, and has a history of request-smuggling fixes.

### Certificates

The server makes an EC P-256 key with Ruby's `openssl`. The command and every runner pin the SHA-256 of the server's public key, the form Git's `http.pinnedPubkey` takes, so the command, the runners, and Git use one fingerprint. How a new command or runner first learns the fingerprint is still open in [issue #17](https://github.com/setdef/Proof/issues/17).

Options weighed:

- The `localhost` gem: puts an IP address in a DNS-name field, adds a separate certificate authority, and writes under `~/.local/state`. Falcon's TLS setup loads only RSA keys.

### Native calls

Native calls go through Fiddle on every system. Fledge's runtimes ship Fiddle as a bundled gem, and Fledge's tests call native code through it in built apps on macOS and Linux. No Proof code has yet called Win32 through it. `Kernel#syscall` can't do the job everywhere: it raises `NotImplementedError` on macOS (measured on Ruby 4.1.0-preview1), it doesn't exist on Windows, and its call numbers differ between x86-64 and ARM64 Linux.

Options weighed:

- `Kernel#syscall` on Linux with Fiddle elsewhere: two ways to do one thing.
- A helper program in another language for each native call: a second language, which [the decision for Ruby](decisions/0001-proof-is-ruby-shipped-as-a-fledge-app.md) rules out without a reason only it can meet.

### Run IDs and codes

Crockford Base32 is written in the domain gem. The domain has no dependencies, and [the glossary](../glossary.md#run) says Proof reads a typed `o` as `0` and an `i` or `l` as `1`, so the decoder is part of the domain's rules.

Options weighed:

- A Base32 gem: adds a dependency to a gem that has none, for an alphabet and a mapping that fit in one value object.

### Storage

Storage is ROM, with `rom` and `rom-sql` over Sequel and the `sqlite3` gem. Sequel's `fiber_concurrency` extension and a busy handler that sleeps make a write waiting on a lock let other fibers run. The store refuses a second placement row for a run with a unique index, which ROM raises as `ROM::SQL::UniqueConstraintError`.

Measured with 4 processes of 20 fibers each choosing runners under contention, 5 runs each:

| Driver | Result |
| --- | --- |
| ROM over `sqlite3`, with `fiber_concurrency` | Every run placed once and no host's resources offered twice, in every run, with a fiber yielding inside each transaction and without |
| ROM over `sqlite3`, without `fiber_concurrency` | Runs placed twice, in every run |
| Sequel over `sqlite3`, used directly | Every run placed once, no host's resources twice |
| Sequel over `extralite` | Every run placed once, no host's resources twice, no errors |
| `sqlite3` used directly | Runs assigned twice, hosts oversubscribed |
| `extralite` used directly | Lock errors raised |

The risk is `rom-sql`'s release cadence: its last release was in January 2025, though its repository has had commits since. The adapter sits behind the domain's ports, so replacing ROM touches one folder.

Options weighed:

- Sequel used directly: it met every requirement measured, as ROM did. ROM was chosen by preference.
- `extralite` as the driver: it fails at once on a lock unless given a progress handler, and the progress handler then holds the GVL for every query.

### Use cases, validation, and composition

Use cases are plain Ruby objects. A refused rule raises a dedicated error class. The domain's constructors check inputs. The composition roots are plain Ruby that builds the objects and hands each its ports.

Options weighed:

- dry-operation: adds dry-monads and Zeitwerk, 63 ms to every start of the command, and its transaction support ties use cases to Sequel.
- dry-validation: loads dry-types into the domain through dry-schema.
- dry-system: takes 61 ms to boot an empty container, for three composition roots.

### Documentation

The API documentation is RDoc in the `.rbs` files, written in Markdown. A `.rb` file has comments only inside method bodies, because RDoc takes a comment above a definition as its documentation, even with blank lines between. The gate checks both: `rake rdoc:coverage` for the `.rbs` files and `rake docs:placement` for the `.rb` files.

Documentation examples in Markdown pages and in `.rbs` comments run as tests, through a runner written for Proof. `rake docs:examples` runs them, one Ruby process for each file.

Options weighed:

- A tool that already runs examples from `.rbs` comments: no maintained tool reads `.rbs` files.
- minitest-markdown: silently passes a wrong `# =>` on the same line.
- The YARD tools: read only YARD's `@example` tags.

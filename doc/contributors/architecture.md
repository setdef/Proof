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

A run is stored as an append-only list of facts, each with the server's time. The run's constructor checks every rule about a run, including when the run is rebuilt from storage. A record changed behind Proof's back therefore fails to load, instead of reporting a pass. The list also shows afterwards how a run reached `succeeded`. Which states a run can pass through, and what each ending needs, are still open in [issue #42](https://github.com/setdef/Proof/issues/42); the facts are the same whichever way it is settled.

Options weighed:

- A record of plain fields with a version number: it meets every requirement in [the server design](design/server.md#runs-and-their-records), but it can't show afterwards how a run reached `succeeded`, and nothing in it fails when a field is edited by hand.

### Placing a run

Choosing a run's runner is a domain service. It checks the rules that span runs and hosts: a host's resources counted once across its runners, arrival order, labels, and the share. It then writes one fact to one run. Three things keep the decision safe:

- The store itself refuses a second placement fact for a run.
- The server's unit of work serializes placement decisions.
- A host's resources in use are computed from its runs, and never stored on the host, so there is no second copy to disagree with the runs.

How placement orders and counts is still open in [issue #43](https://github.com/setdef/Proof/issues/43); [the server design](design/server.md#placement) says what must hold.

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

The command uses Ruby's OptionParser, which requires exact flag names, and dispatches by hand. The tests compare it with `usage explain --format json` for each case [`proof.usage.kdl`](../../proof.usage.kdl) defines, so the spec and the parser can't drift apart.

Options weighed:

- Samovar: reads options only before positional arguments, so it refused `proof run test --os linux`.
- dry-cli, at 1.4.1: for `proof run build a b` it passed the task's name again as the task's first argument (`args` was `["build", "a", "b"]`). For an unknown flag it printed only `"proof run" was called with arguments "build --nope"`, without naming the flag. It also has no way to pass unknown flags through to the task, which [`proof.usage.kdl`](../../proof.usage.kdl) requires of `run` (`unknown_flags="value"`).
- Thor: its list options took the task's flags.
- tty-option: has no subcommands, and has had no release since 2023.

### KDL

The `kdl` gem reads KDL, always called with `version: 2`. One reader in `lib/proof` wraps it, outside the domain gem, which has no dependencies. Errors carry the line and column.

### Git

Proof runs the `git` program as a subprocess, with every inherited `GIT_*` variable removed so that a hook or a parent Git process can't redirect it.

Options weighed:

- Rugged: builds libgit2 from source, its certificate check can't see the certificate, and it has no check that a commit is complete, which [the decision on code](decisions/0003-code-travels-as-git-commits-through-the-server.md) needs.
- The `git` gem: wraps the same program, and pulls in ActiveSupport.

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

Storage is Sequel over the `sqlite3` gem, with Sequel's `fiber_concurrency` extension and a busy handler that sleeps. A write waiting on a lock then lets other fibers run.

Measured with 4 processes of 20 fibers each choosing runners under contention, with a fiber yielding inside each transaction:

| Driver | Result |
| --- | --- |
| Sequel over `sqlite3` | Every run assigned once, no host's resources twice, no errors |
| Sequel over `extralite` | The same |
| `sqlite3` used directly | Runs assigned twice, hosts oversubscribed |
| `extralite` used directly | Lock errors raised |

Options weighed:

- `extralite` as the driver: it fails at once on a lock unless given a progress handler, and the progress handler then holds the GVL for every query.
- ROM: storage is append-only facts with a versioned append, byte logs read at offsets, and files, which the domain's constructors already build from rows, so ROM's relations and mappers have little to map. `rom-sql` has had no release since January 2025. It also sits over Sequel, whose constraints Proof needs anyway: refusing a second placement fact and checking the expected version.

### Use cases, validation, and composition

Use cases are plain Ruby objects. A refused rule raises a dedicated error class. The domain's constructors check inputs. The composition roots are plain Ruby that builds the objects and hands each its ports.

Options weighed:

- dry-operation: adds dry-monads and Zeitwerk, 63 ms to every start of the command, and its transaction support ties use cases to Sequel.
- dry-validation: loads dry-types into the domain through dry-schema.
- dry-system: takes 61 ms to boot an empty container, for three composition roots.

### Documentation

The API documentation is RDoc in the `.rbs` files, written in Markdown. A `.rb` file has comments only inside method bodies, because RDoc takes a comment above a definition as its documentation, even with blank lines between. The gate checks both: `rake rdoc:coverage` for the `.rbs` files and `rake docs:placement` for the `.rb` files.

Documentation examples in Markdown pages and in `.rbs` comments run as tests, through a runner written for Proof.

Options weighed:

- A tool that already runs examples from `.rbs` comments: no maintained tool reads `.rbs` files.
- minitest-markdown: silently passes a wrong `# =>` on the same line.
- The YARD tools: read only YARD's `@example` tags.

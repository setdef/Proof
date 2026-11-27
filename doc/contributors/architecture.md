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

The domain lives in a gem in this repository, `gems/proof-domain`. It has no runtime dependencies, only Ruby's standard library, and a test fails if the gem loads anything outside itself. Ruby's default gems are part of its standard library, so the test counts one at the version Ruby ships as standard wherever a bundle installed it: Falcon requires the `openssl` gem, and `Gemfile.lock` locks 4.0.2, the version Ruby 4.1.0-preview1 ships, which Bundler installs in the bundle.

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

#### Lists in messages

Proof builds each list in a message of the domain or of a file reader with `Proof::ListFormat`, in the domain gem: the units and examples a `Proof::Duration` takes, and the properties and children a `Proof::KdlRefusal` says a node has. It joins items with "and" or with "or", and a serial comma before the last of three or more, as JavaScript's `Intl.ListFormat` does in English. The rule is one of the English of Proof's messages, not of any value, so it is a module apart from every value. It is in the domain because the domain's values and the readers in `lib/proof` both use it, and `lib/proof` depends on the domain, never the reverse.

Options weighed:

- A copy of the list rule in each message: three copies of one rule, and three tests of the comma.
- ActiveSupport's `Array#to_sentence`: a dependency, which the domain gem can't have.

### A run as a consistency boundary

A run is stored as an append-only list of facts, each with the server's time. The run's constructor checks every rule about a run, including when the run is rebuilt from storage. A record changed behind Proof's back therefore fails to load, instead of reporting a pass. The list also shows afterwards how a run reached `succeeded`. Which states a run can pass through, and what each ending needs, are in [the server design](design/server.md#runs-and-their-records) and [the runner design](design/runner.md#a-runs-end), and the facts record them.

Options weighed:

- A record of plain fields with a version number: it meets every requirement in [the server design](design/server.md#runs-and-their-records), but it can't show afterwards how a run reached `succeeded`, and nothing in it fails when a field is edited by hand.

#### The facts and the store of runs

`Proof::Run` is built from its ID and its facts, and compared by its ID. Each fact is a `Data` value under `Proof::Run`, with the time on the server's clock as `at`:

| Fact | Holds | Comes |
| --- | --- | --- |
| `Queued` | The queue position, the operating systems the run may go to, the labels it needs, and the CPUs and memory it requests | First, and only first |
| `Placed` | The host and the runner | Once |
| `CommandStarted` | Nothing more | Once, after `Placed` |
| `CommandEnded` | An exit status or a signal, never both | Once, after `CommandStarted` |
| `OutputCompleted` | The number of bytes | Once, after `CommandEnded` |
| `ArtifactsKept` | Nothing more | Once, after `CommandEnded`, and never with `ArtifactsNotKept` |
| `ArtifactsNotKept` | Why: `no_match`, `over_limit`, `refused_path`, or `short_of_space` | Once: for space after `Placed` and before `CommandStarted`, for any other reason after `CommandEnded` |
| `CancelAsked` | Nothing more | Once, any time before a final state |
| `Succeeded`, `Failed`, `TimedOut`, `OutOfMemory`, `Canceled`, `Lost` | Nothing more | Once, as the final state |
| `ProcessesEnded` | Nothing more | Once, after `Lost`, the only fact a final state can be followed by |

Each final state is allowed only after the facts it needs: `Succeeded` after a command that exited with 0, the whole output, and kept artifacts; `Failed` after the whole output and a status other than 0 or unkept artifacts, or after artifacts left unkept for space; `TimedOut` and `OutOfMemory` after the command started; `Canceled` after a cancel was asked for; `Lost` after the run was placed. A run holds its host's CPUs and memory while it is `running`, and while it is `lost` until its processes end. `Canceled` needs no placement, because the glossary's `canceled` covers a run that is still `queued` and ends with no runner. Such a run holds nothing, and placement never places it: `place_next` and `wait_reasons` skip a queued run whose cancel was asked for. A run that has a runner is `canceled` when its runner ends it. [The command design](design/command.md#output-and-exit-status) says what `proof` exits with for a run that someone else canceled.

The store of runs is the port `Proof::_Runs`. It adds a fact only at the version the caller read, the run's number of facts, refuses a second placement whatever the version, refuses a second run at one queue position, and rebuilds each run from its facts on every read. `Proof::InMemory::Runs` keeps the facts in a `Hash` behind a mutex. `Proof::Testing::RunsContract` is the Minitest module every store passes, with two tests that run two threads at once and one that reopens the store over the same storage. One thread's call usually ends before the other's starts, so a store passes those two even with no lock. A store's test can define `build_runs_pausing_after_reads`, which the two tests call in place of `build_runs`: it builds a store that sleeps after each read, so the other thread's call comes between a call's read and its write, and a store with no lock fails them. `InMemoryRunsTest` defines it with a `Hash` that sleeps after each lookup.

Options weighed:

- One fact for every final state, with the state as a field: every rule about an ending would test the field, where with a class per state each rule checks for its class.
- The run's settings from the project file, `Proof::RunSettings`, in `Queued`: they give every setting as optional, so placement would test for an OS that can't be missing, and they hold each task's command, which placement never reads. The use case that queues a run takes the operating systems, labels, and resources from them.
- An exit status alone, with a signal written as 128 plus its number: a command that exits with 137 and one killed by signal 9 would be one fact.
- A second `CancelAsked` for a second `TERM`: it records nothing new, and records are bounded per run.
- A store that took Ruby objects instead of facts: nothing would rebuild a run on reading, so a record changed behind Proof's back would load.

### Placing a run

Choosing a run's runner is a domain service. It checks the rules that span runs and hosts: a host's resources counted once across its runners, arrival order, labels, and the share. It then writes one fact to one run. Three things keep the decision safe:

- The store itself refuses a second placement fact for a run.
- The server's unit of work serializes placement decisions.
- A host's resources in use are computed from its runs, and never stored on the host, so there is no second copy to disagree with the runs.

How placement orders and counts is in [the server design](design/server.md#placement), which says what must hold.

Options weighed:

- A consistency boundary per host that holds its resources: one placement would write to the host and to the run, so no single boundary would cover it.
- One consistency boundary for the whole queue: every byte of output would wait on its lock.

#### How placement decides

`Proof::Placement` takes the store of runs, the hosts, and the server's clock by keyword: `runs:`, `hosts:`, and `clock:`. The port `Proof::_Hosts` gives each `Proof::Host` with its share, whether a person is active, and its runners. Each `Proof::Runner` has its OS, the labels it offers after the pool file withholds any, its capacity, and whether it is connected.

- **What is free.** A host's capacity is the most any of its runners reports, of each resource. A new run on a runner can have what is free on the host, after every run the host holds on any of its runners and after what it keeps for a person, and no more than what is free on the runner, after the runs on that runner. The host keeps the memory of its share always, and its CPUs while a person is active. A run counts against a host only while the runner it was placed on is one of the host's, so revoking a runner releases what its runs held.
- **`place_next`** places one run per call, so one decision is one unit of work. It takes the queued runs earliest first, leaving out any whose cancel was asked for, and places the first one that fits a connected runner of its OS, with every label it needs, and with its CPUs and memory free. Of the runners that fit, the one with the most memory free takes it, then the one with the most CPUs free, then the first runner by name, then the first host by name.
- **`wait_reasons`** gives each queued run that fits nowhere, and whose cancel wasn't asked for, its nearest reason, from what stops it on each runner of its operating systems: runs holding the host, then a person active there, then no connected runner that could ever take it, then no runner with its labels. A run whose operating systems have no runner waits for one to connect. No reason says that a host needs someone to sign in, because nothing a runner reports says so.
- **`check`** takes the fact that would queue a run, before it is stored, and raises `Proof::RunFitsNoHostError` when runners take the run's OS and labels but none could ever have its CPUs and memory free: its host's capacity less the memory of the share, within the runner's capacity. Its message names the host whose worst shortfall is the smallest, and lists every resource that host lacks, each a `Proof::Shortfall`. A shortfall is the part of a requested resource that the host could never have free, and a host's worst is the largest of its own. The code compares the part a host could have, `Proof::Shortfall#fraction`, so the host whose smallest part is the largest wins, and a tie goes to the first runner by name, then the first host by name. A run with no runner of its OS, or no runner with its labels, waits instead.
- **The private helper modules.** `MemberCheck`, `RunnerChoice`, `WaitCheck`, `ClosestHost`, `Room`, and `PoolNames` are private constants of `Proof`, and each holds code that a class needs and can't hold itself. For all but the first the reason is a limit of the gate, not a boundary in the domain. RubyCritic rates a file A only while the complexity of its methods adds up to 50 or less, and reek flags a method that uses none of its object's state, so a helper that takes its runs and hosts as arguments fails the gate as a private method of a class.
  - `MemberCheck` holds the check of a value's members against a table of messages and rules, and the checks that a value is a name, as `Proof::Name` says, or a flag. `Host` and `Runner` check their members with it, and `Run::Fact` checks a name with it. It isn't in either value because it serves several, and values made with `Data.define` can't share a superclass. It also isn't in `Host`, because `Host` would then be rated B.
  - `RunnerChoice` holds how `place_next` finds the first queued run that fits and the runner it goes to, with the order that puts the emptiest runner first. It isn't in `Placement` because `Placement` would then be rated B, and its methods use no state of a `Placement`. They take the queued runs, the hosts, and the runs that hold resources.
  - `ClosestHost` holds how `check` finds the host that fits the most of a run that none could ever take, and builds the error that names it. It isn't in `Placement` for the same reason: `Placement` with it would be rated B, and its methods use none of its state.
  - `Room` holds a host's capacity from its runners, and what is left of resources after the runs that hold them and what the host keeps for a person. It isn't in `Host` because `Host` would then be rated B.
  - `PoolNames` holds the rules about names that a pool file's entries may not share: two hosts with one name, a runner on two hosts, and two repositories with one name, each compared without regard to case with `Proof::Name.same?`, which holds that rule for the domain and for the readers, and `MemberCheck` compares the runners of a host with it too. It isn't in `PoolFile` because `PoolFile` would then be rated B.
  - `WaitCheck` holds what stops one run on one runner, the nearest of those reasons across runners, and the runs that hold a host. `WaitReason` is the value that gives the answer, and the helper isn't in it because `WaitReason` would then be rated B.

Options weighed:

- Placing every run that fits in one call: the unit of work would hold its lock across many writes, and a failure part way through would leave some runs placed and others not.
- The first runner that fits, by name: it fills one host before the next has any run, so a host someone uses fills while others have room.
- A runner's capacity without the runs already on it: two runs that each fit WSL could go to it together and need more memory than it has.
- A capacity for each host from a source of its own: nothing reports one, and a runner in a virtual machine never has more than its host, so the most any runner reports is the host's.

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

The command uses Ruby's OptionParser with `require_exact`, which refuses an abbreviation of a flag's name, and finds the command by hand: it follows the words down the commands of the spec, and a table maps a command's words to the class that holds its flags and arguments. OptionParser takes its flags from `lib/proof/command_line/spec.json`, which `usage generate json` writes from [`proof.usage.kdl`](../../proof.usage.kdl), so a flag added to the spec reaches the parser and the help together. The help is written from the same file, with no KDL read at run time and no `kdl` gem, so the command starts on Ruby's standard library alone. For a flag it doesn't know, OptionParser raises an error that gives the flag (`invalid option: --oss`, with `--oss` in the error's `args`). Ruby's did_you_mean gives the suggestion: `DidYouMean::SpellChecker`, given the command's flags, answers `--os`. A flag written with one dash, or several short flags written together, gets no suggestion, because the letters of short flags are near each other. The command prints both and exits 2, the status [`proof.usage.kdl`](../../proof.usage.kdl) gives to a mistake on the command line.

`proof run` takes Proof's flags anywhere before `--`. The words for the task follow `--`, as for `cargo run` and `npm run` ([issue #18](https://github.com/setdef/Proof/issues/18)). A plain word before `--`, as in `proof run test foo`, goes to the task, as `proof.usage.kdl` reads it: `usage` can mark a word after the task as a mistake only by requiring `--`, which would also refuse `proof run lint ::: test`. The parser is tested against the spec, so it does the same. Only a flag before `--` is refused, which is where typos of Proof's own flags happen. `:::` starts the next task, before or after `--`. After `--`, words go to the current task until a `:::`, the word after `:::` is the next task's name, and that task's words again follow `--`. OptionParser stops reading flags at the first `--`, so the command splits what follows by hand: the first `--` after a task's name separates its words from Proof's flags, and a later `--` is one of the task's words. The tests compare the parser with `usage explain --format json` for command lines made from the spec, and a difference in whether a line is accepted or in what a word binds to fails the test. They include the front of each flag, command, and choice, which usage refuses and which OptionParser takes for a flag unless `require_exact` is set. What usage can't say, such as the nearest flag in a mistake and where `:::` has no task before it or no name after it, has its own tests.

Options weighed:

- Samovar: reads options only before positional arguments, so it refused `proof run test --os linux`.
- dry-cli, at 1.4.1: a repeated `--os linux --os windows` kept only `windows`, silently. Every yes-or-no flag also gained a `--no-` form that the spec doesn't have, and it accepted the abbreviation `--dry` for `--dry-run`. `--os beos` and a missing task or script got no specific error, or none. It has no global flags, and it exits 1 for a command-line mistake where the spec gives 2.
- Thor: its list options took the task's flags.
- tty-option: has no subcommands, and has had no release since 2023.

### KDL

`Proof::ProjectFileReader` reads the project file, and the `kdl` gem reads its KDL. The reader lives in `lib/proof`, outside the domain gem, which has no dependencies and never loads `kdl`. It builds every value with the domain's classes, so a size, a label, or a path has one rule, and it raises `Proof::ProjectFileError` for every mistake, with the file, the line, and the reason. `Proof::GitProject#file_at` is a general method, so a path that is a symbolic link raises `Proof::SymbolicLinkError`, which names the path and the commit. `Proof::ProjectFileReader.read_from`, which reads the project file of a commit, turns it into a `Proof::ProjectFileError` that says Proof reads only a regular file there. `Proof::ProjectFileForms` lists what each node of the project file takes, and `Proof::KdlFormCheck` checks the file's nodes against it, as it checks the pool file's. `Proof::TaskReader` reads each `task` node, and `Proof::ProjectFileSettings` the properties and children of a `defaults` or `task` node. `Proof::ProjectFileRefusal` holds the project file's messages, and words three mistakes as the project file page writes its nodes: the arguments of each node, a child with a property or a block, and a child with the name of a property, which is a child the node doesn't have.

- **The dependency.** `proof.gemspec` lists `kdl` at `~> 2.2.0`, and `Gemfile.lock` locks 2.2.0 with its SHA-256. The pin takes patch releases of 2.2 and nothing newer, because the reader finds each node's line through a private method of the gem's parser, which the gem doesn't document and a release can change. A new minor release is checked before Proof takes it.
- **The extra gems.** `kdl` 2.2.0 requires `racc ~> 1.5`, `simpleidn ~> 0.2.1`, `bigdecimal ~> 3.1.6`, and `base64 ~> 0.2.0`, and loads all four when it loads. The lockfile already held `racc` 1.8.1 and `bigdecimal` 3.1.9, and now adds `simpleidn` 0.2.3 and `base64` 0.2.0. The constraints on `bigdecimal` and `base64` exclude the versions that Ruby 4.1.0-preview1 bundles, 4.1.3 and 0.3.0, so the lockfile holds older versions than that Ruby does. The gem uses `racc` for its parser, `bigdecimal` for a decimal beyond a `Float`'s range, and `base64` and `simpleidn` for type annotations such as `(base64)` and `(hostname)`. The reader reads no type annotation: it passes `parse_types: false`, so `(date)"2026-11-26"` is the text `2026-11-26`.
- **The pool file.** `Proof::PoolFileReader` reads the text of the pool file and its path into a `Proof::PoolFile`, and reads nothing else: the server reads the file from its disk, and checking the whole file before any of it is used, and keeping the last good version, is the server's. It parses with `Proof::KdlParser` and raises `Proof::PoolFileError` for every mistake, with the path, the line, and the reason, as the project file's reader does. `Proof::FileError` and `Proof::FileRefusal` hold what the two readers share: the error's path, line, and reason, and the refusal's path, error class, and messages. `Proof::PoolFileForms`, a `Proof::KdlForms`, lists what each node of the pool file takes as one `Proof::KdlForm` apiece, so a node the page gains is a line of data. `Proof::KdlFormCheck` checks the nodes of any KDL file against its forms, in the order the file has them: a node that may not be at the top, a second node that may be given once, and each node's arguments, properties, and children. `Proof::KdlRefusal` gathers what each of those refusals says, such as the properties a form lists and how to write it, and words it with the file's messages, which name what they say, so `Proof::PoolFileRefusal` holds the pool file's messages and the refusals only a pool file has. Two rules keep the names of a pool file's entries apart, each with its reason and its message. `Proof::PoolFileRepeatedEntries` refuses a second host or repository with an earlier one's name, because each has one entry. `Proof::PoolFileSharedRunners` refuses a runner that two hosts list, because a runner is one operating system on one host. Each refuses at its line, where the domain's `Proof::PoolFile` would refuse with no line, and each compares names without regard to case with `Proof::PoolFileNames.same?`, which asks the domain's `Proof::Name.same?` for text and keeps no rule of its own. They are two classes because they are two rules of the pool file: they read different nodes, an entry's name or a host's `runner` children, and their messages say different things. `Proof::PoolFileReader` checks them in the domain's order: a second host, then a runner on two hosts, then a second repository. `Proof::PoolFileProperties` builds the values of `server`, `retention`, and `limits`, `Proof::PoolFileHosts` those of `defaults` and of every `host`, with `Proof::PoolFileHost` for one node, and `Proof::PoolFileRepositories` those of every `repository`, with `Proof::PoolFileRepository` for one, each with the domain's classes. `Proof::PoolFileNames` reads the names a node's children give, a runner, a credentials file, a branch, or a task, with the domain's `Proof::Name`, so one that is empty or only white space is refused at the line of its child with the domain's message, and the entries refuse a host's name and a repository's name and URL that are blank, at the line of the node. A `runner` and a `task` may be given in several nodes, because the page's example gives them so, and every other child may be given once, as the project file's children are. A host with no budget in its entry or in `defaults` is refused at the host's line, because the page requires one.

  Options weighed:

  - A reader written as code for each node: the pool file has six nodes and ten children, and each would carry checks of arguments, properties, and children, so a rule would be written in a dozen places, and the project file's reader would write the same checks again.
  - One set of messages for both files: each page writes its nodes its own way, as in `task NAME [COMMAND]`, so each file's messages keep its page's words.
  - One class for the top of the file and another for a node's form: the top of a file is checked as a block's children are, for a name the form doesn't list and a second node that may be given once, so the two would hold the same check twice.
  - The check choosing the words of a refusal, such as a property written as a child: it would be the same for every file, where a file's words are its own, and a file that words a mistake differently would need the check to know it.
  - The domain's `Proof::PoolFile` alone, which refuses a port, a repeated name, and a shared runner: its errors have no line to name.
  - One class for every name two entries share: it held two rules with different reasons and messages, and someone reading one had to read past the other.
  - The domain's error naming the entries that share a name, so the reader could find their lines: the rule would be in one place, and the domain's message and its error would change for a reader's sake.
  - Checking the names of children before the entries are built, and reading them again to build them: two passes over the same children, where reading each name with its rule gives the value and the refusal at once.
- **KDL 2 only.** `KDL.parse` without `version: 2` reads a text as KDL 1 when the KDL 2 parser fails on it, and drops the file's name from its errors. The reader calls `KDL::Parser`, the KDL 2 parser that `KDL.parse` calls for `version: 2`, and gives the path itself, so a KDL 1 text is refused. A test reads a text that is valid KDL 1 and not KDL 2, and a text that starts with `/- kdl-version 1`, and both are refused.
- **Lines.** The gem keeps a line on its errors and its tokens, and none on a node, so a mistake in what a file says, such as a label with a space in it, has no line to name. `Proof::KdlParser`, `Proof::KdlLines`, and `Proof::KdlSyntaxReason` hold the code that touches the gem. Each reader names the error `Proof::KdlParser` raises, so the code that touches the gem knows no kind of file. The files of `Proof::KdlLines` load the gem, so `Proof::KdlParser` loads them with `autoload`, the first time it parses, and `require "proof"` loads none of the gems that `kdl` brings. `test/proof_load_test.rb` runs that in a new Ruby process and fails when the load adds any of them. The grammar builds a node right after it reads the node's name, so a subclass of the parser records the line of each token in its private `next_token`, and a subclass of the gem's node class takes the last line recorded when the grammar builds it. `test/kdl_parser_test.rb` fails when a release changes how a node gets its line: it checks each node's line across nodes separated by `;`, nested nodes, the node after a `/-` node and the children of one, entries continued with `\`, and a text with CRLF line breaks.
- **Two faults of 2.2.0.** The gem fails on some valid KDL 2, and loops on some text that isn't. Its grammar refuses a space, a tab, or a comment between a block's closing `}` and the end of the node, as in `task a { os linux } // the test`, because it reads that space as the start of a block to skip. `Proof::KdlLines::LinedParser` drops the space when the token after it is a line break, the end of the text, or a `;`. And its tokenizer never stops at the end of a block comment that has no `*/`, because at the end of the text it reads nothing and moves on. `Proof::KdlLines::EndOfText` is prepended to `KDL::Tokenizer`, so every tokenizer of a parse, including the one the gem makes for a line continued with `\`, raises the gem's own error when it reads more than a few characters past the end of the text. `test/kdl_parser_test.rb` has a test for each, and the second runs under a timeout so that a loop fails the test and doesn't stop the suite.
- **Errors that aren't the gem's own.** The gem raises an `ArgumentError`, with no line, for a byte that isn't UTF-8, and a `TypeError` for a string that a backslash ends the text in. `Proof::KdlParser` reads the text as UTF-8, whatever encoding its string has, and refuses a byte that isn't UTF-8 at the line it is in. It refuses the string with the backslash at the last line.
- **A limit of 2.2.0.** A carriage return alone ends a node, but the gem doesn't count it as a line break, so the lines after one are numbered as if it weren't there. A line feed and a carriage return with a line feed count.

Options weighed:

- A second pass over the tokens of `KDL::Tokenizer`: the gem's README documents no tokenizer, and finding the node names among the tokens means writing again the grammar's rules for type annotations, `/-`, and blocks.
- A reader written for Proof: the reasons to write it can be fixed in `kdl` for everyone ([issue #54](https://github.com/setdef/Proof/issues/54)).
- `vexyl`'s reader: it reads every number as a float, and it failed 5 of the 338 cases of the official KDL test suite.

### The pool file on the server

`Proof::Server::CurrentPoolFile` holds the pool file the server uses and the mistake that `proof status` shows. It reads each text whole with `Proof::PoolFileReader`, which builds every value before it returns any, so a text with a mistake on any line leaves the last version that had none in use, and becomes the mistake, with its path and line. A text with no mistake becomes the pool file and clears the mistake. Before the first text with no mistake there is no pool file, so a server that starts with a mistake runs no runs. A file the server can't read, such as one that isn't there, is a mistake with no line, and the last good version stays in use. `port` is the pool file's port, or 7443, the page's default, when there is none.

`Proof::Server::PoolFileWatch` reads the file on each `check`, which the server makes when it starts and every second after, and gives the text to `CurrentPoolFile` when it differs from the last text it read, so an edit takes effect for the next run without a restart. It compares the text, not the file's time or size, so an edit within one tick of the file system's clock, a copy that keeps the old time, and an edit that keeps the size are all read. For each text it reads, it writes lines to standard error, after `proof:`, where the service manager records them:

| What it read | Lines |
| --- | --- |
| A text with no mistake | `proof: read PATH, and the next run uses it.` |
| A mistake, with a good version from before | `proof: PATH:LINE: REASON`, then `proof: the server keeps the last version of PATH that had no mistake until you fix it.` |
| A mistake, with no good version | `proof: PATH:LINE: REASON`, then `proof: the server runs no runs until you fix PATH.` |
| A file it can't read | `proof: PATH: the server can't read it: REASON`, then one of the two lines that follow a mistake |

The reason for a file it can't read is the system's text for the error, such as `No such file or directory`, without the call and the path that Ruby's message adds.

Options weighed:

- Notices of a change from the operating system, through the `listen` gem: it loads `rb-inotify` on Linux or `rb-fsevent` on macOS, with `ffi`, a gem with a native extension, and runs threads of its own, for one file of a few kilobytes.
- Comparing the file's modification time: two saves within one tick of the clock, or a copy that keeps the old time, would go unread.
- Reading the file again on `SIGHUP`, as nginx and sshd do: the pool file page says the server reads the file whenever it changes, with nothing for a person to send.
- Reading the file only before each placement: a mistake would show only when a run arrives, and a lower share would place nothing until something else asked for a placement.

### Git

Proof runs the `git` program as a subprocess, with every inherited `GIT_*` variable removed so that a hook or a parent Git process can't redirect it.

`Proof::Git` runs the program in a folder and raises `Proof::GitFailedError` when it fails. `Proof::GitProject` finds the project from a folder, refuses a partial clone, turns a revision into a commit ID, and gives the text of a file at a commit, which `Proof::CommittedFile` reads from the commit's tree. `Proof::WorkingTreeCommit` makes the working-tree commit, with the commit `HEAD` names as its parent, or none in a project with no commit yet.

Options weighed:

- Rugged: builds libgit2 from source, its certificate check can't see the certificate, and it has no check that a commit is complete, which [the decision on code](decisions/0003-code-travels-as-git-commits-through-the-server.md) needs.
- The `git` gem: wraps the same program, and pulls in ActiveSupport.
- Reading a file at a commit in a module that `Proof::GitProject` includes: the module would call the project's methods without a type to say so, to keep one class short.

#### A submodule in a working-tree commit

A working-tree commit records each submodule at the commit its checkout is at, as `git add -A` records it. A submodule the developer has moved to another commit goes at that commit, even when the project hasn't committed the move. Changes to files inside a submodule are not sent, as [the command design](design/command.md#which-project-and-which-code) says. A run of `--commit REV` uses the tree of that commit, so it sends the submodule commits that tree records.

Options weighed:

- Pinning each submodule to the commit `HEAD` records: it drops a submodule bump the developer hasn't committed, and a working-tree run sends the working tree as it is.

#### A project with no commit

A project with no commit yet gets a working-tree commit made from an empty index, with no parent. `--commit` of any revision in such a project is refused as an unknown revision, because the project has no commit for a revision to point to.

Options weighed:

- Refusing a working-tree run: it stops a run in a new repository for no reason the run needs, because the run needs only the files.

#### The index a working-tree commit starts from

A working-tree commit starts its temporary index as a copy of the clone's index file, then runs `git add --all`, `git write-tree`, and `git commit-tree`. In a linked worktree the copy is of that worktree's own index file. A project with no index file starts from an empty index. A clone whose `index.lock` another Git process holds still gets its commit, because the copy reads only the index file, and Proof never takes that lock.

Every Git command that writes the temporary index runs with two settings, which Proof passes as `GIT_CONFIG_COUNT` and its `GIT_CONFIG_KEY_n` and `GIT_CONFIG_VALUE_n` variables, so they beat every configuration file:

- `core.splitIndex=false`, so the temporary index never refers to a shared index file in the clone's `.git`, and never adds one, whatever the clone's settings are. A copy of a split index adds a shared index file when enough of the index's entries changed, and the setting is what stops it.
- `core.fsmonitor=false`, so `git add` never starts a file-system monitor. With `core.fsmonitor=true`, Git's built-in monitor adds a socket to the clone's `.git` and keeps a process running after Proof ends, and with a path in `core.fsmonitor`, Git runs that program.

A probe on `rails/rails` at v8.0.2, with 4,762 tracked files, took the median of five runs:

| State | `read-tree HEAD` | Copy of the clone's index | `read-tree HEAD`, `diff-index`, and `ls-files -o` |
| --- | --- | --- | --- |
| Nothing changed | 0.39 s | 0.11 to 0.13 s | 0.15 s |
| One tracked file changed | 0.39 s | 0.11 to 0.12 s | 0.17 s |

Every existing file under `.git` stayed byte for byte the same in every case. With `core.splitIndex=true`, `read-tree HEAD` alone and with `diff-index` and `ls-files -o` each added a `sharedindex` file to the clone's `.git` for each tree state, and the copy added none in those two states. `read-tree HEAD` dropped a file the developer staged with `git add -f` that `.gitignore` matches. The copy and the three-command way kept it.

The copy is the fastest, and it sends a staged file the way `git commit` would, which is what "your working tree as it is" means to someone who staged it.

Options weighed:

- `read-tree HEAD`: it hashes every tracked file on every run, and it drops a file the developer staged that `.gitignore` matches.
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

#### Falcon in the server

`proof.gemspec` lists `falcon` at `~> 0.57.0`, and `Gemfile.lock` locks 0.57.0. Falcon is below 1.0, and its API changes between minor releases: 0.57.0 marks `Falcon::Server.middleware` deprecated in favor of `rack_middleware`. The pin takes patch releases of 0.57 only, and a new minor release is checked before Proof takes it.

`Proof::Server::Https` serves a Rack application with `Falcon::Server`, over sockets that are already listening, wrapped in io-endpoint's `BoundEndpoint` and `SSLEndpoint`. Falcon's TLS setup isn't used: it loads only RSA keys, and the server's key is EC P-256. `Https.context` makes the `OpenSSL::SSL::SSLContext`, with TLS 1.3 as both its least and its most version, and the server's identity as its certificate and key, so a client that offers only TLS 1.2 is refused in the handshake, before any request. Each connection speaks HTTP/1.1, with no ALPN: Net::HTTP, which the command and the runners use, speaks nothing else, and `git` falls back to it. Falcon's HTTP cache is off, because no answer of the server's may come from a cache.

Async, Falcon, and protocol-rack log through the `console` gem, which writes JSON to standard error. A refused handshake is logged as a warning with its backtrace, so a client of an older TLS, or a scanner of ports, would fill the server's log. `Https#run` sets the logger of the fiber it runs in, which every fiber it starts inherits, to one that writes only errors to the server's standard error, so an exception in a request's handler still reaches the log, and nothing outside the server's fibers changes.

Requiring `proof` loads none of this. `Proof::Server` loads each of its classes the first time something names it, and naming `Https` loads Falcon, Async, async-http, async-http-cache, async-utilization, console, the fiber-annotation, fiber-local, and fiber-storage gems, io-endpoint, io-event, io-stream, protocol-hpack, protocol-http, protocol-http1, protocol-http2, protocol-rack, and rack. That took 133 to 256 ms on an M1 Max, after 81 to 136 ms for `require "proof"`, once per start of the server. `test/server_load_test.rb` runs both in a new Ruby process, and fails when requiring Proof loads any of them, or when naming `Https` loads none. protocol-http 0.72.1 assigns a rescued error to a variable it never reads, and Ruby's `-w`, which the tests run under, warns of it, so `test/test_helper.rb` drops that one warning by its file and its text.

Falcon's gemspec also brings async-container, async-service, bake, localhost, samovar, and string-format, which the server doesn't load, and Fledge ships them all the same. Every gem it brings is Ruby, except two with C extensions, which Fledge compiles from source, as it does `sqlite3`:

- `io-event` 1.22.3, the fiber scheduler's event loop, ships only as source. On Linux its `extconf.rb` links liburing when liburing's headers are on the computer that builds it, and Fledge's documentation says it refuses a gem that links a library not every distribution has. So a Linux release is built where liburing's headers aren't installed, and io-event uses epoll, or with liburing listed in `fledge.yml` as a library of the distribution. On macOS it uses kqueue.
- `openssl` 4.0.2 is the version Ruby 4.1.0-preview1 bundles, and Falcon requires the gem. Fledge compiles a gem that links OpenSSL against the OpenSSL its runtime carries, the copy Ruby's `openssl` was built with.

`Gemfile.lock` keeps `aarch64-linux`, `arm64-darwin`, and `x86_64-linux` in its `PLATFORMS`. `bundle install` dropped all three when it added Falcon, and `bundle lock --add-platform` put them back.

Options weighed:

- Falcon's TLS setup, from an `https://` URL: it loads only RSA keys.
- HTTP/2 by ALPN, as Falcon offers by default: nothing that calls the server speaks it, and each follow is its own connection either way.
- The `localhost` gem's certificates, which Falcon offers for development: [Certificates](#certificates) says why the server makes its own.
- Async's `Async::HTTP::Server` with protocol-rack, without Falcon: the measurements in [The HTTP server](#the-http-server) were of Falcon, and Falcon adds only the middleware around the Rack application.

#### Requests

`Proof::Server::Requests` is the Rack application the server serves. It holds a table of paths, each with the answer to each method it takes, and the composition root builds it. A path the table doesn't have gets 404, and a method its path doesn't take gets 405 with the `allow` header, each with an `error` in JSON, so the command can tell a request the server lacks, as on a server of another version, from one that failed. Each answer in the table is an object with `call(env)`: it takes the request apart, calls its use case with the parts, and turns the result into JSON, so a use case sees no HTTP and a test calls it with no server. The composition root hands each use case its ports when it builds the answer.

`GET /version` is answered by `Proof::Server::VersionRequest` with `{"version":"0.1.0"}`, the server's `Proof::VERSION`. It needs no token, because the command checks the version before it signs in, and it calls no use case, because it has no rule to check and no port to call.

Options weighed:

- Roda, Sinatra, or Hanami's router: each runs its routes in blocks that change `self`, which Steep can't check without hand-written types for the whole DSL, for a table that is a `Hash` lookup. When a path takes a parameter, such as a run's ID, the first of them to weigh is Roda, which has no dependency but Rack and comes from Sequel's maintainer.
- Protocol::HTTP's own middleware in place of Rack: `git http-backend`, which the server will serve, is a CGI program, and a Rack environment is the CGI environment it reads.

### Certificates

The server makes an EC P-256 key with Ruby's `openssl`. The command and every runner pin the SHA-256 of the server's public key, the form Git's `http.pinnedPubkey` takes, so the command, the runners, and Git use one fingerprint.

A new command or runner first learns the fingerprint from a slow tag, keyed by the one-time code, over the server's key fingerprint. The tag uses scrypt, HKDF, ECDH, and AES-GCM from Ruby's `openssl`. The codes' format, the commands, and what a person types don't change. The reasoning is in [issue #17](https://github.com/setdef/Proof/issues/17).

Sign-in:

1. For each sign-in code, the server makes a fresh random nonce and keeps `T = scrypt(code, salt: "proof login", nonce, F)`, where `F` is the SHA-256 of its public key.
2. `proof login` connects with TLS 1.3 only and takes `F'` from the leaf certificate's key.
3. It fetches each `(nonce, T)` and checks for one that matches over `F'`.
4. Only then does it pin `F'` and send the code, which counts toward its 5 attempts.

A runner:

1. The runner makes its code `c` and a key pair `R`. It never sends `c`.
2. Its join request carries `R` and `J = scrypt(c, salt: "proof join", R)`.
3. `proof runner approve c`, on a computer already signed in, finds the pending request that matches `J`. It computes `S = scrypt(c, salt: "proof server", F, R)` itself, so `c` never reaches the server.
4. The server sends the runner its token encrypted to `R`, along with `S`. The runner pins `F'` only if `S` matches over the key it saw.
5. The runner forgets `c` 15 minutes after making it.

Rules:

- Every salt field is length-prefixed.
- The scrypt parameters (N=2^17, r=8, p=1, 32 bytes) are constants in Proof, never read from a server.
- There is no fallback to trust on first use.
- Nothing re-pins by itself after a key change.
- Pending join requests are capped and expire after 15 minutes.
- Codes are normalized before scrypt and compared in constant time.

An adversarial review found these flaws in the first draft, and the rules and steps above fix them:

- A relayed join request handed over a runner token.
- One salt per server allowed a table built ahead of time.
- A runner kept waiting could be searched for as long as an attacker liked.
- Anonymous join requests forced the server to compute scrypt.

A forged tag needs the code. Searching all 2^40 codes for one tag takes about 10,590 years on one M1 Max core, at a measured 0.304 s and 128 MiB per tag, and each code lasts 15 minutes. A fresh salt per code stops any table built ahead of time. A relayed join request gets the attacker nothing it can read, because the token is encrypted to the runner's key.

Options weighed:

- SPAKE2 (RFC 9382), bound to the TLS exporter (RFC 9266): it leaves no offline target at all. It lost because no maintained Ruby implementation exists. Proof would have to write its own elliptic-curve protocol on `OpenSSL::PKey::EC::Point`, whose constant-time behavior on every platform Proof ships to is unverified. Revisit this if a maintained implementation appears, or if measured GPU rates bring a code's search under hours.
- TLS with a pre-shared key: Ruby's `SSLContext` has no PSK support, and RFC 8446 says a low-entropy key can be searched from an observed handshake.
- An HMAC tag: 2^40 HMACs take about 38 days on one core.
- A fingerprint a person compares, or a longer code: people skip the comparison, agents can't make it, and a long code can't be typed from a text console.
- The `localhost` gem: puts an IP address in a DNS-name field, adds a separate certificate authority, and writes under `~/.local/state`. Falcon's TLS setup loads only RSA keys.

#### The code and the tags

The one-time code and the slow tags are in the domain gem. They hold rules of the check and no state, and they need only Ruby's `openssl`, which is part of the standard library the domain may load.

- `Proof::OneTimeCode` reads a code as Crockford's Base32, in lowercase with no hyphen, so every way of typing one code is one value, and refuses any other text without repeating it. It draws a new code's characters from the random source it is given. Its `==` compares with `OpenSSL.fixed_length_secure_compare`, and its `inspect` leaves the characters out. How long a code works and how many wrong attempts void it are kept by the server that issued it, so the value holds neither.
- `Proof::SlowTag.sign_in`, `.join`, and `.server` compute `T`, `J`, and `S`. Each takes a `Proof::OneTimeCode`, never text, so a code is read before scrypt sees it. `Proof::LengthPrefixed` writes each salt field after its length in 8 bytes, the label first. The fingerprint goes in as the 32 bytes of its hash, read from the `sha256//` form that `Proof::Server::Identity#fingerprint` gives, and the runner's key as the bytes its join request carries. A nonce is 16 bytes. A tag is 32 bytes, checked when it is read from bytes, and two tags compare with `OpenSSL.fixed_length_secure_compare`.
- `Proof::SlowTag::COST` holds the parameters, and no public method takes a cost. `Proof::TagMaker`, a private constant of `Proof`, computes the tags at the cost it holds. `Proof::SlowTag` makes one at `COST`, and `Proof::Testing::QUICK_TAGS` is one at N=2, r=1, p=1, which only the tests and the examples load.

Both comparisons use `OpenSSL.fixed_length_secure_compare`. Each value checks its length when it is built, so the two sides of a comparison always have one length, and `OpenSSL.secure_compare` would hash both first to hide a length that isn't secret.

Options weighed:

- The code and the tags in `lib/proof`, behind a port of the domain: a port with one adapter and nothing to swap, since the domain may load `openssl`, and the domain's values would leave a code's comparison to each caller.
- A cost passed to each method, with `COST` as its default: any caller could pass another, a value a server sent among them.
- A test cost set in the process, by a variable or a method the tests call: the code that computes every tag would read it, in production too.

#### The runner's token, encrypted to its key

`Proof::RunnerKey`, in `lib/proof`, is a runner's EC P-256 key, on the curve of the server's key. `generate` makes it on the runner, and `read` reads the public key, as DER, from a join request on the server. `public_der` gives the bytes that the join request carries and that `J` and `S` are over. `encrypt` and `decrypt` call `Proof::TokenCipher`, a private constant of `Proof`, which composes Ruby's `openssl`:

1. `encrypt` makes an ephemeral P-256 key for the token alone, and ECDH gives the secret it shares with the runner's key.
2. HKDF-SHA256, with an empty salt, makes a 32-byte key from that secret over `Proof::LengthPrefixed` fields: the label `proof runner token`, the ephemeral key's DER, and the runner key's DER. A token encrypted to one key never decrypts with another's.
3. AES-256-GCM encrypts the token with a random 12-byte nonce and no associated data. `Proof::EncryptedToken` holds the ephemeral key, the nonce, the ciphertext, and the 16-byte tag.

`decrypt` raises `Proof::TokenDecryptionError` for a token encrypted to another key and for any field changed, with one message for every cause, and `Proof::RunnerKeyError` for a public key alone. `Proof::EncryptedToken` refuses a tag that isn't 16 bytes when it is built, because Ruby's `openssl` checks as few bytes of a tag as it is given: a tag cut to 4 bytes decrypted in a measurement. A test decrypts a token encrypted by hand with the shared secret of RFC 5903's P-256 exchange, so the format can't change unnoticed.

They are in `lib/proof`, not the domain gem, because making a key and a nonce draws random numbers inside OpenSSL, and the domain never draws a random number itself. No port is needed, because the use cases that call them are in `lib/proof` too.

Options weighed:

- X25519 for the runner's key: Ruby's `openssl` has it, but the server's key is P-256, and with one curve Proof has one kind of key.
- A nonce of zeros, since each token has a separate key: it is safe, and a random nonce costs nothing and leaves no reader wondering.
- The two public keys as associated data instead of in the key derivation: either binds them, and HKDF's info is where RFC 5869 puts what a key is for.

#### The server's key and certificate

`Proof::Server::IdentityFiles` keeps the key as `key.pem`, which only the server's account can read, and a certificate for it as `certificate.pem`, in the server's folder. On the server's first start neither file is there, and it makes both. On every start after that it reads them. Every computer and runner that trusts the server knows it by its key, and nothing re-pins by itself, so the server never replaces a key:

- It makes a key only when neither file is there. It refuses a certificate whose key is missing, and the message says to put the key back, or to delete both files and have every computer and runner trust the server again.
- `Proof::Server::KeptFile` writes each file under a temporary name, syncs it to the disk, and then links it to its name. Making a link fails when the name is taken, where a rename replaces the file, so two servers that start at once can't each write a key, and a crash can't leave a key file with no key in it. A server whose link fails because the other server's file got there first reads that file and goes on, so both start with one key and one certificate. It makes the folder, and every folder above it that isn't there, readable by the account alone, as the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/) asks.
- `Proof::Server::IdentityReader` reads the text of each file, and refuses a key that isn't an EC P-256 private key in PEM, a certificate that isn't PEM, and a certificate of another key, each with the file's path and what to do. `Proof::Server::IdentityRefusal` holds those messages, as `Proof::PoolFileRefusal` holds the pool file's. The certificate is the only file the server makes again: when only the key is there, it makes a certificate for the key, and the fingerprint stays the same.

`Proof::Server::Identity` holds the key and a self-signed version 3 certificate for it: the server's identity, as Apple's Security framework calls a certificate with its private key. The certificate's subject is `CN=Proof server`, its serial number is 127 random bits with the top one set, and its extensions are those of a TLS server that is no certificate authority: `basicConstraints` `CA:FALSE`, `keyUsage` `digitalSignature`, and `extendedKeyUsage` `serverAuth`. Its validity has no end: its `notAfter` is 9999-12-31 23:59:59 UTC, which [RFC 5280, section 4.1.2.5](https://www.rfc-editor.org/rfc/rfc5280#section-4.1.2.5), gives a certificate with no well-defined expiration date. The command, the runners, and Git trust the pin, never the certificate's dates, so an end would only make OpenSSL refuse a key they trust. It holds no host name, because the server's address is whatever name the command and the runners reach it by. `fingerprint` gives the pin as `sha256//` and the Base64 of the SHA-256 of the public key's DER, the form `http.pinnedPubkey` takes, and a test compares it with the pin that the `openssl` command computes for the same key.

Options weighed:

- A new certificate for the key on every start: the pin would stay the same, but a client that keeps the certificate itself, as Git does with `http.sslCAInfo`, would refuse the next one.
- A certificate that ends after a year, as a public certificate authority's does: nothing trusts the dates, and the server would have to renew it for no gain.
- A key made again when its file is damaged or missing: every computer and runner would refuse the server, and nothing on the server would say why.
- Writing each file with a rename: a second server that starts at the same moment would replace the first one's key.

### Native calls

Native calls go through Fiddle on every system. Fledge's runtimes ship Fiddle as a bundled gem, and Fledge's tests call native code through it in built apps on macOS and Linux. No Proof code has yet called Win32 through it. `Kernel#syscall` can't do the job everywhere: it raises `NotImplementedError` on macOS (measured on Ruby 4.1.0-preview1), it doesn't exist on Windows, and its call numbers differ between x86-64 and ARM64 Linux.

Options weighed:

- `Kernel#syscall` on Linux with Fiddle elsewhere: two ways to do one thing.
- A helper program in another language for each native call: a second language, which [the decision for Ruby](decisions/0001-proof-is-ruby-shipped-as-a-fledge-app.md) rules out without a reason only it can meet.

### Ending a Linux run's processes and holding its memory

The Linux runner ends what a run started with a subreaper and a process group, and holds the run to its memory with a systemd scope:

- The runner makes itself the child subreaper by calling `prctl(PR_SET_CHILD_SUBREAPER, 1)` through Fiddle, with a plain, non-variadic signature, as [Native calls](#native-calls) says native calls go. An orphaned descendant is then reparented to the runner and stays a zombie, which `kill -0` still answers, until the runner reaps it with `Process.wait`.
- The runner starts the command with `Process.spawn(..., pgroup: true)` and ends the group with `Process.kill` on the negative group ID: `TERM`, then `CONT` for a stopped process, then `KILL`, as [the runner design](design/runner.md#a-runs-end) escalates.
- A process that leaves the group with `setsid` survives those signals. When its parent exits, it is an orphan and comes back to the runner, which holds it as a child to signal and reap.
- The runner starts the command in `systemd-run --user --scope -p MemoryMax=… -p MemorySwapMax=0`, with `MemoryMax` set to the run's memory request and `MemorySwapMax` set to zero.
- The runner reads a run's memory from `/proc/PID/smaps_rollup`, which has `Pss` and `SwapPss`, and which an account can read for its own processes, including those inside such a scope. The scope's `memory.current` and `memory.peak` are readable by the account too. Another account's processes aren't readable.

These were measured in disposable virtual machines running Debian 13 (kernel 6.12, systemd 257) and Ubuntu 24.04.5 (kernel 6.8, systemd 255), on x86-64, with Ruby 4.1.0-preview1 and Fiddle 1.1.8, as an ordinary account with no sudo, over SSH, with no desktop. The results were the same on both systems. ARM64 is unmeasured.

- With the subreaper call, an orphaned grandchild was reparented to the Ruby process and stayed a zombie until `Process.wait` reaped it. Without the call, the orphan went to PID 1 and `Process.wait` raised `ECHILD`.
- `Process.kill("-TERM", pgid)`, `"-CONT"`, and `"-KILL"` ended every process in the group, including a stopped one. A process that called `setsid` was in its own session and group, and survived all three.
- A Ruby process that allocated 400 MB in a scope with `MemoryMax=200M` was ended with `SIGKILL` within a second. The Ruby parent saw `termsig=9`, and the user journal said the scope failed with result `oom-kill`. On a host with 2 GB of swap, `MemoryMax=200M` alone didn't end it: the excess went to swap, and the process exited 0 after 1.5 to 20 seconds. With `MemorySwapMax=0` added, it was killed within 0.2 seconds.
- The limit worked over SSH with no desktop. With lingering off, it worked while a login session existed. With lingering off and no session, it failed to start ("Failed to connect to bus"). With lingering on and no session, it worked.

Options weighed:

- `Kernel#syscall` for the subreaper call: ruled out under [Native calls](#native-calls), because it doesn't exist on macOS or Windows and its call numbers differ between x86-64 and ARM64 Linux.
- A process group alone: a process that calls `setsid` escapes it, as measured.
- `MemoryMax` alone: swap defeats it on a host that has swap, as measured.

### Run IDs and codes

Crockford Base32 is written in the domain gem. The domain has no dependencies, and [the glossary](../glossary.md#run) says Proof reads a typed `o` as `0` and an `i` or `l` as `1`, so the decoder is part of the domain's rules.

Options weighed:

- A Base32 gem: adds a dependency to a gem that has none, for an alphabet and a mapping that fit in one value object.

### Where the server keeps its state

The server keeps what it makes in one folder, `~/.local/share/proof/server/`, in the home of the account it runs as, on Linux and on macOS, and reads the pool file from `~/.config/proof/pool.kdl`, where a person edits it. `Proof::Server::Paths` gives both paths under a home. The folder, and every folder above it that the server makes, can be opened by the account alone.

| Path in the folder | Holds |
| --- | --- |
| `key.pem` | The server's private key, which only the account can read |
| `certificate.pem` | The server's certificate for that key |
| `runs.db` | The store of runs, `Proof::Sqlite::Runs` |
| `repositories/` | One bare Git repository for each project |

The server's key, certificate, runs, and repositories are data a person would lose by losing the folder: every computer and runner that trusts the server knows it by its key, and the runs and repositories exist nowhere else. The [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/), which [clig.dev](https://clig.dev/#configuration) says to follow, puts "user-specific data files" in `$XDG_DATA_HOME`, by default `~/.local/share`. It keeps `$XDG_STATE_HOME`, by default `~/.local/state`, for state "that is not important or portable enough to the user that it should be stored in `$XDG_DATA_HOME`", such as logs, history, and recently used files, and `$XDG_CONFIG_HOME`, by default `~/.config`, for configuration, which the pool file is. [Caddy](https://caddyserver.com/docs/conventions), which makes its certificates and keys itself, as Proof's server does, keeps them in `~/.local/share/caddy` on Linux, in a folder its documentation says "must not be treated as a cache". The pool file's page gives `~/.config` on every system, and mise, which installs Proof's tools, keeps its data in `~/.local/share/mise` on macOS as on Linux, so Proof uses the XDG folders on macOS too. The server reads no `XDG_DATA_HOME` or `XDG_CONFIG_HOME`, as the pool file's page gives one path, so every path in Proof's pages is the path on disk.

Options weighed:

- `~/.local/state/proof`, where Syncthing keeps its keys and database from version 1.27: the specification keeps that folder for what isn't important enough for `~/.local/share`, and the key is what every computer and runner knows the server by.
- `~/.config/proof`, beside the pool file: the specification keeps that folder for configuration, and a tool that copies a person's configuration from computer to computer would copy the private key with it.
- `~/Library/Application Support/Proof` on macOS, as Caddy and Syncthing use: a second layout, where the pool file's page already gives `~/.config` on every system.
- `/var/lib/proof`: making it needs root, and the server runs as an ordinary account.
- `~/.proof`: a folder in the home beside the specification's folders, the habit the specification exists to replace.

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

#### The store of runs on SQLite

`Proof::Sqlite::Runs`, in `lib/proof/sqlite/`, is the store of runs in one SQLite file. Its path is the caller's, and a file that isn't there is made. `Proof::Sqlite::Facts` is the ROM relation over the table, `Proof::Sqlite::FactRows` turns a fact into a row and back, with `Proof::Sqlite::RowReader` reading it, `Proof::Sqlite::RunRows` does the same for a run's rows, `Proof::Sqlite::Writer` inserts them, `Proof::Sqlite::Refusals` holds the checks of a fact against a run and the error for a write that lost a race, and `Proof::Sqlite::Database` opens the file, runs the migration, and builds the ROM container. They load ROM, Sequel, and SQLite, so `Proof::Sqlite` loads each with `autoload`, the first time something names it, and `require "proof"` loads none of the gems. `test/proof_load_test.rb` runs that in a new Ruby process, and fails when requiring Proof loads any of the gems or the gems they load, or when building a store loads none.

- **The schema.** One table, `facts`, made by a ROM migration in `lib/proof/sqlite/migrations/`, which ROM runs when a store opens a file that hasn't had it. Each row is one fact of one run:

  | Column | Holds |
  | --- | --- |
  | `id` | An integer key that SQLite numbers, and nothing reads |
  | `run_id`, `version` | The run's ID as text, and the fact's place in the run's list, from 1 |
  | `kind` | The fact's class without `Proof::Run::`, such as `Placed` |
  | `at_seconds`, `at_nanoseconds` | The fact's time: whole seconds since 1970, and the nanoseconds past them |
  | `position` | A `Queued` fact's queue position |
  | `os`, `labels` | A `Queued` fact's operating systems and labels, each as JSON text: a list of names in sorted order |
  | `cpus`, `megabytes` | A `Queued` fact's resources |
  | `host`, `runner` | A `Placed` fact's host and runner |
  | `exit_status`, `signal` | A `CommandEnded` fact's status or signal, and the other empty |
  | `bytes` | An `OutputCompleted` fact's byte count |
  | `reason` | An `ArtifactsNotKept` fact's reason, as the text of its name |

  Every column of this table after `at_nanoseconds` is empty in a row whose fact has no such member. Three unique indexes make SQLite refuse a row. One on `(run_id, version)` refuses a second fact at one version of a run, and so a second run with one ID. One on `run_id` where `kind` is `Placed` refuses a second placement of a run, at any version. One on `position` where `kind` is `Queued` refuses a second run at one queue position.
- **How a fact is stored.** The time is two integers, so it comes back equal, in UTC, to the nanosecond, whatever the zone or the year: a `Time` has no exact form in a column that ROM reads back, and SQLite has no time type. The operating systems, the labels, and the resources are `Proof::OS`, `Proof::LabelSet`, and `Proof::Resources` in the domain, and a row rebuilds the same values from its text and integers. Every other member is a column of its own name. `FactRows::KINDS` finds every class of fact in `Proof::Run` by reflection, and a test fails when the domain gets a fact that has no sample in the tests, so a new fact can't go unstored without a failing test.
- **A read rebuilds the run.** `find`, `queued`, `holding_resources`, and `append` read every fact they need in order and build `Proof::Run` from them, as `Proof::InMemory::Runs` does. A row that is not a fact raises `Proof::InvalidFactError`, and a list that breaks a rule raises `Proof::InvalidRunError`. `queued`, `holding_resources`, and `next_position` read every run, so their cost grows with the number of facts stored.
- **A write adds a fact at the version read.** `append` reads the run outside any transaction, and refuses what the contract names: `Proof::UnknownRunError`, a second placement, a version the run doesn't have, a fact that breaks a rule. Then it inserts the row for version `read + 1`, in one transaction. SQLite refuses the row when another writer inserted a row at that version first, and ROM raises `ROM::SQL::UniqueConstraintError`. The store reads the run again and says what the winner stored: `Proof::RunAlreadyPlacedError` when the fact is a placement and the run is now placed, and `Proof::RunChangedError` otherwise. `add` inserts the run's rows in one transaction, and says which index refused it in the same way: `Proof::RunExistsError` when the run's ID is stored, and `Proof::QueuePositionTakenError` when it isn't. Reading the error's text would name the index, but the text is SQLite's, so the store reads the rows.
- **Which guard catches what.** Each write is one insert, so the promise that two writers can't both add a fact at one version rests on the unique indexes, and the errors the contract names and a version the run hasn't reached rest on the checks before the insert. Each guard was removed in turn, and the tests it fails were read:
  - Without the `(run_id, version)` index, three tests fail: the contract's refusal of a run whose ID is stored, the test of a fact added between a read and a write, and the schema test. The contract's two-thread placement test still passes, because the placement index refuses the second placement.
  - Without the placement index, only the schema test of two placements at different versions fails, because the version index refuses a second placement at the same version, which is all the two-thread test makes.
  - Without both indexes, six tests fail, the two-thread placement test among them. A test of a fact added between a read and a write checks each index through the error the store raises, with a second connection that writes after the store's read.
  - Without the `position` index, three tests fail, the two-thread test of runs at one queue position among them.
  - Without the version check, the contract tests of a version the run has not reached and of one it no longer has fail. Without the check for a placed run, the two contract tests of a second placement fail.
  - The pausing hook makes both threads read before either writes, so SQLite's indexes are what refuse the second.
- **Fibers and locks.** `Proof::Sqlite::Database` loads Sequel's `fiber_concurrency` extension when it opens a file, which makes a fiber, not a thread, the holder of a connection. It is a switch for the whole process, and opening a store turns it on. Without it, two fibers of one thread share a connection and a transaction, and a fiber sees another's write before it commits; a test shows that without a fiber scheduler. A connection waits for the file's lock with the `sqlite3` gem's `busy_handler_timeout=`, set to 5,000 milliseconds, which sleeps 1 millisecond in Ruby between tries and gives up after the time is up, so a thread or fiber that waits for the lock lets the others run, where the gem's `busy_timeout=` sleeps in C and holds every other thread. A write that waits longer than that raises `ROM::SQL::DatabaseError`, which the port doesn't name, so the server meets it as an error of its own. A test holds the write lock in one thread and counts the ticks of another while a third writes. The file is in write-ahead mode, which a connection sets when it opens, so a read doesn't wait for a write, and a file on a network share can't have it. Sequel's pool opens at most 4 connections, so a fifth thread or fiber waits for one.
- **Opening a new file from several processes.** `Proof::Sqlite::Database` runs the migrations inside a transaction that takes the file's write lock first. Without the lock, processes that opened a new file at the same moment each found it unmigrated: over 6 processes, some failed with `table facts already exists`, some with `index facts_one_fact_per_version already exists`, and one left two rows in Sequel's migrator table, which every later open then refused with `More than 1 row in migrator table`. With the lock the second process waits, then finds nothing to run. SQLite also refuses a connection that asks for write-ahead mode while another connection is changing the mode, without calling the busy handler, so a connection asks again every 5 milliseconds, up to 200 times. `test/sqlite_runs_processes_test.rb` opens one new file from 6 new processes at once, 3 times over, and fails when any of them fails. Threads can't show it, because Ruby's lock keeps them from overlapping in the setup.
- **Measured under a scheduler.** The gate's bundle has no fiber scheduler. In a bundle of its own, with Async 2.46.0 and the same gems, two fibers placing one run and two fibers adding runs at one queue position, 20 trials each, and 20 fibers for 10 trials, stored one placement and one run in every trial, with Sequel's `fiber_concurrency` and without it. The store is correct without it because a write is one insert and the indexes refuse the second; the extension is what keeps a fiber from reading another's uncommitted rows, which the server's unit of work will need when it wraps a read and a write in one transaction.
- **sqlite3 on each platform.** `sqlite3` 2.10.2 ships a precompiled gem for `arm64-darwin`, `aarch64-linux`, and `x86_64-linux`, in gnu and musl forms for the two Linux ones. Each requires Ruby below 4.1.dev and holds a build for Ruby 3.2 to 4.0, so none loads on Ruby 4.1.0-preview1, and Bundler installs the source gem, which compiles SQLite 3.54.1 from the tarball inside the gem with `mini_portile2` and needs a C compiler. `Gemfile.lock` keeps `aarch64-linux`, `arm64-darwin`, and `x86_64-linux` in its `PLATFORMS`, and locks the source gem.
- **How the store is divided.** `Runs` holds the methods of the port and nothing else. `FactRows` is the codec between a fact and a row, and the name both directions go by. RubyCritic rates a file A only while the complexity of its methods adds up to 50 or less, and the codec with both directions is above that, so the reading, with its own table of how each member that has no column of its own name is read, is in `RowReader`, and `FactRows.fact` hands a row to it. `RunRows` turns a run into rows and back. `Writer` inserts rows in one transaction and, when a unique index refuses them, reads what is stored, and `Refusals` chooses each error the store raises for a write: before an insert, and after an insert of a new run or of a fact that lost a race. `create_table` with its columns and indexes passes with the columns of one type in a loop, so the schema is one migration. The cops on the length and the complexity of a method and a class make the tests go to four files and two support modules, because one class of tests that long fails `Metrics/ClassLength`. A comment in `FactRows` says why one line there is ignored by Steep.

Options weighed:

- A JSON column for every fact's members: the queue position needs a column for its unique index, so a fact would have two ways of being stored, and a query couldn't use the other members as columns.
- Reading the run inside the write's transaction, with `BEGIN IMMEDIATE`: it is correct too, and it needs no mapping of a lost race to an error, because no writer can get in between the read and the insert. It makes every append take the file's write lock before it reads, where now only the insert takes it, and it leaves the indexes with no race to refuse, so the tests of a writer that got in between couldn't show that they hold.
- A table of runs next to the facts: the run's ID and queue position are already on its first fact, and a second table would have to agree with it.
- The choice of error for a lost race inside `Writer`, for a new run, beside `Refusals` for a fact: the errors of a write would be in two places.
- Time as ISO 8601 text: it reads in a SQLite shell, and it needs `Time.iso8601` and a format that keeps nine digits of the second, where two integers need neither.

### Use cases, validation, and composition

Use cases are plain Ruby objects. A refused rule raises a dedicated error class. The domain's constructors check inputs. The composition roots are plain Ruby that builds the objects and hands each its ports.

Options weighed:

- dry-operation: adds dry-monads and Zeitwerk, 63 ms to every start of the command, and its transaction support ties use cases to Sequel.
- dry-validation: loads dry-types into the domain through dry-schema.
- dry-system: takes 61 ms to boot an empty container, for three composition roots.

#### The server process

`Proof::Server.serve` is the entry point of the server's process, which the service that `proof server setup` makes will start. It builds `Proof::Server::Service` and returns its exit status. The service traps `INT` and `TERM`, and either stops the server, so a service manager stops it with `TERM` and a person at a terminal with Ctrl-C. It returns 0 once the server has stopped, and 1, after the reason on standard error, when the server can't start. It puts back the handlers the two signals had before when it returns, and it turns off Ruby's warnings of experimental features, because the fiber scheduler reads and writes through `IO::Buffer` and Ruby warns once that `IO::Buffer` is experimental. A signal handler can't take a lock, so `Proof::Server::Stop` is a pipe: the handler writes a byte to it without waiting, and the server waits for the byte in a fiber, which yields.

`Proof::Server::Root` is the server's composition root. It reads the pool file once, before it listens, so it knows the port: the pool file's `port`, or 7443, the page's default, when there is no version without a mistake. It then finds or makes the server's identity, listens on that port on every address of the computer, IPv4 and IPv6, with Ruby's `Socket.tcp_server_sockets`, and builds `Proof::Server::Https` with the table of requests. A change to the port takes effect when the server starts again, after `proof server setup` runs again, as the pool file's page says. `Proof::Server::Fibers` starts the fiber scheduler, serves the HTTPS in it, checks the pool file every second in a second fiber, with a `sleep` that yields, and stops both when the stop is asked for.

What the server writes to standard error, after `proof:`, beyond what it writes about the pool file:

| When | Line |
| --- | --- |
| It listens | `proof: listening on port PORT, with the fingerprint sha256//...` |
| It has stopped | `proof: stopped.` |
| Its key or certificate can't be used | `proof: PATH ...`, with what to do, as [The server's key and certificate](#the-servers-key-and-certificate) says |
| Its port is taken | `proof: the server can't listen on port PORT: REASON`, with the system's text for the error, such as `Address already in use` |
| A file it can't make | `proof: the server can't start: ` and Ruby's message |

Options weighed:

- Listening on `::` alone, which takes IPv4 too on Linux and macOS: on a computer with IPv6 turned off, the server couldn't listen at all. `Socket.tcp_server_sockets` makes one socket for each address family the computer has.
- Falcon's service, through async-service: it reads a Ruby file of configuration and forks worker processes, where the pool file is the server's configuration and one process holds the queue.
- Checking the pool file from a thread: every other wait in the server is a fiber's, and a thread would need a lock on the pool file in use.

### Documentation

The API documentation is RDoc in the `.rbs` files, written in Markdown. A `.rb` file has comments only inside method bodies, because RDoc takes a comment above a definition as its documentation, even with blank lines between. The gate checks both: `rake rdoc:coverage` for the `.rbs` files and `rake docs:placement` for the `.rb` files.

Documentation examples in Markdown pages and in `.rbs` comments run as tests, through a runner written for Proof. `rake docs:examples` runs them, one Ruby process for each file.

Options weighed:

- A tool that already runs examples from `.rbs` comments: no maintained tool reads `.rbs` files.
- minitest-markdown: silently passes a wrong `# =>` on the same line.
- The YARD tools: read only YARD's `@example` tags.

### Type checking

Steep checks four targets: `lib`, the domain gem, the usage gem, and the Rake tasks. Steep loads each target's signatures into every other target, so a signature that names a type from a library, such as `OptionParser` from `optparse`, needs that library in every target. A target that lacks it fails to build its types. Steep then checks none of that target's files, reports no error, and ends with "No type error detected". `steep check --validate=project` and `--validate=library` don't find it, because Steep validates a signature only in the target it belongs to.

The Steepfile therefore holds one list of libraries and loads it in every target, and `rake steep:loads` fails the gate when any target doesn't load. It loads each target's signatures as Steep does, and names each target that fails with its first diagnostic, so the fix is one line in the list.

Options weighed:

- `unreferenced!` on each target, so none loads another's signatures: the domain gem's and usage gem's signatures are also in `lib`'s list, and Steep gives a signature file to the first target that lists it, so `lib` would stop seeing them.
- A check of Steep's output for a target that reports nothing: Steep prints nothing for a target that fails to load and for one with no errors alike.

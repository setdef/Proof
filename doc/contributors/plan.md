# Plan for 1.0

What 1.0 builds, in what order, and what it leaves out. Delete each item here once it's done.

## Order of work

1. **Scaffold the repository** from `ruby_quality`, and merge its `AGENTS.md` into this repository's, so there is one ([#12](https://github.com/setdef/Proof/issues/12)).
2. **One Linux runner, end to end,** in virtual machines: server setup, runner setup, a run of a commit and of a working tree, streamed output, the exit status, cancel, and artifacts.
3. **Prove sensing a person** on each system, as [People at hosts](design/people-at-hosts.md#proven-before-its-built-on) lists, before anything depends on it ([#13](https://github.com/setdef/Proof/issues/13)).
4. **macOS,** then **Windows with WSL.**
5. **Move one real project at a time** onto Proof once it can carry that project's checks.

Each requirement in the design pages becomes an acceptance test as its part is built.

## Not in 1.0

Leave these out until a project asks for one, and then decide it as a design change:

- Windows as the server, or as the computer where `proof` runs
- runs that take a whole host, such as benchmarks
- runs on a person's real desktop, with real input
- priorities, and moving a run ahead in the queue
- placement or sizing from earlier runs' history
- a record of every process a run started
- Linux distributions beyond those the README lists
- isolation between runs beyond separate folders and accounts
- reporting results to a forge, such as GitHub commit statuses

## Undecided

Open questions are [issues](https://github.com/setdef/Proof/issues). Until one is decided, build what the docs say now.

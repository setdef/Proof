# Server design

What the server must guarantee, and the traps known so far. How to meet each requirement is the implementer's choice. The decision to place runs without an external scheduler is [ADR 0002](../decisions/0002-proof-places-runs-itself-with-no-external-scheduler.md); keeping the server to these few rules is part of that decision.

## Placement

- Count CPUs, memory, and disk per **host**, summing every runner on it. Two runners on one host must never be offered the host's resources twice.
- A run is placed only where its operating system, every label it needs, and its requested resources fit. Among the runs that fit now, the one that arrived first goes first, and a run that fits nowhere doesn't hold up the runs behind it. There are no priorities and no preemption.
- **A large request can wait indefinitely** behind runs that request less and keep taking the resources it needs, because nothing shares fairly. `proof status` is where that wait shows.
- A host keeps its memory share free always, and its CPU share free while a person is active: no new run is placed into either. A host with nobody active leaves its memory share unused, which is the cost of never having to take memory back.
- Refuse a run no host could ever take before anything is sent, and name the closest host. Keep a run queued when its operating system has no runner at the moment, since hosts come back.
- `proof status` must say what each queued run waits behind: which runs hold the host it needs, or that a person is active there, or that the host needs someone to sign in, or that no runner of its operating system is connected. A run that waits a long time without saying why looks hung.
- `proof status` must also say what a run a runner already has is doing: getting its code, waiting for a desktop or for a person to leave, running its command, or sending its output. A run that sits before its command starts looks hung the same way.

## The pool file

- **The pool file is KDL 2, and a file that isn't valid KDL 2 is refused.** The `kdl` gem (2.2.0) silently falls back to KDL 1 unless it is called with `version: 2`, and a reader that falls back accepts, and misreads, files Proof must refuse.

## Runs and their records

- Proof never runs a run's command again by itself: not after the command fails or times out, and not after the run is `lost`. The one retry is before the command starts, when the runner's workspace is broken ([runner design](runner.md#workspaces)), and no command has run then. A lost run's `proof` exits 75, and a lost run of a pushed commit shows as `lost` in `proof status`.
- **A run whose runner stays unreachable past a deadline becomes `lost`,** so an agent never waits forever on a dead host. A run may still be going on a host the server can't reach. Final states stay final, so a complete report that arrives after `lost` is refused. The host's resources stay held until the runner reports that the run's processes ended, or the runner is revoked, so a host is never offered more than it has while a lost run may still use it.
- A run's record holds its ID, task, commit, runner, state, exit status, resource use, and times. It never holds the command's arguments or environment, which can carry secrets and grow without bound.
- Records are bounded per run, kept for the pool file's `retention`, and written so that concurrent writers can't interleave or lose them.
- Times are recorded from the server's clock; clocks on hosts and where `proof` runs can differ.
- Run IDs are the UTC minute of creation and five random characters from Crockford's Base32. The server refuses a short form that matches more than one of the last 7 days of runs, and lists the matches.

## Output

- Keep each run's whole output as the runner sent it, up to the pool file's `limits output`. Past that, keep the first and last halves, with a line between them saying how much was left out.
- Stream it to every follower without letting a slow follower hold up the run or other followers. Send output in bounded pieces, so a burst of hundreds of megabytes can't break a deadline.
- **Following a run holds a connection open for as long as the run lasts.** A server that gives each open connection a separate thread stops answering new requests once followers hold every thread: with a cap of 4 threads, a thread-per-connection server (Puma 8.1.3) timed out its 5th request after 60 seconds (measured once). [ADR 0004](../decisions/0004-every-connection-goes-out-to-the-server-over-https.md) expects dozens of runs followed at once, so the server must keep answering with that many follows open.
- A follow must never silently drop or repeat output. Following picks up from a byte offset, so reattaching continues where it left off.

## Code

- One bare Git repository per project. `proof` pushes each run's commit under a temporary ref; runners fetch it.
- **A commit object being present doesn't mean the commit is complete.** A fetch cut off part way can leave the commit without its trees. A runner, or the server, counts a commit as present only when `git rev-list --objects --quiet SHA --not --all` succeeds, and deletes leftover temporary pack files before fetching again.
- Repack and prune each repository, and delete temporary refs of runs past their retention.
- For runs of pushed commits, the server fetches the listed branches with read-only credentials read from a file, and never passes those credentials to runners.

## Artifacts

- Each file arrives with its SHA-256 and byte count, is written to a temporary name, and is kept only if both match. The run's artifacts are sealed by a sorted manifest once all have arrived; nothing is added after that.
- **A run whose command exited 0 but whose artifacts couldn't be kept is `failed`, never `succeeded`.** A pass is reported only for work Proof finished.
- Refuse file paths that are absolute or contain `..`, and check names that differ only in case, which collide on Windows and macOS.
- Enforce `limits artifacts` per run, and keep free space on the server's disk: a run whose artifacts would fill it fails, rather than the server.
- When a run starts, check `limits artifacts` and the server's free space. Reserve no space: reserving it would make the server account for space across runs, for little gain. Two runs that each fit can together fill the disk, and the second then fails when its artifacts arrive, as the previous requirement allows.

## Tokens and codes

- Tokens are issued to one person, agent, or runner each, stored by Proof in files only their owner can read, and never accepted from a command-line argument or an environment variable.
- One-time codes (approval and sign-in) are 8 characters of Crockford's Base32, grouped 4-4, valid once for 15 minutes, and void after 5 wrong attempts. Input is accepted in either case, with or without the hyphen, with `O` read as `0` and `I` or `L` as `1`.
- The server makes its certificate itself. Its fingerprint travels inside the codes, so the command and runners pin it on first contact.

## Versions

- The server, every runner, and the command run one version. A runner that finds the server at a newer version upgrades between runs, from builds the server holds for each platform.
- The command checks the server's version on each call. When they differ in a way that matters, it says which one to upgrade, before sending anything.
- Nothing about a version is pinned in the source code: a new pool works from its first install.

# Upgrade the pool

Upgrade every part of a pool to a new version of Proof. You upgrade the server; the runners follow it; and you upgrade the `proof` command where you work.

This page runs commands on two computers:

| Prompt | Where, and as whom |
| --- | --- |
| `proof@server $` | The account Proof runs as, on the server's computer |
| `you@laptop $` | Your account, on the computer you work on |

## Upgrade the server

On the server's computer, as the account Proof runs as, see what the upgrade would install:

```console
proof@server $ proof server upgrade --dry-run
proof: would upgrade the server from 1.0.0 to 1.1.0
proof: would download builds of 1.1.0 for Linux (x86-64, ARM64), Windows, and macOS, for the runners
proof: nothing changed, because of --dry-run
```

Then upgrade:

```console
proof@server $ proof server upgrade
proof: downloaded Proof 1.1.0 for every platform, and checked each against SHA256SUMS
proof: restarted the server at 1.1.0
proof: runners will upgrade between runs
```

The server keeps queued runs across the restart. Runs going on at the time continue, and their output reaches the server once it's back.

## The runners follow

Each runner checks the server's version when it connects. When the server is newer, the runner finishes the run it has, downloads its platform's build from the server, and restarts with it. `proof runner list` shows each runner's version:

```console
you@laptop $ proof runner list
nuc-linux    1.1.0  linux  x86-64  gpu kvm desktop podman
pc-windows   1.1.0  windows x86-64  gpu desktop
pc-wsl       1.1.0  linux  x86-64  desktop
mac-macos    1.0.0  macos  arm64   gpu xcode  (upgrading after run p9x2k)
```

A runner whose host is asleep upgrades when it next connects. Runners need nothing from the internet: they download from the server.

## Upgrade the command where you work

Download the archive of the server's version for your computer from [the releases page](https://github.com/setdef/Proof/releases), check it against `SHA256SUMS`, and replace the old one. Until you do, `proof` says the server is at a newer version, and which commands that affects, before it sends anything.

If you installed [the Agent Skill](coding-agents.md), install it again, so it matches the version you run:

```console
you@laptop $ proof skill install
```

## What changes between versions

The [changelog](../../CHANGELOG.md) lists every change, and says which ones need anything from you, such as a new setting in the pool file. Fields in a run's result line and its `--json` output are only ever added, never renamed or removed, so scripts that read them keep working.

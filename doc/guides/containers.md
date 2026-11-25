<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Run containers in a run

Use containers in a task, for a database or another service its tests need, on a Linux runner. Proof runs containers with rootless [Podman](https://podman.io/): no Docker daemon, and no root, so a container can't change the host it runs on.

This page runs commands on one host, as two accounts:

| Prompt | Where, and as whom |
| --- | --- |
| `you@nuc $` | Your account, on the Linux host |
| `proof@nuc $` | The account Proof runs as, on the Linux host |

## Let the runner use Podman

Rootless Podman needs a range of subordinate user and group IDs for the runner's account, and on Ubuntu 24.04 and later, AppArmor must let it create user namespaces. Run setup again as `proof`, and it prints what's missing:

```console
proof@nuc $ proof runner setup server.home.arpa
proof: checking nuc for a Linux runner
proof: podman is installed, but the account proof has no subordinate IDs
proof: an administrator must run these commands, then run `proof runner setup server.home.arpa` again:
proof:   sudo usermod --add-subuids 200000-265535 --add-subgids 200000-265535 proof
```

Run the commands it prints as yourself, then setup again as `proof`. When rootless Podman works, the runner offers the `podman` label.

## Ask for it in a task

A task that needs containers asks for the label, so it only goes to runners that offer it:

```kdl
task "test:integration" {
  os linux
  label podman
}
```

The task's command uses `podman` as you would anywhere. For example, a setup step that starts PostgreSQL for the tests:

```console
$ podman run --detach --rm --name invoices-db --publish 127.0.0.1:5432:5432 --env POSTGRES_PASSWORD=test postgres:17
```

Publish ports on `127.0.0.1` only, as here, so nothing outside the host reaches the service.

## What happens to containers and images

- Each workspace has separate Podman storage, in the workspace's home folder, so images stay between the project's runs there and count against the host's budget.
- Every container a run starts is stopped and removed when the run ends, whether the task stops it or not.
- Two runs at once on one host can't see each other's containers: each workspace's storage is separate.
- Files a container writes into a mounted folder are owned by the account's subordinate IDs, not to `proof`. The runner deletes them when it empties the workspace; a workspace it can't empty is never reused.

## What this doesn't do

Docker isn't supported, because its daemon runs as root and anyone who can reach it can act as root on the host. Containers are available on Linux runners only. A container's memory is counted against the run, and the run's memory request has to cover it.

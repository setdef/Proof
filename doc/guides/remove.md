<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Remove a runner or the server

Take a host out of the pool, uninstall Proof from a computer, and delete what it kept. Removing a runner takes two steps: revoke it, so the server no longer trusts it, then uninstall it on its host.

This page runs commands on several computers:

| Prompt | Where, and as whom |
| --- | --- |
| `you@laptop $` | Your account, on the computer you work on |
| `proof@nuc $` | The account Proof runs as, on the host being removed |
| `you@nuc $` | Your account, on that host |
| `proof@server $` | The account Proof runs as, on the server's computer |

## Revoke a runner

Where you work, find the runner's name, then revoke it:

```console
you@laptop $ proof runner list
you@laptop $ proof runner revoke nuc-linux
proof: revoke nuc-linux? Its token stops working, and its runs going on are canceled. [y/N] y
proof: revoked nuc-linux
proof: removed host nuc from the pool file, since it has no other runner
```

A revoked runner can't connect again, even if its host comes back. To use the host again later, set it up again, and approve it with its new code.

## Uninstall the runner

On the host, as the account Proof runs as:

```console
proof@nuc $ proof runner uninstall
proof: uninstall the runner nuc-linux? This deletes its workspaces and caches. [y/N] y
proof: stopped the runner, and deleted its service, workspaces, caches, and mise
```

On a Mac, `proof runner uninstall` first prints the commands for an administrator to run to stop and remove the launchd daemon, and deletes the rest when you run it again. `proof server uninstall` does the same for the server.

Then, as yourself, delete Proof's account, with its home folder and the unpacked archive in it:

```console
you@nuc $ sudo loginctl disable-linger proof
you@nuc $ sudo userdel --remove proof
```

On a Mac, use `sudo sysadminctl -deleteUser proof`; on Windows, `net user proof /delete` as an administrator, after signing the account out.

## Uninstall the server

Uninstalling the server deletes the whole pool's records, output, and artifacts, and every runner stops working. On the server's computer:

```console
proof@server $ proof server uninstall
proof: uninstall the server? This deletes every run's record, output, and artifacts, and every runner's token stops working. Type the server's address to confirm: server.home.arpa
proof: stopped the server, and deleted its service, its data, and the pool file
```

Then uninstall each runner as in the previous section, and delete the server's account the same way.

## Uninstall Proof where you work

Sign out, which deletes the token Proof kept, then delete the unpacked archive and Proof's configuration:

```console
you@laptop $ proof logout
you@laptop $ rm -r ~/.config/proof ~/.local/state/proof
```

Remove the pre-push hook from any clone that has one, with `proof hook uninstall` in that clone.

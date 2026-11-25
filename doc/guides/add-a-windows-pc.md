<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Add a Windows PC

Set up a runner on a Windows PC, and a second one in its WSL (the Windows Subsystem for Linux), so tasks that need Windows run there, and Linux tasks can use the PC too. Proof counts the two runners as one host, so together they never get more work than the PC can do.

This page runs commands on two computers, as two accounts:

| Prompt | Where, and as whom |
| --- | --- |
| `PS C:\Users\you>` | Your account, in PowerShell, on the PC |
| `PS C:\Users\proof>` | The account Proof runs as, in PowerShell, on the PC |
| `you@laptop $` | Your account, on the computer you work on |

You need a pool with a server, from [Getting started](../getting-started.md), an administrator on the PC, and WSL installed with a supported Linux (Debian 13, Ubuntu 24.04, or Fedora 40 or later) if you want the second runner.

## Create an account for Proof

As an administrator, create a standard account for Proof:

```console
PS C:\Users\you> net user proof * /add
```

`net user` asks for the account's password. Then sign in to Windows as `proof` once, with Fast User Switching (Start, your picture, Switch user), and switch back to your account. The `proof` account stays signed in, and its runner works while it is.

## Install Proof and set up the runners

Switch to the `proof` account, download the Windows archive from [the releases page](https://github.com/setdef/Proof/releases), check it against `SHA256SUMS`, unpack it, and put `proof.exe` on the account's `PATH`. Then, in PowerShell:

```console
PS C:\Users\proof> proof runner setup server.home.arpa
proof: checking pc for a Windows runner
proof: found WSL with Debian 13
proof: installed mise for both runners
proof: started the runner pc-windows, to run while this account is signed in
proof: started the runner pc-wsl in WSL
proof: pc-windows and pc-wsl ask to join server.home.arpa as code J4RN-8VXT
proof: approve them from where you work with `proof runner approve J4RN-8VXT`
```

Setup starts the Windows runner in the account's session at sign-in, because only that session has a display and the PC's GPU. It keeps WSL running for the Linux runner. To set up the Windows runner alone, pass `--no-wsl`.

Approve both where you work:

```console
you@laptop $ proof runner approve J4RN-8VXT
proof: approved pc-windows and pc-wsl, as one host, pc
proof: added host pc to the pool file, with a budget of 210GB, half its free disk space
you@laptop $ proof verify
```

## When someone uses the PC

A PC has one display and one console session at a time. When a person signs in to their account and uses it, the `proof` account's session loses the display. While that lasts:

- runs that need the `desktop` label, or the PC's GPU, wait;
- other Windows runs and every WSL run go on, with the share the pool file keeps free for the person;
- runs that were using the display when the person arrived are stopped and queued again, since Windows gives the display to one session only.

When the person switches back to the `proof` account, or signs out, the waiting runs start. [Share a host with the person who uses it](sharing.md) says how to set what's kept free.

## What each run gets on Windows

Each run gets a private desktop: its windows draw there, with OpenGL and Vulkan on the PC's GPU, and never take the focus of the person's desktop. A test can't send simulated input with `SendInput`, read or move the mouse cursor, bring a window to the front with `SetForegroundWindow`, or take a screenshot of the desktop; it can post messages to the windows it made and read back what it drew.

> [!WARNING]
> A program that listens on any address other than `127.0.0.1` makes Windows ask whether to allow it, on the person's screen. If nobody answers, Windows adds a firewall rule that blocks it, which only an administrator can remove. Make test servers listen on `127.0.0.1`.

Everything a run starts ends with it, including programs that ignore being asked to stop. Settings under `%APPDATA%` and `%LOCALAPPDATA%` are shared by every run of the `proof` account, whatever the run's home folder.


# Add a Mac

Set up a runner on a Mac with Apple silicon, so tasks that need macOS run there. A Mac runner starts when the Mac starts, with nobody signed in, and runs work that needs no window, such as builds, unit tests, and iOS Simulator tests, from the moment setup ends. To also run tasks that open windows, the runner's account needs a signed-in session, which this guide sets up at the end.

This page runs commands on two computers, as two accounts:

| Prompt | Where, and as whom |
| --- | --- |
| `you@mac %` | Your account, on the Mac |
| `proof@mac %` | The account Proof runs as, on the Mac |
| `you@laptop $` | Your account, on the computer you work on |

You need a pool with a server, from [Getting started](../getting-started.md), and someone who can use `sudo` on the Mac.

## Create an account for Proof

The runner runs as a separate account, so a run's command can't read the files of anyone who uses the Mac. Create it as a standard account, not an administrator, then switch to it:

```console
you@mac % sudo sysadminctl -addUser proof -fullName "Proof" -password -
you@mac % sudo -iu proof
proof@mac %
```

`sysadminctl` asks for the account's password. Keep it: you need it to sign the account in, if you set up a runner that can open windows.

## Install Proof and set up the runner

As `proof`, download the macOS archive from [the releases page](https://github.com/setdef/Proof/releases), check it against `SHA256SUMS`, unpack it, and put `proof` on the account's `PATH`. Then run setup.

The runner has to start when the Mac starts, so it runs as a launchd daemon, and installing a daemon needs an administrator. The first time you run setup, it stops before it changes anything, prints the commands for an administrator to run, and asks you to run setup again. Nothing went wrong: setup never runs anything as root itself. Do this:

1. Run setup as `proof`. It prints the commands and stops.
2. Leave the `proof` shell.
3. Run the commands it printed as `you`, with `sudo`.
4. Switch back to `proof` with `sudo -iu proof`.
5. Run the same setup command again:

```console
proof@mac % proof runner setup server.home.arpa
proof: checking mac for a macOS runner
proof: checked: the runner's launchd daemon is installed
proof: installed mise for the runner
proof: started the runner mac-macos as a launchd daemon that runs as this account
proof: mac-macos asks to join server.home.arpa as code 7WQK-M2HD
proof: approve it from where you work with `proof runner approve 7WQK-M2HD`
```

Approve it where you work, and check it:

```console
you@laptop $ proof runner approve 7WQK-M2HD
proof: approved mac-macos
proof: added host mac to the pool file, with a budget of 180GB, half its free disk space
you@laptop $ proof verify
proof: mac-macos passed (3s)
proof: nuc-linux passed (4s)
proof: exit=0 runners=2 passed=2 failed=0
```

## Let runs open windows

A launchd daemon has no window server: a run there can draw offscreen, but a window it opens never appears, and macOS XCTest can't start. For tasks with the `desktop` label, the runner has to run that work in a signed-in session of its account.

1. On the Mac, turn on Fast User Switching in System Settings, so the `proof` account can stay signed in while someone else uses the Mac.
2. Sign in as `proof` once, then switch back to your account. The `proof` account stays signed in in the background.
3. As `proof`, run setup again with `--desktop`:

   ```console
   proof@mac % proof runner setup server.home.arpa --desktop
   proof: mac-macos runs work that opens windows in this account's session
   proof: mac-macos now offers the label desktop
   ```

While the `proof` account has no signed-in session, runs that need a window wait in the queue, and `proof status` says the host needs signing in. Runs that need no window go on.

A session that isn't on the screen opens windows and runs them, but macOS presents none of their frames to a display. Tests that read back what they drew work there; benchmarks of frames reaching the screen don't.

> [!WARNING]
> With FileVault on, nothing of Proof's starts after a restart until someone unlocks the disk at the unlock screen, and macOS doesn't sign anyone in. Until the disk is unlocked, the runner isn't connected, and runs that need a Mac wait in the queue. After that, runs that open windows wait until someone signs in as `proof`, and `proof status` says the host needs signing in.

> [!WARNING]
> Don't turn FileVault on over SSH: `fdesetup enable` waits for a consent dialog at the Mac's screen.

## What you've set up

`proof status` lists `mac-macos` with the labels it found, such as `gpu` and, if Xcode is installed, `xcode`. The Mac runs its work at the utility quality-of-service class, and keeps a share free for a person using it, as [Share a host with the person who uses it](sharing.md) describes.

To keep tasks that don't work on macOS off this host, list where they work in the project file: [Run a task on several operating systems](several-operating-systems.md).

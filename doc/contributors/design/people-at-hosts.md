# People at hosts

What a runner must do when a person uses its host, what is known about sensing that, and what must be proven before anything is built on it. How to meet each requirement is the implementer's choice.

## Requirements

- **A person comes first, whoever they are.** Not only one owner: anyone at the host's keyboard, mouse, trackpad, or screen.
- **Being active is a state, not a setting.** A person is active while their last input is more recent than the host's `active-for`. When they stop, runs get the whole host back.
- **Runs go on, with less.** While a person is active, the host keeps its share of CPUs and memory free for them, runs already going drop to the lowest priority, and runs that need the person's display, GPU, or speakers wait. No run is stopped because a person arrived.
- **Memory can't be taken back.** CPU can be taken back by priority; memory a run already holds can't. Placement must leave the share free before a person arrives, which is why the share is kept whenever a person is active and new runs never use it.
- **Input from runs never counts as a person.** A run that drives a window or posts input must not keep the host looking busy.
- **Fail toward the person.** When the runner can't tell whether someone is there, it treats them as present.
- **Every test hook that can make a host step aside must expire by itself.** A file that pretends a person is present, left behind by a failed check, stops a host until someone notices.

## What is known about sensing a person

From a check of primary sources and tests on 2026-11-24:

| System | Mechanism | What is known |
| --- | --- | --- |
| Linux | systemd-logind's `IdleHint` and `IdleSinceHint` for each session, over the system bus | Another user's session was readable with no privilege and no prompt (tested on Debian 13). Only graphical sessions set the hint; a text session's idleness comes from its terminal's access time. |
| Linux | The X11 screen-saver extension, GNOME's `org.gnome.Mutter.IdleMonitor` | Need access to the person's display or session bus; not reachable from another account by default (untested). |
| Windows | `GetLastInputInfo` | Only for the session that calls it, per Microsoft's documentation, so a runner in a separate session can't use it for the person's. |
| Windows | `WTSQuerySessionInformation` with `WTSSessionInfo`, field `LastInputTime` | Gives another session's last input time. Needs the Query Information permission on that session; whether a standard account has it on a client edition of Windows is unverified. |
| macOS | IOKit's `HIDIdleTime` (`ioreg -c IOHIDSystem`) | One value for the whole system, readable by an ordinary account (tested as one user). Whether it counts events a program posts, and whether it reads correctly from another account's session, is untested. |
| macOS | `CGEventSourceSecondsSinceLastEventType` | Its combined-session state covers the calling session only, per the SDK header. Its readings disagreed with `HIDIdleTime` in a test. |

On Linux and Windows, runs draw on displays and desktops apart from the person's, which the runner leaves out of its measurement. On macOS, no way to exclude a run's posted input is known.

## Proven before it's built on

Sensing a person from the runner's account is the least proven part of the design. Before the runner depends on it, prove on each system, as a separate unprivileged account, with a person really at the host:

1. **Windows:** read the console session's last input time from the runner's session, as a standard account.
2. **macOS:** read idle time from another account's session, and find whether a run's posted input resets it.
3. **Linux:** read a graphical session's idle hint from another account, on GNOME and on KDE.

If a system can't do it unprivileged, the fallback is a helper program started in the person's session that reports only their idle time to the runner.

## Windows: who holds the console

On Windows, the runner also needs to know whether the person holds the console session, because a run that needs the display can't have it while they do. A watcher in the runner's session can see the console change hands within seconds. Runs that need the display then wait; runs already using it are stopped and queued again, since Windows gives no way to hand the display back.

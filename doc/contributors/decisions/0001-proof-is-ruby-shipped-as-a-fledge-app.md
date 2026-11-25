---
status: proposed
date: 2026-11-24
deciders: not recorded
---

# Proof is written in Ruby and shipped as a self-contained Fledge app

## Context and Problem Statement

Proof is one program in three roles: the command people and agents type, the server, and the runner on each host. It must behave the same on Linux, Windows, and macOS, and the runner must not depend on anything a project installs, because a project's setup could change or break it. People who use Proof should not have to install a language runtime to run it. What should Proof be written in, and how should it reach each computer?

## Decision Drivers

* One program, with the same behavior and messages, on Linux, Windows, and macOS
* Nothing for a person to install first: no runtime, no package manager
* A runner that nothing a project installs can break
* The project's maintainers write Ruby

## Considered Options

1. Ruby, packaged per platform with [Fledge](https://github.com/setdef/Fledge) as a self-contained app
2. A second language that compiles to one executable, such as Go
3. Ruby installed on each host, with Proof as a gem
4. A shell script per operating system: bash on Linux and macOS, PowerShell on Windows

## Decision Outcome

Chosen: option 1, because it keeps the whole project in the language its maintainers write, while each archive carries the Ruby it runs on. Option 2 lost because it adds a second language to maintain beside the Ruby the project already has. Option 3 lost because a Ruby on the host is one more thing a project's setup can change or break, and one more thing for a person to install and pin. Option 4 lost because the same behavior has to be written several times, and the tools those scripts lean on (file locks, process groups, timeouts) differ between operating systems.

A helper in another language is allowed only for something Ruby can't do on a platform, such as a Windows launcher that creates a desktop per run.

Confidence: Fledge builds self-contained apps for Linux, Windows, and macOS, per its README. Nothing yet shows that Proof's native calls (process groups, job objects, input idle time) work through Fledge's Ruby, which has no Fiddle. No recorded comparison shows option 1 beats option 2 on anything but the maintainers' language.

### Consequences

* Good, because people download one archive per computer and run it, with nothing else installed.
* Good, because the command, the server, and the runner share one codebase and one version.
* Bad, because Fledge builds only for the platform it runs on, so every release needs a build machine for each platform: Linux on x86-64 and ARM64, Windows, and macOS on Apple silicon.
* Bad, because Fledge's Linux builds need glibc 2.39 or later, which limits the Linux distributions Proof supports.
* Bad, because Fledge's Ruby is a preview release, so Proof inherits its bugs until a stable one ships.
* Bad, because without Fiddle, native calls go through `Kernel#syscall` or a helper program, which the maintainers have to write and test on each platform.

### Confirmation

Nothing automated checks it yet. The release build will fail if any part of Proof needs a runtime outside its archive.

## More Information

The supported platforms are listed in the README's Compatibility section. Revisit this decision if a platform Proof must support has no Fledge build.

# Platform design

What each operating system needs from a runner, and its traps. Where an item has been tested or comes from documentation, it says so. How to meet each requirement is the implementer's choice.

## Linux

- **Supported:** Debian 13, Ubuntu 24.04, Fedora 40 and later, on x86-64 and ARM64. The floor is glibc 2.39, set by Fledge's Linux builds.
- **Services without login:** the runner is a systemd user service, so the account needs lingering (`loginctl enable-linger`), which only an administrator can turn on. In WSL without systemd, the Windows runner keeps WSL alive instead.
- **Hardware through groups:** `/dev/kvm` through `kvm`, and GPU render nodes through `render`. A service keeps the groups it started with, so it has to restart after a group change. On ARM64, CPU flags don't show KVM support; test `/dev/kvm` itself.
- **Displays:** a run that needs one gets a separate Xvfb with a window manager, on a display number from a range people don't use (for example, from `:300` up). Without a window manager, a window that opens over another takes its input, and full-screen requests fail. An ordinary account can run both (tested on Debian 13; packages `xvfb` and `openbox` there). Allocate the display number in the runner; checking for free lock files from the run's shell races.
- **Vulkan can't present to an Xvfb window,** because Xvfb has no DRI3. Programs that prefer Vulkan fail to find a GPU, or show an error dialog nobody can answer and hang. Hiding the Vulkan ICD folders from such a run (for example, bind-mounting an empty folder over `/usr/share/vulkan/icd.d` and `/etc/vulkan/icd.d` with `bwrap`) makes them fall back to OpenGL.
- **Software rendering differs between Mesa versions:** Mesa 25's llvmpipe linear rasterizer reads wrong uniform array elements (`LP_PERF=no_rast_linear` avoids it). Output a project compares pixel by pixel depends on the host's Mesa.
- **Sound:** a run with the `sound` label gets a separate virtual audio device: a null sink in a separate PipeWire or PulseAudio instance, which the run can play into and record from, and nobody hears.
- **Containers:** rootless Podman, with its storage in the workspace's home, so a workspace's images count against the budget and go with it. Ubuntu 24.04's AppArmor restricts unprivileged user namespaces for unconfined programs; setup must check for this and print the administrator step. Subordinate ID ranges may be missing for the account.

## Windows

- **A real display and GPU need the console session.** A service in session 0, or a session reached over SSH, gets no display and usually not the discrete GPU. The runner starts in the account's interactive session, at logon, so the host works only while the account is signed in.
- **Session 0 can't control session 1:** a command over SSH can't stop the runner in the console session. Control the runner through files or a task scheduled in that session.
- **A private desktop per run** (`CreateDesktop`, with the process started on it through `STARTUPINFO.lpDesktop`, never `SwitchDesktop`). On it, windows, OpenGL on the vendor's driver, and Vulkan surfaces work. `SendInput`, cursor position, `SetForegroundWindow`, raw input, and GDI or DWM screenshots don't. Clipboard and atoms are shared through the window station. Moving a thread to the desktop with `SetThreadDesktop` breaks OpenGL; start the process on it instead.
- **A job object per run,** with `KILL_ON_JOB_CLOSE`, ends every process a run started, including native programs that no POSIX signal reaches. A memory limit on the job is documented; untested.
- **Firewall:** a program that listens on any address other than `127.0.0.1` makes Windows prompt on the desktop, and when nobody answers, Windows adds a Block rule only an administrator can remove. Tests must bind `127.0.0.1`.
- **Shared per-account state:** `APPDATA`, `LOCALAPPDATA`, and `USERPROFILE` stay the account's whatever `HOME` says. Environment variables are limited to 32,767 characters. Non-administrator symbolic links work in the console session but not over SSH.
- **WSL:** the Linux runner in WSL and the Windows runner are one host. WSL has no GPU (OpenGL falls back to llvmpipe), and its processes run at normal priority whatever the Windows side's priority is. A Linux process outlives its `wsl.exe` until it next writes to it.
- **Gems with C extensions need a compiler toolchain.** A project whose gems have C extensions and no precompiled Windows gem can't install them on a Windows host without MSYS2 at `C:\msys64`, with its `base-devel` group and the `mingw-w64-ucrt-x86_64-toolchain` package. Without them, `bundle install` fails (measured in three runs on an x64 Windows host, as an administrator).
- **A GPU that drives a person's display:** work on it can disturb what the person sees, and from a disconnected session Windows may pick an integrated GPU the person's display depends on. A runner must never use a GPU that drives a person's display unless the pool file allows it.

## macOS

- **Supported:** Apple silicon only.
- **A runner starts when the Mac starts, with nobody signed in.** A launchd agent of an ordinary account doesn't start after a restart until that account signs in. A launchd daemon that runs as the runner's account (`UserName`) starts at boot with no one signed in (tested in a virtual machine running macOS 27.2.1, with FileVault off). Installing a daemon needs an administrator, so setup stops before it changes anything, prints the commands for an administrator to run, and asks to be run again, as it does on Linux for `loginctl enable-linger`.
- **The server on macOS** starts when the Mac starts, with nobody signed in, in the same way, and is set up by `proof server setup`. It never runs through a crontab: a crontab written over SSH waits on a consent dialog nobody sees, so the server never starts.
- **No window server for a daemon:** a launchd daemon can make a window but never show it, and macOS XCTest fails there (`testmanagerd` unreachable). Offscreen Metal and OpenGL work, and the iOS Simulator boots and runs XCTest. Work that opens windows has to run in a signed-in session of the runner's account. While there is none, runs that need a window wait, and `proof status` says the host needs signing in.
- **A signed-in session that isn't on the screen presents no frames:** windows open and look active to the program, but nothing is drawn to a display. Benchmarks of presented frames need the session on the screen.
- **With FileVault on, nothing starts after a restart until someone unlocks the disk at the unlock screen,** neither a daemon nor the server (tested in a virtual machine running macOS 27.2.1). Until then the runner is not connected. FileVault also turns off automatic login, so someone must sign the runner's account in after every restart before work that opens windows can run. `proof status` must say a host needs signing in, not that it's busy.
- **`fdesetup enable` over SSH waits on a consent dialog at the console.** No step of Proof may turn FileVault on over SSH, because it waits for someone at the console.
- **Simulator devices are kept per account,** in `~/Library/Developer/CoreSimulator/Devices` whatever `HOME` says, and a booted device outlives the run that booted it. At a run's end, shut down devices booted before every other running run began; never shut down a device another running run may be using.
- **A bare `PATH`:** a login shell runs `path_helper`, which adds `/usr/local/bin` and `/opt/homebrew/bin` from the person's installs. Start runs with the system's folders only, then the tools mise provides.
- **No memory limit** an ordinary account can set (tested). Hold runs to their requests by ending them when the host runs short.
- **Local Network privacy** can stop a daemon from reaching the server on the local network, with no entry to allow in System Settings. Setup must check that the runner reaches the server.
- **Utility QoS:** run the runner at the utility quality-of-service class (`taskpolicy -c utility`), which its children inherit, so a person's typing and scrolling stay smooth while runs keep the processors busy.
- **Sound:** CoreAudio plays a run's sound on the host's default output, and an ordinary account can't change it. A run with the `sound` label waits while a person is active; one without it can still make noise, which Proof can't prevent.

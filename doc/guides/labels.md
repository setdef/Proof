# Give runs a GPU, KVM, or a desktop

Some tasks need more than an operating system: a GPU, KVM for an Android emulator, or a desktop where windows can open. Each runner checks its host and offers a **label** for each of these it finds. A task asks for labels, and the server places its runs only on runners that offer all of them.

## The labels runners offer

| Label | A runner offers it when | What a run gets |
| --- | --- | --- |
| `gpu` | Linux: the account can open a GPU's render node, through the `render` group. Windows: the runner's session has the PC's discrete GPU. macOS: always. | Hardware graphics and compute through the system's drivers |
| `kvm` | Linux: the account can open `/dev/kvm`, through the `kvm` group | Hardware virtualization, for Android emulators and virtual machines |
| `desktop` | Linux: Xvfb and a window manager are installed. Windows: always. macOS: the runner runs in a signed-in session ([Add a Mac](add-a-mac.md#let-runs-open-windows)). | A place to open windows: a virtual display on Linux, a private desktop on Windows, the runner's session on macOS |
| `sound` | Linux: PipeWire or PulseAudio is installed. Windows and macOS: always. | Somewhere to play sound: a separate virtual audio device on Linux, which the run can also record from; the host's speakers on Windows and macOS, only while no person is active there |
| `podman` | Linux: rootless Podman works for the account | Containers, as [Run containers in a run](containers.md) describes |
| `xcode` | macOS: Xcode is installed | Xcode's tools and the iOS Simulator |

`proof runner list` shows each runner's labels. A runner checks again each time it starts, so a label appears after you add what it needs and restart the runner.

## Ask for a label

In the project file:

```kdl
task "test:gpu" {
  label gpu
}
```

Or for one run, on the command line:

```console
$ proof run test --label gpu
```

A run that needs a label no runner offers waits in the queue, and `proof status` says which label it's waiting for.

## Give a Linux runner a label it's missing

Setup on Linux checks for the groups and packages each label needs, and prints the administrator commands for the ones that are missing, without running them. For example, for KVM:

```console
$ sudo usermod -aG kvm proof
```

A service keeps the groups it started with, so restart the runner after a group change:

```console
$ proof runner setup server.home.arpa
```

Running setup again restarts the runner and checks each label again.

## Keep a label off a host

A runner offers what it finds. To keep a label off a host anyway, for example a GPU that a person needs for their work, withhold it in the [pool file](../reference/pool-file.md):

```kdl
host pc {
  runner pc-windows
  runner pc-wsl
  withhold gpu
}
```

# Share a host with the person who uses it

Most hosts are someone's computer first. This guide sets how much of a host Proof keeps free for a person using it, and explains what runs do while they're there, so the person can work, or play, without noticing Proof.

## What a person notices, and doesn't

Proof keeps the memory of a host's **share** free whether or not a person is there, because memory a run already holds can't be taken back when a person arrives. Runs never use it, and an idle host leaves it unused.

While a person is **active** at a host, using its keyboard, mouse, trackpad, or screen:

- Proof also keeps the share's CPUs free for them, and places no new run that would need them.
- Runs already going continue at the lowest priority the operating system has, so the person's programs come first.
- Runs that need the person's display, GPU, or speakers wait until they stop. On Windows, a run already using the display when a person arrives goes on, and the person finds the display busy until the run ends, which its time limit bounds.
- On Linux and Windows, runs draw on separate displays and desktops, and never take the person's keyboard focus.

When nobody has used the host for its `active-for` time, five minutes unless the pool file says otherwise, runs get the share's CPUs back. The share's memory stays free.

Any person counts, not only one owner: a family member at the same computer gets the same share. On Linux and Windows, input from runs never counts as a person, because runs draw on separate displays and desktops.

## Set the share

In the [pool file](../reference/pool-file.md#host), give the host a share large enough for what the person does there. The default share is 2 CPUs and 4 GB. A gaming PC needs much more:

```kdl
host pc {
  runner pc-windows
  runner pc-wsl
  share cpus=8 memory="32GB"
  active-for "10m"
}
```

The 32 GB of memory stays free whenever the PC is on, even when nobody is there, and the 8 CPUs are free only while someone is active. An idle host leaves that memory unused, so set the share's memory to what the person needs.

## Keep a GPU or a host to yourself

To keep runs off a GPU a person uses for their work, withhold the `gpu` label:

```kdl
host pc {
  runner pc-windows
  runner pc-wsl
  withhold gpu
}
```

To take a host out of the pool for a while, stop its runner on the host itself, and start it again later:

```console
$ proof runner stop
$ proof runner start
```

Runs going on that host when it stops are canceled, and their `proof` exits 75.

## Sound

A task whose tests play sound asks for the `sound` label, as [Give runs a GPU, KVM, or a desktop](labels.md) describes. On Linux, such a run plays into a separate virtual audio device, which nobody hears. On Windows and macOS, it plays through the host's speakers, so it waits while a person is active there, as a run that needs the display does. A run that plays sound without asking for the label is heard on Windows and macOS, wherever it runs.

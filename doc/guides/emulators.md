<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Run Android emulators and iOS Simulators

Run a mobile app's tests on an emulator or a Simulator. Android emulators need a Linux host with KVM; iOS Simulators need a Mac with Xcode.

## Android emulators on Linux

The Android emulator needs hardware virtualization, which a Linux runner offers as the `kvm` label once its account can open `/dev/kvm`. If `proof runner list` doesn't show `kvm` for the runner, run setup again on the host, and it prints the administrator commands, such as adding the account to the `kvm` group. [Give runs a GPU, KVM, or a desktop](labels.md#give-a-linux-runner-a-label-its-missing) covers the steps.

Ask for the label in the task, along with enough memory for the emulator:

```kdl
task "test:android" "bin/test-android" memory="12GB" {
  os linux
  label kvm
}
```

The task installs the Android SDK and its system image in its setup, as on a hosted CI service. Its cache folders, such as the system images, are worth declaring as caches, since a system image is gigabytes: see [Keep caches between runs](caches.md).

Start the emulator without a window (`emulator -no-window`) unless the task also asks for the `desktop` label. The emulator and every process it starts, including the `adb` server, end with the run.

A host running Linux in WSL has KVM only when the PC's processor supports nested virtualization, and the emulator runs more slowly there than on a Linux host.

## iOS Simulators on a Mac

A Mac runner with Xcode installed offers the `xcode` label. Xcode isn't something mise installs: install it on the Mac, accept its license once as an administrator, and run setup again so the runner finds it.

```kdl
task "test:ios" "bin/test-ios" memory="8GB" {
  os macos
  label xcode
}
```

The Simulator boots and runs XCTest from a runner without a signed-in session. Ask for the `desktop` label only when tests need to see the Simulator's window.

Simulator devices are kept per account, not per run, and a device can stay booted after the run that booted it. When a run ends, Proof shuts down the devices booted while it ran that no other running run could be using; it never deletes a device. Create the devices a task needs with names only that task uses, and delete them in the task when it's done.

## Memory

Emulators and Simulators take gigabytes beyond the test itself. Request enough in the task, or the run is ended when its host runs short, with the state `out_of_memory` and a message saying how much it held.

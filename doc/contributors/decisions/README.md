<!--
  SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
  SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Decisions

The architectural decisions Proof rests on, one per record. Each record says what was decided, the options weighed, and why the others lost. How each part works is in the documents the records point to, not here.

| Number | Decision | Status |
| --- | --- | --- |
| [0001](0001-proof-is-ruby-shipped-as-a-fledge-app.md) | Proof is written in Ruby and shipped as a self-contained Fledge app | proposed |
| [0002](0002-proof-places-runs-itself-with-no-external-scheduler.md) | Proof's server places runs itself, with no external scheduler | proposed |
| [0003](0003-code-travels-as-git-commits-through-the-server.md) | Code travels to runners as Git commits, through Proof's server | proposed |
| [0004](0004-every-connection-goes-out-to-the-server-over-https.md) | Every connection goes out to Proof's server over HTTPS, and nothing connects to a runner | proposed |
| [0005](0005-runs-never-get-root.md) | Runs never get root, and each runner runs as an account set aside for Proof | proposed |

A record is `proposed` until the code does what it says, and `accepted` from then on. When a decision changes, a new record with the next number restates it whole, and the old one is deleted.

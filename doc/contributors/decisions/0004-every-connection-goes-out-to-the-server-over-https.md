---
status: proposed
date: 2026-11-24
deciders: not recorded
---

# Every connection goes out to Proof's server over HTTPS, and nothing connects to a runner

## Context and Problem Statement

Hosts are computers people own: behind home routers, on laptops that change networks, sometimes asleep. Dozens of agents may follow runs at once from one computer. Something has to carry code, runs, output, and status between the command, the server, and the runners. Which way should connections go, and over what?

## Decision Drivers

* Hosts behind NAT and on changing networks, with no open ports
* Dozens of runs followed at once without exhausting the server's connection limits
* One trust root for the command and every runner, set up without a certificate authority
* No secret on a command line or in an environment variable

## Considered Options

1. The command and every runner connect to the server over HTTPS, and nothing connects to a runner
2. The command or the server connects to each host over SSH

## Decision Outcome

Chosen: option 1, because a runner that connects out works from behind any router, and one HTTPS server can hold many followers on few connections. Option 2 lost because it needs a host reachable from outside, keys for every host, and an SSH daemon whose limits on concurrent sessions and handshakes many followers exhaust.

The one-time codes that `proof server setup` and `proof runner setup` print let the command and each runner check the server's key on their first connection. How it works, and what it must guarantee, is in [How Proof works](../../how-proof-works.md#trust-and-tokens).

Confidence: unbuilt. No recorded measurement compares the two options' cost per follower.

### Consequences

* Good, because adding a host needs no firewall change and no open port.
* Good, because a runner on a laptop keeps working when the laptop changes networks.
* Bad, because the server is a single computer every other part depends on: while it's asleep or off the network, no new run starts.
* Bad, because the server holds a long-lived connection for every runner and every follower, which its operators have to keep within its limits.

### Confirmation

Nothing automated checks it yet.

## More Information

Revisit this decision if a pool needs more than one server.

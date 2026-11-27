# Security policy

## Report a vulnerability privately

Report a vulnerability in Proof through GitHub's private vulnerability reporting, never in [Proof's forum category](https://forum.setdef.com/c/proof), in an email thread, or anywhere else others can read it:

1. Open [the repository's Security tab](https://github.com/setdef/Proof/security) and choose **Report a vulnerability**, or go straight to [a new private advisory](https://github.com/setdef/Proof/security/advisories/new).
2. Fill in the form. Only the project's maintainers can see what you send.

If you aren't sure that a problem is a vulnerability, report it privately anyway.

## What to include

- The Proof version, from `proof --version`.
- Your system: its operating system and processor.
- How to reproduce the problem: the command you ran, the output of `proof status`, and what happened.

## Which versions get fixes

[The README's Compatibility section](README.md#compatibility) lists the systems that Proof supports. It makes no promise that an earlier release gets a fix. A fix ships in a new release, so install [the latest release](https://github.com/setdef/Proof/releases/latest).

# The corpus fixture

`corpus_test.rb` runs the gem against the argv conformance corpus of [usage](https://github.com/jdx/usage) 7.4.1, from its `corpus/` folder at the tag `v7.4.1`. Each vector gives a spec, a command line, and what usage's grammar says reading them gives. The vectors are under usage's MIT license, which `REUSE.toml` records with usage's copyright.

## What is here

- `vectors/` has the corpus's 17 files, with one field added to every vector: `spec_json`, the vector's `spec` as `usage generate json` writes it. The gem reads that JSON, so the tests need no `usage` program and never reach the network.
- `known_differences.json` lists the vectors that the gem doesn't agree with, each with its reason, and the vectors whose spec the gem refuses.
- `vector.rb` runs one vector against the gem and says whether the gem agrees, refuses the spec, or differs.
- `make_fixture.rb` makes `vectors/` again.

## What the tests check

A vector is one of three things, and the tests fail when one moves to another:

- **Agrees.** The gem reads the command line as the corpus says. A vector whose answer is an error agrees when the gem raises `Usage::CommandLineError`, because the corpus pins the class of the error and the gem names none.
- **Refused.** `Usage::Spec.read` raises `Usage::SpecError`, because the spec has a part the gem doesn't act on. The `refused` list holds these, and a spec the gem starts to read fails the test, so the list is taken down as the gem grows.
- **Known difference.** The gem reads the spec and answers otherwise than the corpus. The `differences` list gives each vector's reason from `reasons`. A vector that starts to differ and isn't listed fails the test, and so does a listed vector that starts to agree.

Where usage's documentation and its program disagree, the gem follows the program, as the `docs-and-program` reason says.

## Making it again for a later release of usage

1. Check out the release's tag of usage, and put the same release of its `usage` program on the path: `usage --version` must print the release.
2. Run `ruby gems/usage-rb/test/corpus/make_fixture.rb PATH_TO_THE_CHECKOUT`. It replaces `vectors/`.
3. Run `ruby -Igems/usage-rb/test gems/usage-rb/test/corpus_test.rb`. A vector that is new, or that moved, fails with its id.
4. Put each failing vector in the list it belongs to, or fix the gem. Give a new difference a reason in `reasons`, or reuse one.
5. Change the release in this page, in `corpus_test.rb`, and in the copyright and tag named in `REUSE.toml` if usage's `LICENSE` changed.

# Validation

Five layers, in increasing cost and decreasing frequency. They check different
things and none of them substitutes for another.

```bash
make lint                 # style, naming, documentation, evidence registry
make verify               # byte identity with the reference ROM -- the gate
make test                 # focused unit tests for the Python tooling
make roundtrip-formats    # decode and re-encode the authored data formats
make trace                # emulator evidence for gameplay transactions
make release-check        # everything above, in order
```

## What each layer can tell you

**`make lint`** reads text. It knows that a label sits at column zero, that no
symbol carries a ROM address, that every evidence tag resolves to a registry
entry and back, and that no documentation link is broken. It knows nothing
about what the program does.

**`make verify`** assembles the source and compares the result against the
cartridge dump. This is the only check that can say the reconstruction is
faithful. A green lint with a failing verify means the source is tidy and
wrong.

**`make test`** exercises the Python tooling -- the formatter, the linters, the
codecs, the audit -- so a bug in the checks does not quietly pass everything.

**`make roundtrip-formats`** decodes each authored data segment and re-encodes
it, requiring the original bytes back. It catches a codec that decodes
plausibly but cannot reproduce what it read.

**`make trace`** runs the ROM. It is the only layer that observes behaviour
rather than bytes, and the only one that needs an emulator build.

## The rule

> A green lint or unit-test run never substitutes for byte identity or for
> behavioural evidence.

The order in `make release-check` is deliberate: cheap text checks first so a
typo fails in a second rather than after a movie replay.

## Failure output

Every tool prints bracketed levels -- `[RUN]`, `[INFO]`, `[OK]`, `[WARN]`,
`[ERROR]`, `[FAIL]` -- and exits non-zero on failure. `make verify` reports the
first differing offset with both bytes, which is usually enough to identify the
instruction that moved.

## What is not automated

Whether a name is *right*. The linter can prove that `Ram_ChicksRemaining` is
not an address and that nothing else claims the name; it cannot prove the field
counts chicks. That is a review responsibility, and where the evidence runs out
the answer belongs in [`unknowns.md`](unknowns.md) rather than in a confident
name.

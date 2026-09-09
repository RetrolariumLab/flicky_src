# Validation

Eight layers, in increasing cost and decreasing frequency. They check different
things and none of them substitutes for another.

```bash
make verify-toolchain     # the assembler is the one this release was built with
make lint                 # style, naming, documentation, evidence registry
make check-source-structure # 300-700 lines, exceptions, filename prefixes
make verify               # byte identity with the reference ROM -- the gate
make verify-layout        # the ROM layout is the one config/linker/rom_layout.json declares
make test                 # focused unit tests for the Python tooling
make roundtrip-formats    # decode and re-encode the authored data formats
make trace                # emulator evidence for gameplay transactions
make verify-sound-sequencer # Python audio writes against the real Z80 driver
make release-check        # everything above, in order
make source-2-audit       # validate the current 2.0 contract state
make source-2-check       # complete 1.0 gate, then every 2.0 gate
make format-check         # formatting check without writes
make scaffold-check       # static clone checks without a private ROM
```

## What each layer can tell you

**`make verify-toolchain`** hashes the vendored assembler and its message
catalogs against `config/toolchain.json` and refuses to go on if they differ. It
runs before the assembler rather than after, so a swapped binary is reported by
name instead of appearing as an unexplained byte difference. `build` and
`verify` both depend on it.

**`make lint`** reads text. It knows that a label sits at column zero, that no
symbol carries a ROM address, that every evidence tag resolves to a registry
entry and back, and that no documentation link is broken. It knows nothing
about what the program does.

**`make check-source-structure`** inventories every `.s`, `.asm`, and `.inc`
file. Sources should contain 300-700 lines; every exception needs a concrete
reason in `config/reconstruction/source_structure.json`. It also rejects repeated filename
prefixes in one directory. The check is part of `make lint` as well as a
standalone target.

**`make verify`** assembles the source and compares the result against the
cartridge dump. This is the only check that can say the reconstruction is
faithful. A green lint with a failing verify means the source is tidy and
wrong.

**`make test`** exercises the Python tooling -- the formatter, the linters, the
codecs, the audit -- so a bug in the checks does not quietly pass everything.

**`make roundtrip-formats`** decodes each authored data segment and re-encodes
it, requiring the original bytes back. It catches a codec that decodes
plausibly but cannot reproduce what it read.

**`make verify-layout`** checks `config/linker/rom_layout.json` against three separate
ground truths: module ranges against the addresses the assembler recorded for
every `include` in its listing, landmark symbols against its symbol table, and
the padding gap against the built image. AS has no linker, so this is what owns
the memory layout. A moved module fails here by name before `make verify`
reports it as an offset.

**`make trace`** replays the two recorded movies under the emulator and checks
declared values of work RAM at each scenario's frames. It is the only layer
that observes behaviour rather than bytes, and the only one that needs an
emulator build -- `make build-gens` cross-compiles it in Docker.

**`make verify-sound-sequencer`** uses that instrumented emulator as an audio
oracle. It captures actual Z80 writes to the YM2612, aligns title song `$85`,
and requires 2,624 ordered non-timer writes to equal the standalone Python
sequencer exactly. Their sample positions must also agree with the
frame-resolution Gens trace within 2.1 frames. A missing, truncated, value-,
order-, or timing-divergent trace fails the Source 2.0 gate.

## The rule

> A green lint or unit-test run never substitutes for byte identity or for
> behavioural evidence.

The order in `make release-check` is deliberate: cheap text checks first so a
typo fails in a second rather than after a movie replay.

`make source-2-check` preserves that entire 1.0 gate as its first step. The
release workflow then uses `make source-2-pre-tag-check` on the clean release
commit and `make source-2-tag-check` after creating the annotated tag. A green
development audit is intentionally weaker than either tag-state check.

`make scaffold-check` is the public-clone subset: repository lint, both
release-manifest audits, synthetic Enigma codec cases, Make-interface tests,
and audit fixtures. It deliberately does not claim byte identity or runtime
coverage because those need the user-supplied cartridge data and emulator.

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

# Source Reconstruction 1.0

The first stable reconstruction profile for Flicky (Sega Mega Drive). It is a
preservation baseline, not a claim that every byte's purpose is known.

What it does claim is that uncertainty is explicit: where the evidence ran out,
there is an entry in [`unknowns.md`](unknowns.md) rather than a confident name.

## Identity

| Property | Value |
| --- | --- |
| ROM | Flicky (UE) [!], 131,072 bytes |
| SHA-1 | `83d8bbf0a9b38c42a0bf492d105cc3abe9644a96` |
| MD5 | `805CC0B3724F041126A57A4D956FD251` |
| CRC32 | `4291C8AB` |
| Padding byte | `$FF` |
| Toolchain | AS Macro Assembler 1.42 Beta [Bld 212] with `p2bin` |

The repository tracks source and hashes. It never tracks the ROM, anything
extracted from it, or any build output.

## The stable contract

- `flicky.s` includes 43 address-ordered modules as one AS translation unit.
- `make verify` requires the build to equal the reference dump byte for byte.
- Every symbol is semantic; `make lint` refuses an address-derived name.
- Work RAM, hardware ports and the RAM-resident jump table are named in
  `src/memory/` and referenced by symbol everywhere else.
- Seventeen extracted segments are validated by SHA-1 before every build.
- Material uncertainty is searchable in `unknowns.md` and linked from the
  source location that raises it, in both directions.
- 1,739 ROM symbols are exported for debuggers from the build, not copied.

## Criterion and evidence

| Criterion | Evidence |
| --- | --- |
| The reconstruction is faithful | `make verify` compares against the cartridge dump and reports the first differing offset |
| The source can be navigated | 43 modules under a 700-line cap, mapped in [`source_layout.md`](source_layout.md) and [`subsystems.md`](subsystems.md) |
| Names mean something | Zero address-derived identifiers across 1,979 definitions, enforced by `make lint --strict-naming` |
| The memory map is known | 194 named work RAM fields in [`ram_fields.md`](ram_fields.md), raw addresses rejected outside `src/memory/` |
| Authored data is understood | 8 of 17 segments round-trip byte for byte; the rest declare a weaker claim in `config/data_formats.json` |
| Uncertainty is explicit | 7 entries in [`unknowns.md`](unknowns.md), each referenced from the source, checked both ways by lint |
| The tooling itself is checked | 75 unit tests over the formatter, the linters, the codecs, the symbol export and this audit |
| The contract holds together | `make release-audit` cross-checks the manifests, milestones, documents, targets, toolchain and full git history |

## What this release does not cover

**Runtime evidence.** Twelve scenarios are declared and the runner and
validator are written, but no capture has been produced: the instrumented Gens
build requires Visual Studio 2022, which was not available on the machine this
reconstruction was assembled on. Milestone 7 stays open, the contract records
`runtime_captures_produced: false`, and a unit test fails if that flag is ever
flipped without the roadmap changing with it.

This matters because no check in this release observes behaviour. `make verify`
proves the bytes are right today; only a replay would prove they still do what
they used to after a change to the tooling or the data extraction.

**The Z80 sound driver.** Both images are copied verbatim and never
disassembled ([SND-001](unknowns.md)).

**Byte-exact re-encoding of Nemesis and Enigma.** The decoders are proven by
re-encoding to a valid stream that decodes to identical pixels, but not to the
original bytes ([DATA-002](unknowns.md)).

## Known-unknown policy

The open entries in `unknowns.md` are not release blockers. They are the record
of what an honest reading could not settle, and each names the cheapest
experiment that would settle it. Resolving one later must preserve its evidence
history: replace the **Experiment** with a **Resolution**, do not delete the
entry and do not reuse its identifier.

## Reproducing the audit

```bash
make release-check
```

runs, in order: `lint`, `test`, `roundtrip-formats`, `verify`, `symbols`,
`release-audit`. Cheap text checks come first so a typo fails in a second
rather than after a full assemble.

Everything it writes goes under the ignored `build/` directory, regenerated
each time, so a stale local artifact cannot mask a regression.

## Tagging procedure

1. Merge the reviewed work into `main`.
2. Run `make release-check` on that exact commit.
3. Confirm the worktree is clean.
4. Create the annotated tag `source-reconstruction-1.0` on that commit.

The tag goes on the reviewed `main` commit, never on an intermediate milestone.

## After 1.0

Behaviour-changing work -- fixed-layout hacks, bug fixes, variants -- begins
only after the tag and behind a separate entrypoint and output. The
preservation build stays the default and `make verify` stays the permanent
gate.

The first thing 2.0 should do is close milestone 7 on a machine that can build
the emulator, because it is the only claim this release could not make.

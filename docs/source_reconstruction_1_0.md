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

- `src/main.s` includes 43 address-ordered modules as one AS translation unit.
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
| Names follow a checked vocabulary | Every symbol names a subsystem, derives from one, or is a declared hardware or header exception; `make lint` rejects the rest |
| Every name traces to the disassembly | `config/reconstruction/label_renames.json` maps all 1,717 imported labels to their current names and paths, held to the source in both directions by `make test` |
| Names mean something | Zero address-derived identifiers across 1,979 definitions, enforced by `make lint --strict-naming` |
| The memory map is known | 194 named work RAM fields in [`ram_fields.md`](ram_fields.md), raw addresses rejected outside `src/memory/` |
| Authored data is understood | 8 of 17 segments round-trip byte for byte; the rest declare a weaker claim in `config/authoring/data_formats.json` |
| Uncertainty is explicit | 8 entries in [`unknowns.md`](unknowns.md), seven open and one resolved, each referenced from the source, checked both ways by lint |
| Behaviour is observed, not assumed | 12 movie replays under the emulator, 68 expectations about work RAM checked against the captures |
| The toolchain is the declared one | SHA-256 for every vendored binary in `config/toolchain.json`, checked by `make verify-toolchain` before the assembler runs |
| The ROM layout is declared, not implied | `config/linker/rom_layout.json` holds 43 module ranges, 9 landmarks and the padding gap; `make verify-layout` checks all three against the build |
| The release boundary is machine-checked | The public manifest uses schema version 1, and `make release-audit` resolves every requirement's evidence to a real file, target or scenario |
| The tooling itself is checked | 155 unit tests over the formatter, the linters, the codecs, the state-dump reader, the symbol export and this audit |
| The contract holds together | `make release-audit` cross-checks the manifests, milestones, documents, targets, toolchain and full git history |

## What this release does not cover

**Frame-by-frame image comparison.** The runtime layer checks state, not
pixels. It reads work RAM out of the state dumps and asserts declared values,
which catches an emulated game that diverges; it does not compare screenshots
unless given a reference capture with `--reference-dir`, and no such reference
is tracked. Rendering is therefore covered only where it shows up in memory.

**What a replay can conclude.** Reaching `Bonus_MainLoop` proves the bonus
round runs and that `Ram_NextGameMode` selects it. It does not prove
`Ram_BonusCaughtCount` counts what its name says. The runtime layer narrows
where a wrong name could hide; it does not by itself confirm one.

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

runs, in order: `verify-toolchain`, `check-assets`, `lint`, `test`,
`roundtrip-formats`, `verify`, `verify-layout`, `symbols`, `trace`,
`release-audit`. The order is the one the project release policy requires and
`release_audit.py` checks that the Makefile recipe matches the sequence declared
in the manifest, so the contract cannot claim a layer the gate skips.

Cheap checks come first: the toolchain and asset hashes settle in a second, text
checks a second after that, and a typo fails long before a full assemble.
`trace` is last before the audit because it is much the slowest -- it replays
67,000 frames -- and needs the emulator from `make build-gens`.

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

The runtime layer is the natural place to grow next: a tracked reference
capture would turn the frame comparison on, and scenarios reaching states the
two movies never visit would need the `controlled` method the schema already
allows for.

# Roadmap

## Project goal

Reconstruct Flicky (Sega Mega Drive) as source that a person can read, navigate
and change, while continuing to assemble into the original cartridge image byte
for byte.

Two things this project is not. It is not a port or a rewrite: the 68000
instruction stream, its layout and its timing are the artifact being preserved.
And it is not finished when the ROM matches -- a matching build that nobody can
read is a checksum, not a reconstruction.

## Reference ROM

| Property | Value |
| --- | --- |
| Name | Flicky (UE) [!] |
| Size | 131,072 bytes |
| SHA-1 | `83d8bbf0a9b38c42a0bf492d105cc3abe9644a96` |
| MD5 | `805CC0B3724F041126A57A4D956FD251` |
| CRC32 | `4291C8AB` |
| SHA-256 | `4DF1A91E08376AE773A6EB8E5ABE310F94CA39D8F81583B91A9477FEDCB68C11` |
| Padding byte in unused space | `$FF` |
| Toolchain | AS Macro Assembler 1.42 Beta [Bld 212] with `p2bin` |

Other revisions must not be merged in by address or by name. A different dump
is a different reconstruction.

## Current baseline

- `src/main.s` is an index of 43 address-ordered modules; the largest is under
  700 lines and the mean is around 240.
- The build reproduces the reference ROM exactly, verified against the dump
  itself rather than against a copy of a previous build.
- Every symbol is semantic. Zero address-derived identifiers remain across
  1,979 definitions, and `make lint --strict-naming` refuses new ones.
- All 194 work RAM fields are named and grouped in
  [`ram_fields.md`](ram_fields.md).
- Six open questions are recorded in [`unknowns.md`](unknowns.md), each tied to
  the source location that raises it.
- Seventeen extracted data segments are validated by SHA-1 before every build.

## Source and data policy

The reference ROM is never tracked. Neither is anything sliced out of it.
`make split` is the only command that writes `data/`; `make build` and
`make verify` validate what is there and refuse to run if it is missing or
altered.

Data stays in the source when a contributor can meaningfully read or edit it:
pointer tables, animation scripts, palettes, level object placement, collision
flags, sprite mappings. Data is extracted only when it is an opaque authored
asset -- compressed tile art, the Z80 driver images, the packed level streams.
Extraction is allowed only when the boundaries are proven, the checksum is
recorded in `assets/manifest.json`, the labels stay visible in the source, and
the rebuild remains byte-identical.

## Evidence rules

Comments and names distinguish what was observed from what was inferred. Six
tags carry that distinction:

| Tag | Meaning |
| --- | --- |
| `!(OBS)` | Directly observed in the code or in a trace |
| `!(ASSUME)` | A working interpretation, supported but unproven |
| `!(WHY?)` | Mechanically understood, purpose unclear |
| `!(UNKNOWN)` | Not yet understood |
| `!(BUG?)` | Suspected original-game defect |
| `!(UNUSED)` | Proven unreachable in this ROM |

Every tag except `!(OBS)` must name an entry in [`unknowns.md`](unknowns.md),
and every entry must be referenced from somewhere. `make lint` enforces both.

A comment should explain intent, invariants, state transitions, data formats or
hardware consequences. Restating the instruction in English earns nothing.

## Milestones

### 0. Repository hygiene and a real byte-identity gate - Complete

Normalize line endings, vendor the toolchain per platform, record the reference
identity and every extracted segment in a manifest, and make `make verify`
compare against the cartridge dump.

Closing this milestone found that the build had never matched: 73,045 bytes of
`$00` padding where the cartridge pads with `$FF`, and ten bytes of checksum
verification that had been replaced with a branch and three NOPs for analysis
and never restored.

*Exit criterion:* `make verify` reproduces the reference SHA-1 and fails, with
the first differing offset, when it does not.

### 1. Modular source baseline - Complete

Split the 10,238-line file into address-ordered modules with an include index,
under a 700-line soft cap, with the shared definitions in `src/memory/` and
`src/macros/`.

*Exit criterion:* the ROM is unchanged and no module exceeds the cap.

### 2. Mechanical style and automated checks - Complete

Write down the layout the disassembly already used, enforce it, and add the
source and repository invariant checks.

*Exit criterion:* `make lint` is green and `make format` is byte-neutral.

### 3. Semantic naming - Complete

Replace every address-derived identifier with a name that says what the symbol
is for, keeping the original as provenance on the definition line, and record
what could not be settled.

The RAM-resident jump table at `$FFFA70` resolved exactly against
`Sys_FuncTable`, which named 58 trampolines and explained the frame-advance idiom
used throughout the source.

*Exit criterion:* `make lint --strict-naming` passes.

### 4. Systematic subsystem documentation - Complete

Document the program's shape, the subsystem boundaries and the work RAM map,
and give contributors a written workflow.

*Exit criterion:* a reader can locate the owner of any behaviour without
reading the whole ROM.

### 5. Decode and round-trip the authored data formats - Complete

Eight of the seventeen segments round-trip byte for byte, which proves their
field layout. The six Nemesis segments round-trip semantically -- re-encoding
produces a valid stream that decodes to identical pixels -- but not byte for
byte, because the original compressor used a run-splitting heuristic that has
not been identified and was not minimising size. Enigma is decode-only and the
two Z80 images are opaque.

Source 2.0 subsequently added an exact Enigma encoder, raising the live format
manifest to nine exact round trips while leaving this 1.0 milestone record
unchanged.

The manifest records which claim applies to each segment rather than rounding
them all up, and DATA-002 says what would settle the Nemesis case.

*Exit criterion:* `make roundtrip-formats` covers every segment or names the
entry that explains the exception.

### 6. Debugger symbols - Complete

`make symbols` exports 1,739 ROM symbols as `build/main.sym` and resolves the
breakpoint and watch configs against it, failing if a rename orphaned one.

The instrumented Gens build has no symbol loader, so there is no named
disassembly window to be had. The exported map is in the plain format other
Mega Drive debuggers accept, and the documented workflow applies it to traces
after the fact.

*Exit criterion:* the map is exported and every configured symbol resolves.

### 7. Runtime evidence - Complete

Twelve scenarios in `scenarios/runtime_scenarios.json`, pinned to the ROM and
movie SHA-1, captured with the emulator cross-built by
`make build-gens`. 68 declared expectations about work RAM hold across the
captured windows.

The evidence is state, not pixels. Each scenario names fields of work RAM that
must `hold` across its whole frame range or be `reached` inside it, resolved
through the symbols in `src/memory/ram.inc`. That turns each scene label into a
machine-checkable claim: the score screen is the frames where
`Ram_GameState` is `$8004`, which the source shows is `Game_StateRoundComplete`;
the bonus round is where `Ram_NextGameMode` is `$002C`, which is
`Bonus_MainLoop`. Every one of the twelve human-written scene labels turned out
to match the game mode the emulator actually reached.

*Exit criterion:* every scenario captures, and every declared expectation is
checked against the captured state -- met, and `make release-check` now runs
the capture as part of the gate.

### 8. Automated release audit - Complete

A machine-readable release contract plus an audit that checks the manifests
agree, the required documents exist, the milestone statuses say what they
claim, the toolchain matches, and no ROM-derived payload exists anywhere in
reachable history.

*Exit criterion:* `make release-check` passes end to end.

### 9. Machine-readable release policy - Complete

The release manifest was rewritten to the shape
The project release manifest defines scope in
and out, delta, profiles, runtime coverage, artifacts, aggregate gates, layout
deviations, licensing and provenance, plus a per-requirement status with
evidence that has to resolve to a real file, target or scenario.

Two of its requirements had nothing behind them and now do. The toolchain is
checked against recorded SHA-256 hashes *before* the assembler runs rather than
after the ROM disagrees, and the emulator is pinned by upstream commit because a
locally cross-built MinGW binary has no stable hash. The ROM layout moved out of
prose into `config/rom_layout.json` and is checked against three separate ground
truths -- the assembler's own listing, its symbol table and the built image.

*Exit criterion:* `make release-audit` verifies the manifest against reality,
not just against itself.

### 10. Source Reconstruction 1.0 - Planned

Tag the reviewed state once the audit passes on that exact commit with a clean
worktree.

### 11. Behaviour-changing variants - Not started

Fixed-layout hacks and bug fixes belong to a separate entrypoint and a separate
output. The preservation build stays the default and the gate stays permanent.

## Permanent invariants

- The reference ROM and everything extracted from it are never tracked.
- The default build reproduces the cartridge byte for byte.
- Module order is ROM order.
- Names and comments distinguish evidence from inference.
- Extraction is explicit; ordinary builds never overwrite `data/`.
- Uncertainty is recorded, not rounded off into a confident name.
- Tooling may grow, but it never becomes the source of truth for the original
  program.

## Resuming on another machine

1. Clone the repository.
2. Put a legally obtained `Flicky (UE) [!].bin` in the project root.
3. Run `make init`. It validates the dump, extracts the segments, builds and
   verifies.
4. Run `make lint` and `make verify` before and after any change.
5. Read [`index.md`](index.md) for the documentation order.

Never commit the ROM, `data/**/*.bin`, `fbuilt.bin`, `build/main.p` or the listing.

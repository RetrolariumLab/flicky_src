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

- `flicky.s` is an index of 43 address-ordered modules; the largest is under
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
`func_table`, which named 58 trampolines and explained the frame-advance idiom
used throughout the source.

*Exit criterion:* `make lint --strict-naming` passes.

### 4. Systematic subsystem documentation - Complete

Document the program's shape, the subsystem boundaries and the work RAM map,
and give contributors a written workflow.

*Exit criterion:* a reader can locate the owner of any behaviour without
reading the whole ROM.

### 5. Decode and round-trip the authored data formats - Planned

Give the Nemesis and Enigma formats encoders as well as decoders, and prove
each extracted segment decodes and re-encodes to its exact source bytes. Where
byte-identical re-encoding is not achievable, record why in `unknowns.md`
rather than weakening the claim.

*Exit criterion:* `make roundtrip-formats` covers every segment or names the
entry that explains the exception.

### 6. Debugger symbols - Planned

Export the assembler's symbol output in a form the Gens debugger can load, and
express breakpoints and watches by symbol rather than address.

*Exit criterion:* a symbol resolves in a live debugger session.

### 7. Runtime evidence - Planned

Replay the tracked movies under the instrumented Gens build and validate
declared gameplay transactions. Natural play and controlled RAM patches are
recorded separately and never treated as interchangeable.

*Exit criterion:* the scenarios reproduce and validate from a clean checkout.

### 8. Automated release audit - Planned

A machine-readable release contract plus an audit that checks the manifests
agree, the required documents exist, the milestone statuses say what they
claim, the toolchain matches, and no ROM-derived payload exists anywhere in
reachable history.

*Exit criterion:* `make release-check` passes end to end.

### 9. Source Reconstruction 1.0 - Planned

Tag the reviewed state once the audit passes on that exact commit with a clean
worktree.

### 10. Behaviour-changing variants - Not started

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

Never commit the ROM, `data/**/*.bin`, `fbuilt.bin`, `flicky.p` or the listing.

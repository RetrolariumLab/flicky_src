# Provenance of Labels and Data

This document records where every name and extracted byte in the repository
came from. [`naming.md`](naming.md) describes what names mean now; provenance
instead tells a reader how much confidence to place in their origin.

## The three generations of names

**Generation 1 -- the disassembler.** The project began as a machine
disassembly. Every label was address-derived, such as `sub_12B46`, `loc_12B5E`,
`byte_13A08`, or `word_FFD82C`. These names carried no semantic claim.

**Generation 2 -- procedure naming.** An earlier pass named a few hundred
procedures by reading them. Those names used the same `; was:` marker as the
later semantic pass, so both generations were re-reviewed together. The source
once carried 1,782 such markers.

**Generation 3 -- the 1.0 semantic pass.** All 1,488 remaining
disassembler-generated identifiers were replaced across 1,979 definitions.
`make lint --strict-naming` now rejects an identifier containing four or more
hex digits, preventing address-derived names from returning.

## Reading a name's origin

The sole machine-readable rename registry is
[`config/reconstruction/label_renames.json`](../config/reconstruction/label_renames.json).
It maps every label, equate, and macro from the imported disassembly to its
current name and source path:

```json
["sub_12A94", "Game_StartRound", "src/game/round/main_loop.s"]
```

A symbol that was not renamed has identical `original` and `current` values. A
symbol created by this reconstruction is listed under `project_additions`, so
an inherited name cannot be confused with a new one.

The registry replaced inline `; was:` comments. Such a comment recorded only a
symbol's immediate predecessor, so a twice-renamed symbol could point to a name
that never existed in the imported disassembly. Markers also appeared in
different places for data and procedures, which made them easy to misread.

`tests/validation/test_label_provenance.py` holds the registry to the source in
both directions. Every entry must resolve to a symbol at its declared path,
every source symbol must be represented, every imported label must be
accounted for, and no inline marker may return.

## How much a name is worth

A name is a claim, and the claims do not all have the same strength.

| Basis | Meaning | Example |
| --- | --- | --- |
| Structural | Code shape settles the role, such as a vector or jump-table entry | `Sys_GameModeTable` |
| Cross-referenced | Another named structure forces the interpretation | The `j_` trampolines resolved through `Sys_FuncTable` |
| Observed | Runtime evidence records the value behaving this way | `Ram_NextGameMode`, `Ram_GameState` |
| Interpretive | Reading the code suggests the role without independent confirmation | Most object and enemy helpers |
| Neutral | The name deliberately avoids an unsupported claim | `Ram_SharedState*` entries in `unknowns.md` |

An unresolved name stays neutral and receives an entry in
[`unknowns.md`](unknowns.md). An interpretive name can later be corrected; an
invented meaning must not be presented as settled evidence.

## Two resolved naming questions

**The RAM-resident jump table at `$FFFA70`.** `Sys_LoadFuncTable` copies a table
of entry points into work RAM as `jmp` instructions, and the game calls through
them. The ROM source is `Sys_FuncTable`: a count word of `$39` followed by 58
destination words. Walking the copy loop against that table establishes the
destinations, including 17 entries named `j_*`. Those names come from the table,
not from visual similarity between routines.

**The round tables used by `Demo_Init`.** They were once called
`Demo_RoundHighTable` and `Demo_RoundLowTable` on the assumption that they fed
the high and low bytes of `Ram_RoundNumber`. Runtime evidence showed the
opposite: the former high table is written to `Ram_RoundNumber+1`, the low byte.
They are now `Demo_RoundIndexTable` and `Demo_RoundDisplayTable`, named for
their observed contents. See [`runtime_evidence.md`](runtime_evidence.md).

## Extracted data

The seventeen `binclude` payloads under `data/` come from the cartridge dump.
`scripts/build/split_data_from_rom.py` cuts them at the offsets recorded in
`data/data_addrs.txt`. The payloads are ignored rather than tracked;
`assets/manifest.json` owns each path, ROM address, size, and SHA-1, and
`make check-assets` rejects any mismatch. `make split` is the only command that
writes to `data/`.

The offsets in `data/data_addrs.txt` come from the disassembly's `binclude`
sites. They are therefore facts about the source layout rather than imported
semantic claims.

The two movie recordings, `movies/flicky_longplay.gmv` and
`movies/flicky_demos.gmv`, contain controller input but no game code, game data,
or video. Their SHA-1 values are pinned in
`scenarios/runtime_scenarios.json`. The scene indexes in
`movies/*_description.txt` were written by watching the recordings, and all
twelve declared scenes are checked against states the emulator reaches.

The cartridge dump itself is never tracked. `assets/manifest.json` records its
name, size, SHA-1, MD5, CRC32, and SHA-256. The release audit inspects reachable
Git objects to reject committed ROM-derived payloads.

## Z80 sound-source provenance

The 1.0 release excluded the extracted sound images because their executable
source had not yet been reconstructed. In the 2.0 candidate,
`data_z80_part1.bin` is the byte-identity reference for the symbolic resident
program in `src/sound/z80/driver.asm`. `data_z80_part2.bin` is data rather than
executable code: its descriptors, indexes, SFX and music headers, and data
pointers are authored by `src/sound/z80/load_data.s` and
`src/sound/z80/data.asm`.

Both generated components are assembled and compared with their extracted
images before the main ROM pass. DATA-001 and SND-001 in
[`unknowns.md`](unknowns.md) retain the original evidence and their resolution;
`make verify-relocation` also proves the sound data follows a moved
`Sys_GameEntryPoint`.

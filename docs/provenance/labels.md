# Provenance of Labels and Data

Where every name and every extracted byte in this repository came from. This is
deliberately separate from [`naming.md`](../naming.md), which says what the
names mean now: a reader deciding how much to trust a symbol needs to know its
origin, not just its current spelling.

## The three generations of names

**Generation 1 — the disassembler.** The project began as a machine
disassembly. Every label was address-derived: `sub_12B46`, `loc_12B5E`,
`byte_13A08`, `word_FFD82C`. These names carry no claim at all; they are the
address written twice.

**Generation 2 — procedure naming.** An earlier pass, before this release,
named a few hundred procedures by reading them. Those names carry the same
`; was:` marker as generation 3 and cannot be told apart by inspection; both
were re-reviewed during the 1.0 naming pass. The source carries 1,782 markers
in total.

**Generation 3 — the 1.0 semantic pass.** All 1,488 remaining
disassembler-generated identifiers were replaced across 1,979 definitions.
`make lint --strict-naming` now rejects any identifier containing four or more
hex digits, so generation 1 cannot come back.

## Reading a name's origin

[`label_renames.json`](label_renames.json) maps every label, equate and macro
the imported disassembly defined to the name this reconstruction gave it, and
the file that now holds it:

```json
["sub_12A94", "Game_StartRound", "src/game/main_loop.s"]
```

A symbol the reconstruction did not rename appears with `original` equal to
`current`. A symbol that never existed in the disassembly is listed separately
under `project_additions`, so the two cases cannot be confused.

The table replaced an inline `; was:` comment on every renamed symbol, for two
reasons. The marker recorded a symbol's *immediate predecessor*, not its origin,
so a symbol renamed twice pointed at a name that had never existed in the
disassembly. And it sat in two different places -- on the label line for data,
on the first line of the body for a procedure -- which is easy to misread:

```asm
Game_StartRound:
                jsr     Sys_InitTitleScreen             ; was: sub_12A94
```

`tests/test_label_provenance.py` holds the table to the source in both
directions. Every entry must name a symbol that exists at the path it declares,
every symbol in `src/` must have an entry, every imported label must be
accounted for, and no `; was:` may come back.

## How much a name is worth

A name is a claim, and the claims here are not all equally strong.

| Basis | What it means | Example |
| --- | --- | --- |
| Structural | The code's shape settles it: a jump table entry, a vector, a loop counter | `Sys_GameModeTable` |
| Cross-referenced | Another named thing forces the reading | The `j_` trampolines, resolved through `Sys_FuncTable` below |
| Observed | The runtime layer saw the value behave this way | `Ram_NextGameMode`, `Ram_GameState` |
| Interpretive | A reading of what the code does, unconfirmed by anything else | Most object and enemy helpers |
| Neutral | Deliberately says little, because nothing settles it | `Ram_SharedState*` entries in `unknowns.md` |

Where nothing settles a name it stays neutral and gets a registry entry in
[`unknowns.md`](../unknowns.md) rather than an invented one. An interpretive
name that later turns out wrong is a rename; an invented name presented as
settled is a lie in the record.

## Two resolutions worth recording

**The RAM-resident jump table at `$FFFA70`.** `Sys_LoadFuncTable` copies a table of
entry points into work RAM as `jmp` instructions and the game calls through
them. The source in ROM is `Sys_FuncTable`: a count word of `$39` followed by 58
destination words. Walking the copy loop against that table gives each RAM
address its real destination, and 17 of them are named `j_*` after the
procedure they reach. That is why the `j_` prefix is not a guess here — the
destination is named because the table says so, not because the code looked
similar.

**`Demo_Init`'s round tables.** These were named `Demo_RoundHighTable` and
`Demo_RoundLowTable` on the assumption that they fed the high and low bytes of
`Ram_RoundNumber`. The runtime layer showed the opposite: the "high" table is
written to `Ram_RoundNumber+1`, the low byte. They are now
`Demo_RoundIndexTable` and `Demo_RoundDisplayTable`, named after what they are
observed to contain. See [`runtime_evidence.md`](../runtime_evidence.md).

## Data provenance

**The seventeen extracted segments.** Every `binclude` payload under `data/`
comes from the cartridge dump, cut at the offsets in `data/data_addrs.txt` by
`scripts/split_data_from_rom.py`. None is tracked: `assets/manifest.json` holds
the path, ROM address, size and SHA-1 of each, and `make check-assets` refuses
to build against a segment that does not match. `make split` is the only command
that writes to `data/`.

The offsets in `data_addrs.txt` were derived from the disassembly itself — they
are the addresses of the `binclude` sites — so they are a fact about the source,
not an external claim.

**The two movie recordings.** `movies/flicky_longplay.gmv` and
`movies/flicky_demos.gmv` contain controller input and nothing else: no game
code, no data, no video. Both are pinned by SHA-1 in
`scenarios/runtime_scenarios.json`, and the capture refuses to run against a
different file. Their scene indexes in `movies/*_description.txt` were written
by watching the recordings; the runtime layer since confirmed all twelve
against the game mode the emulator actually reached.

**The cartridge dump itself** is never tracked. `assets/manifest.json` records
its name, size, SHA-1, MD5, CRC32 and SHA-256, and `scripts/release_audit.py`
walks every reachable git object to prove no payload was ever committed.

## Z80 sound-source provenance

The 1.0 release excluded the extracted sound images by name because it had not
yet reconstructed their source. On `source-2.0`, `data_z80_part1.bin` is the
byte-identity reference for the symbolic resident program in
`src/sound/z80_driver_z80.asm`. `data_z80_part2.bin` is not executable: its
descriptors, indices, SFX/music headers and data pointers are authored in
`src/data/z80_sound.s` and `src/sound/z80_sound_data.asm`.

Both generated components are assembled and compared with the extracted
images before the main ROM pass. DATA-001 and SND-001 in
[`unknowns.md`](../unknowns.md) retain the original evidence and record their
resolution; `make verify-relocation` separately proves the sound data follows a
moved `Sys_GameEntryPoint`.

# Authored Data Formats

Seventeen segments are cut out of the ROM by `make split` and checked against
`assets/manifest.json`. Most are pulled back in with `binclude`; the two Z80
segments are the original driver and sound banks, which the build assembles from
source instead. The second half of this page gives the formats of the tables
written in the source.

## The segments

| Segment                | Region   | ROM range         | Bytes | Format                                    |
| ---------------------- | -------- | ----------------- | ----: | ----------------------------------------- |
| `SegaPalette`          | `other`  | `$4F6`-`$50A`     |    20 | Packed palette, compact form              |
| `SegaEnigma`           | `arteni` | `$510`-`$51A`     |    10 | Enigma tilemap                            |
| `SegaTiles`            | `artnem` | `$51A`-`$856`     |   828 | Nemesis tile art                          |
| `z80_part1`            | `sound`  | `$1316`-`$22FC`   | 4,070 | Z80 machine code                          |
| `Jap1BPPTiles`         | `artunc` | `$2372`-`$290A`   | 1,432 | Uncompressed 1bpp font                    |
| `z80_part2`            | `sound`  | `$101D4`-`$10CD4` | 2,816 | 68000 load descriptors and Z80 sound data |
| `EndingMusic81Overlay` | `other`  | `$135E8`-`$139A2` |   954 | Alternate Z80 music data for song `$81`   |
| `DemoInputStream0`     | `other`  | `$13A82`-`$13B82` |   256 | Recorded controller input                 |
| `DemoInputStream2`     | `other`  | `$13C52`-`$13D70` |   286 | Recorded controller input                 |
| `DemoInputStream3`     | `other`  | `$13D70`-`$13E70` |   256 | Recorded controller input                 |
| `TigerJumpArcTable`    | `other`  | `$15B94`-`$15D14` |   384 | Per-round jump velocity pairs             |
| `LevelTiles`           | `artnem` | `$16E58`-`$185FC` | 6,052 | Nemesis tile art                          |
| `Latin1BPPTiles`       | `artunc` | `$185FC`-`$18754` |   344 | Uncompressed 1bpp font                    |
| `ExitTiles`            | `artnem` | `$18754`-`$187D4` |   128 | Nemesis tile art                          |
| `SpritesTiles`         | `artnem` | `$187D4`-`$1993E` | 4,458 | Nemesis tile art                          |
| `ScoresTiles`          | `artnem` | `$1993E`-`$19EEE` | 1,456 | Nemesis tile art                          |
| `FlickyLogoTiles`      | `artnem` | `$19EEE`-`$1A196` |   680 | Nemesis tile art                          |

`DemoInputStream1` is not in this table because it is not extracted: it lives in
the source as `dc.w` data in `src/game/screens/attract_mode.s`, which is why the
numbering skips from 0 to 2 among the extracted files.

## Nemesis

Huffman-coded 4bpp tile art, the standard Sega first-party format. A header
builds a code table mapping variable-length codes to (palette index, run length)
pairs; the body emits nibbles until the tile count is exhausted. A flag in the
header selects XOR mode, where each row is XOR-ed against the previous one.

The canonical decoder is Retrolarium Core's `retrolarium_core.oracles.nemesis`.
It decodes all six segments:

```
ExitTiles         128 ->    288 bytes
FlickyLogoTiles   680 ->  1,824 bytes
LevelTiles      6,052 -> 10,976 bytes
ScoresTiles     1,456 ->  2,656 bytes
SegaTiles         828 ->  1,536 bytes
SpritesTiles    4,458 ->  9,696 bytes
```

The in-ROM decompressor is `Nem_Decomp` in `src/compression/nemesis_enigma.s`,
and reading it alongside the Python version is the fastest way to understand the
format.

## Enigma

Run-coded tilemaps. An opcode selects one of seven behaviours -- copy an
incrementing run, repeat one tile, write a static value, write incrementing or
decrementing values, or take tiles inline -- and each tile word can carry
per-tile priority, palette and flip bits read from a bitstream.

The canonical decoder is Retrolarium Core's `retrolarium_core.oracles.enigma`;
the in-ROM version is `Eni_Decompress`, dispatching through
`Eni_OpcodeJumpTable`. The one Enigma segment decodes from 10 bytes to 96.

## Uncompressed 1bpp fonts

`Jap1BPPTiles` and `Latin1BPPTiles` are one bit per pixel. They are expanded to
4bpp at load time by the routine at `Nem_Decomp1bpp_Begin`, which despite
sharing the Nemesis prefix its callers gave it is a separate algorithm: it reads
one byte, tests each bit, and emits the foreground or background nibble
accordingly. The foreground and background nibbles come from the caller, which
is how the same font is drawn in different colours.

## Z80 sound program and data

`z80_part1` is the resident program. It is reconstructed as
`src/sound/z80/driver.asm` and assembled in a separate Z80 pass before the main
ROM includes it. Its executable boundary, RAM layout and sequence dispatcher are
documented in [z80_sound_driver.md](z80_sound_driver.md).

`z80_part2` is not another executable image. Its two load descriptors copy sound
data to Z80 `$1000` and `$1200`: SFX headers/sequences in the first bank, and
data indices, command priorities, music headers, FM voices, envelopes and
sequences in the second. The descriptors are expressions in
`src/sound/z80/load_data.s`; the 2,804-byte payload is authored in
`src/sound/z80/data.asm`, where Z80 little-endian pointers are computed from
labels. The build splits it at `zMusicBank` into separately included SFX and
music banks; `make verify` covers them with the rest of the ROM, and the movies
played on the relocated build show that the sound loads follow a moved game
image.

`EndingMusic81Overlay` replaces the resident `$81` music header and sequences at
Z80 `$125B` (`src/game/screens/ending.s`); `data.asm` refuses to assemble if
`zMusic81Header` leaves that address. The 68000 `DBF` copy reads one byte beyond
the 954-byte block, as the original does.

## Demo input streams

Pairs of (input byte, hold count). `Demo_ReadInput` writes the byte into
`Ram_Joypad` and decrements `Ram_DemoHoldFrames`, advancing to the next pair
when it reaches zero. This is the same idea as the tracked movies, but built
into the ROM for attract mode.

## Round trips

Retrolarium Core's decoders and encoders (`retrolarium_core.oracles`) handle
every extracted format. The palette, demo streams, Tiger jump arcs, both fonts
and the Enigma tilemap re-encode to their original bytes. The six Nemesis
segments re-encode to streams that decode to the same pixels but not to the same
bytes: the encoder reuses the original code table, and no rule for splitting
runs found so far reproduces the original (a bit-optimal split is smaller, 117
bytes against 128 for `ExitTiles`); see [DATA-002](unknowns.md). An edited
Enigma tilemap is accepted only when its stream still fits its ten-byte slot.

# Formats in the source

## Rounds and level records

The 48 rounds use 36 level records: `Level_DataPointers` (`src/data/tables.s`)
and `Level_SpecialTilePointers` (`src/data/level_layout.s`) hold one word per
round, and each bonus round shares the record of the round before it. The round
loop picks the entries by round number (`Math_ModuloUpper` folds round 49 back
to round 1), and `Tiger_JumpArcTable` holds eight bytes per round in the same
order.

A level record (`Level_Data<n>`) starts with the collision map, a run-coded
stream that `Collision_LoadMap` (`src/game/world.s`) writes into the 32x28 map
from its third row (cell `$40`):

| Byte        | Meaning                                                    |
| ----------- | ---------------------------------------------------------- |
| `$00`       | end of the map                                             |
| `$01-$7F`   | skip that many cells                                       |
| `%10nnnnnn` | `n` solid cells to the right; the cursor moves past them   |
| `%11nnnnnn` | `n` solid cells downwards; the cursor moves one cell right |

Runs must stay inside the map. `Collision_SetBoundaries` then makes the outer
rows solid. The object placements follow the map: `Level_SpawnObjects` reads the
player's start (column, row), the entry arrow, the background objects, the
window girl and the groups of chicks and enemies, each group as a count byte and
that many positions.

`Level_SpecialTiles<n>` is a byte stream written as words. It has three groups,
each a count byte and that many (column, row) pairs: cells that get flag bit 7,
then bits 7 and 6, then bit 5 (`Collision_SetSpecialTiles`). An empty group is a
single `$00`.

Retrolarium Kit's Flicky level codec (`games/flicky/workspace/levels.py`) reads
and writes both, within the space all levels share.

## Other tables

The sprite frame records, animation scripts, palettes, text encoding
(`src/game/text_encoding.s`) and bonus-round motion tables are written in the
source next to the code that reads them; Retrolarium Kit's Flicky codecs
(`workspace/sequences.py`, `workspace/semantics.py`) describe how the Studio
edits them.

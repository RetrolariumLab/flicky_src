# Authored Data Formats

Seventeen reference segments are sliced out of the ROM by `make split` and
validated against `assets/manifest.json` before every build. Most are pulled
back in with `binclude`; the two sound segments are now byte-exact references
for authored assembly. This page says what each one is and what the tooling can
currently do with it.

## The segments

| Segment | Region | ROM range | Bytes | Format |
| --- | --- | --- | ---: | --- |
| `SegaPalette` | `other` | `$4F6`-`$50A` | 20 | Packed palette, compact form |
| `SegaEnigma` | `arteni` | `$510`-`$51A` | 10 | Enigma tilemap |
| `SegaTiles` | `artnem` | `$51A`-`$856` | 828 | Nemesis tile art |
| `z80_part1` | `sound` | `$1316`-`$22FC` | 4,070 | Z80 machine code |
| `Jap1BPPTiles` | `artunc` | `$2372`-`$290A` | 1,432 | Uncompressed 1bpp font |
| `z80_part2` | `sound` | `$101D4`-`$10CD4` | 2,816 | 68000 load descriptors and Z80 sound data |
| `EndingMusic81Overlay` | `other` | `$135E8`-`$139A2` | 954 | Alternate Z80 music data for song `$81` |
| `DemoInputStream0` | `other` | `$13A82`-`$13B82` | 256 | Recorded controller input |
| `DemoInputStream2` | `other` | `$13C52`-`$13D70` | 286 | Recorded controller input |
| `DemoInputStream3` | `other` | `$13D70`-`$13E70` | 256 | Recorded controller input |
| `TigerJumpArcTable` | `other` | `$15B94`-`$15D14` | 384 | Per-round jump velocity pairs |
| `LevelTiles` | `artnem` | `$16E58`-`$185FC` | 6,052 | Nemesis tile art |
| `Latin1BPPTiles` | `artunc` | `$185FC`-`$18754` | 344 | Uncompressed 1bpp font |
| `ExitTiles` | `artnem` | `$18754`-`$187D4` | 128 | Nemesis tile art |
| `SpritesTiles` | `artnem` | `$187D4`-`$1993E` | 4,458 | Nemesis tile art |
| `ScoresTiles` | `artnem` | `$1993E`-`$19EEE` | 1,456 | Nemesis tile art |
| `FlickyLogoTiles` | `artnem` | `$19EEE`-`$1A196` | 680 | Nemesis tile art |

`DemoInputStream1` is not in this table because it is not extracted: it lives in
the source as `dc.w` data in `src/game/screens/attract_mode.s`, which is why the numbering skips
from 0 to 2 among the extracted files.

## Nemesis

Huffman-coded 4bpp tile art, the standard Sega first-party format. A header
builds a code table mapping variable-length codes to (palette index, run
length) pairs; the body emits nibbles until the tile count is exhausted. A flag
in the header selects XOR mode, where each row is XOR-ed against the previous
one.

The canonical decoder is `scripts/formats/nemesis_dec.py`. It is shared by
build extraction and content authoring, requires no compiled helper, and
decodes all six segments:

```
ExitTiles         128 ->    288 bytes
FlickyLogoTiles   680 ->  1,824 bytes
LevelTiles      6,052 -> 10,976 bytes
ScoresTiles     1,456 ->  2,656 bytes
SegaTiles         828 ->  1,536 bytes
SpritesTiles    4,458 ->  9,696 bytes
```

The in-ROM decompressor is `Nem_Decomp` in
`src/compression/nemesis_enigma.s`, and reading it alongside the Python version
is the fastest way to understand the format.

## Enigma

Run-coded tilemaps. An opcode selects one of seven behaviours -- copy an
incrementing run, repeat one tile, write a static value, write incrementing or
decrementing values, or take tiles inline -- and each tile word can carry
per-tile priority, palette and flip bits read from a bitstream.

The canonical decoder is `scripts/formats/enigma_dec.py`; the in-ROM version is
`Eni_Decompress`, dispatching through `Eni_OpcodeJumpTable`. The one Enigma
segment decodes from 10 bytes to 96.

## Uncompressed 1bpp fonts

`Jap1BPPTiles` and `Latin1BPPTiles` are one bit per pixel. They are expanded to
4bpp at load time by the routine at `Nem_Decomp1bpp_Begin`, which despite
sharing the Nemesis prefix its callers gave it is a separate algorithm: it
reads one byte, tests each bit, and emits the foreground or background nibble
accordingly. The foreground and background nibbles come from the caller, which
is how the same font is drawn in different colours.

## Z80 sound program and data

`z80_part1` is the resident program. It is reconstructed as
`src/sound/z80/driver.asm`, assembled in a separate Z80 pass and compared
byte for byte before the main ROM includes it. Its executable boundary, RAM
layout and sequence dispatcher are documented in
[z80_sound_driver.md](z80_sound_driver.md).

`z80_part2` is not another executable image. Its two load descriptors copy
sound data to Z80 `$1000` and `$1200`: SFX headers/sequences in the first bank,
and data indices, command priorities, music headers, FM voices, envelopes and
sequences in the second. The descriptors are expressions in
`src/sound/z80/load_data.s`; the 2,804-byte payload is authored in
`src/sound/z80/data.asm`, where Z80 little-endian pointers are computed
from labels. The build splits it at `zMusicBank` into separately included SFX
and music banks. `make z80-data-check` proves byte identity and
`make verify-relocation` proves the 68000 source offsets follow a moved game
image. This resolves [DATA-001](unknowns.md).

## Demo input streams

Pairs of (input byte, hold count). `Demo_ReadInput` writes the byte into
`Ram_Joypad` and decrements `Ram_DemoHoldFrames`, advancing to the next pair
when it reaches zero. This is the same idea as the tracked `.gmv` movies, but
built into the ROM for attract mode.

## Round trips

`make roundtrip-formats` decodes every segment and checks it against the claim
recorded in `config/authoring/data_formats.json`. Three claims are possible and they are
not interchangeable.

**`exact`** -- decoding and re-encoding returns the original bytes. Eight
segments qualify, and for these the field layout is proven rather than
plausible:

```
SegaPalette          20 bytes,    10 entries
DemoInputStream0    256 bytes,   128 entries
DemoInputStream2    286 bytes,   143 entries
DemoInputStream3    256 bytes,   128 entries
TigerJumpArcTable  384 bytes,    48 entries
Jap1BPPTiles      1,432 bytes, 1,432 rows
Latin1BPPTiles      344 bytes,   344 rows
SegaEnigma           10 bytes,    48 words
```

**`semantic`** -- re-encoding produces a valid stream that decodes to identical
pixels, but not the original bytes. All six Nemesis segments are in this class.
`scripts/formats/nemesis_enc.py` reuses the code table carried by the original
stream, so the only remaining freedom is how the nybble sequence is split into
runs, and no splitting rule tried so far reproduces the original. A bit-optimal
split is consistently *smaller* than the original -- 117 bytes against 128 for
`ExitTiles` -- which says the original compressor was not minimising size. This
is [DATA-002](unknowns.md).

There are no remaining decode-only formats. `SegaEnigma` now has an optimizing
encoder which reproduces its 48 incrementing words in the original ten-byte
slot. Edited tilemaps are accepted only when their optimal stream still fits
that fixed region.

The historical 1.0 format manifest still marks both extracted Z80 segments as
`none`. On `source-2.0`, the first claim is superseded by the independent
source-assembly equality gate; the second remains an authored-data task.
`EndingMusic81Overlay` is also `none`: it replaces the resident `$81` music
header and sequences at Z80 `$125B`. Its previous `tilemap_words` round trip
only proved that arbitrary even-length bytes survive conversion to words and
back; it did not decode the sound format. The 68000 `DBF` copy reads one byte
beyond this 954-byte block, matching the original ROM.

This distinction is the point of the milestone. A decoder can be plausibly
wrong -- it can produce sensible-looking tiles from a misunderstood header and
nobody would notice. Requiring the encoder to reproduce the original bytes is
what turns "this decodes" into "this is understood", so the eight `exact`
segments carry a stronger guarantee than the six `semantic` ones, and the
manifest says which is which rather than rounding them all up.

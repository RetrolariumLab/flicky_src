# Authored Data Formats

Seventeen segments are sliced out of the reference ROM by `make split`,
validated against `assets/manifest.json` before every build, and pulled back in
with `binclude`. This page says what each one is and what the tooling can
currently do with it.

## The segments

| Segment | Region | ROM range | Bytes | Format |
| --- | --- | --- | ---: | --- |
| `SegaPalette` | `other` | `$4F6`-`$50A` | 20 | Packed palette, compact form |
| `SegaEnigma` | `arteni` | `$510`-`$51A` | 10 | Enigma tilemap |
| `SegaTiles` | `artnem` | `$51A`-`$856` | 828 | Nemesis tile art |
| `z80_part1` | `sound` | `$1316`-`$22FC` | 4,070 | Z80 machine code |
| `Jap1BPPTiles` | `artunc` | `$2372`-`$290A` | 1,432 | Uncompressed 1bpp font |
| `z80_part2` | `sound` | `$101D4`-`$10CD4` | 2,816 | Z80 machine code and tables |
| `EndingCongratsArt` | `other` | `$135E8`-`$139A2` | 954 | Tilemap for the ending screen |
| `DemoInputStream0` | `other` | `$13A82`-`$13B82` | 256 | Recorded controller input |
| `DemoInputStream2` | `other` | `$13C52`-`$13D70` | 286 | Recorded controller input |
| `DemoInputStream3` | `other` | `$13D70`-`$13E70` | 256 | Recorded controller input |
| `LizardJumpArcTable` | `other` | `$15B94`-`$15D14` | 384 | Per-round jump velocity pairs |
| `LevelTiles` | `artnem` | `$16E58`-`$185FC` | 6,052 | Nemesis tile art |
| `Latin1BPPTiles` | `artunc` | `$185FC`-`$18754` | 344 | Uncompressed 1bpp font |
| `ExitTiles` | `artnem` | `$18754`-`$187D4` | 128 | Nemesis tile art |
| `SpritesTiles` | `artnem` | `$187D4`-`$1993E` | 4,458 | Nemesis tile art |
| `ScoresTiles` | `artnem` | `$1993E`-`$19EEE` | 1,456 | Nemesis tile art |
| `FlickyLogoTiles` | `artnem` | `$19EEE`-`$1A196` | 680 | Nemesis tile art |

`DemoInputStream1` is not in this table because it is not extracted: it lives in
the source as `dc.w` data in `src/game/demo.s`, which is why the numbering skips
from 0 to 2 among the extracted files.

## Nemesis

Huffman-coded 4bpp tile art, the standard Sega first-party format. A header
builds a code table mapping variable-length codes to (palette index, run
length) pairs; the body emits nibbles until the tile count is exhausted. A flag
in the header selects XOR mode, where each row is XOR-ed against the previous
one.

The decoder is implemented twice, in `tools/nemesis_dec.c` and
`tools/nemesis_dec.py`, so the data can be inspected either with a compiled
binary or with no toolchain at all. Both decode all six segments:

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

Implemented in `tools/enigma_dec.c` and `tools/enigma_dec.py`; the in-ROM
version is `Eni_Decompress`, dispatching through `Eni_OpcodeJumpTable`. The one
Enigma segment decodes from 10 bytes to 96.

## Uncompressed 1bpp fonts

`Jap1BPPTiles` and `Latin1BPPTiles` are one bit per pixel. They are expanded to
4bpp at load time by the routine at `Nem_Decomp1bpp_Begin`, which despite
sharing the Nemesis prefix its callers gave it is a separate algorithm: it
reads one byte, tests each bit, and emits the foreground or background nibble
accordingly. The foreground and background nibbles come from the caller, which
is how the same font is drawn in different colours.

## Z80 images

`z80_part1` and `z80_part2` are copied into sound RAM verbatim and executed by
the Z80. They are opaque to this reconstruction; see
[SND-001](unknowns.md). `z80_part2` additionally contains pointer tables whose
values assume the 68000 code sits at `$10000`, which is
[DATA-001](unknowns.md) and the reason `Sys_GameEntryPoint` must not move.

## Demo input streams

Pairs of (input byte, hold count). `Demo_ReadInput` writes the byte into
`Ram_Joypad` and decrements `Ram_DemoHoldFrames`, advancing to the next pair
when it reaches zero. This is the same idea as the tracked `.gmv` movies, but
built into the ROM for attract mode.

## Round trips

`make roundtrip-formats` decodes every segment and checks it against the claim
recorded in `config/data_formats.json`. Three claims are possible and they are
not interchangeable.

**`exact`** -- decoding and re-encoding returns the original bytes. Eight
segments qualify, and for these the field layout is proven rather than
plausible:

```
SegaPalette          20 bytes,    10 entries
DemoInputStream0    256 bytes,   128 entries
DemoInputStream2    286 bytes,   143 entries
DemoInputStream3    256 bytes,   128 entries
LizardJumpArcTable  384 bytes,    48 entries
EndingCongratsArt   954 bytes,   477 entries
Jap1BPPTiles      1,432 bytes, 1,432 rows
Latin1BPPTiles      344 bytes,   344 rows
```

**`semantic`** -- re-encoding produces a valid stream that decodes to identical
pixels, but not the original bytes. All six Nemesis segments are in this class.
`tools/nemesis_enc.py` reuses the code table carried by the original stream, so
the only remaining freedom is how the nybble sequence is split into runs, and
no splitting rule tried so far reproduces the original. A bit-optimal split is
consistently *smaller* than the original -- 117 bytes against 128 for
`ExitTiles` -- which says the original compressor was not minimising size. This
is [DATA-002](unknowns.md).

**`decode_only`** -- there is a decoder and no encoder. `SegaEnigma` is the one
case; it decodes from 10 bytes to 96 and stops there.

The two Z80 images have no codec at all and are marked `none`.

This distinction is the point of the milestone. A decoder can be plausibly
wrong -- it can produce sensible-looking tiles from a misunderstood header and
nobody would notice. Requiring the encoder to reproduce the original bytes is
what turns "this decodes" into "this is understood", so the eight `exact`
segments carry a stronger guarantee than the six `semantic` ones, and the
manifest says which is which rather than rounding them all up.

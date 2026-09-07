# Source Layout

`src/main.s` is not a source file any more: it is the index. It sets the CPU and
assembly options, pulls in the shared definitions, and then includes 36
modules in ROM address order.

AS assembles the whole thing as a single translation unit, so every label stays
global and cross-module branches need no declaration. That also means **the
include order is the ROM layout**. Moving an include moves code in the output
and `make verify` fails immediately.

## Granularity policy

A module owns one coherent subsystem, the helpers only it uses, and the data
those helpers consume. The preferred range is **300-700 lines**. Both bounds,
and the reason for every source outside them, are enforced by
`make check-source-structure` from `config/source_structure.json`. A procedure
is never cut in half, and a small table stays beside the code that reads it.

The policy covers the 68000 tree, Z80 tree, entrypoint indexes and shared
definitions: 23 of 50 files are in the preferred range and 27 have explicit
exceptions. The largest byte-emitting module is `src/game/world.s` at exactly
700 lines. Short files remain only where the ROM order, a hardware/ABI boundary,
or an index/asset-ledger role gives them a stronger boundary than line count.

Where a module boundary looks arbitrary it usually is not: the ROM interleaves
subsystems, and the layout follows the ROM rather than an idealized call graph.
`src/compression/nemesis_enigma.s` holds both decompressors because their
routines alternate in the original image, and `src/data/level_layout.s` sits
between the lizard and snake code because that is where the data physically is.

## Shared definitions

These emit no bytes and are included before any module:

| File | Contents |
| --- | --- |
| `src/macros/macros.inc` | Alignment pseudo-instructions (`cnop`, `align`, `org0`) |
| `src/memory/hardware.inc` | VDP, Z80 and I/O port addresses |
| `src/memory/constants.inc` | VDP status bit constants |
| `src/memory/ram.inc` | Work RAM field addresses |

`src/sound/z80/driver.asm` is a separate Z80 translation-unit index rather than
part of the address-ordered 68000 include tree. Its seven implementation files
under `src/sound/z80/driver/` are 302-535 lines, apart from the non-emitting ABI
declarations. Together they assemble to 4,070 bytes, are checked against the
reference driver, and are included by `bank0.s`.

## Source extensions

AS does not assign a language or processor to a filename extension; the `cpu`
directive inside each translation unit does that. This repository uses the
extension to make the two build boundaries visible instead:

- `.s` is an address-ordered 68000 module included by `src/main.s`;
- `.asm` belongs to a separately assembled sound tree; `driver.asm` and
  `data.asm` are its translation-unit entrypoints;
- `.inc` contains shared definitions and emits no bytes by itself.

The distinction is architectural rather than an assembler requirement. It
also prevents a Z80 source from being mistaken for a module that can be moved
inside the 68000 ROM include order.

## Directory vocabulary

Repeated filename qualifiers are represented by directories. Enemy actors are
`game/enemies/{cat,lizard,snake,spawner}.s`, screen modes are under
`game/screens/`, and bonus, round, actor, and Z80 concerns follow the same
pattern. A file inside one directory therefore does not repeat an `enemy_`,
`screen_`, `round_`, or `z80_` prefix. `make check-source-structure` rejects a
new repeated prefix and asks for a subdirectory or a more specific name.

The Z80 implementation split is independently visible:

| File | Lines | Responsibility |
| --- | ---: | --- |
| `driver/abi.asm` | 108 | Non-emitting hardware and resident-RAM ABI |
| `driver/core.asm` | 302 | Reset, timer interrupt, update loop |
| `driver/fm.asm` | 535 | FM event, modulation, envelope, voice handling |
| `driver/control.asm` | 439 | Sound commands, track startup, pause and fade |
| `driver/mixer.asm` | 357 | Reset/silence, priority polling, DAC path |
| `driver/coordination.asm` | 424 | Coordination-flag dispatch and handlers |
| `driver/sequencing_psg.asm` | 303 | Calls, loops, PSG update and envelopes |

## Modules

| File | ROM range | Lines | Responsibility |
| --- | --- | ---: | --- |
| `src/system/startup.s` | `$000000-$000855` | 371 | Header, reset/boot sequence, Sega screen |
| `src/system/dma.s` | `$000856-$000AD3` | 273 | Game-state init, DMA helpers and VRAM fills |
| `src/compression/nemesis_enigma.s` | `$000AD4-$000DBF` | 452 | Nemesis and Enigma decompressors |
| `src/system/input.s` | `$000DC0-$000E41` | 65 | Joypad initialization and polling |
| `src/rendering/vdp.s` | `$000E42-$001013` | 244 | VDP registers, sprite area, tilemap writes, palette fade |
| `src/sound/z80/host.s` | `$001014-$001195` | 183 | Z80 bus arbitration and the sound command queue |
| `src/rendering/tilemap.s` | `$001196-$001315` | 175 | Palette and tilemap loading, VRAM and CRAM transfers |
| `src/data/bank0.s` | `$001316-$00FFFF` | 70 | Source-built Z80 driver image, function table, Japanese 1bpp font |
| `src/system/game_entry.s` | `$010000-$0101D3` | 140 | Game entry point and title-screen VRAM setup |
| `src/sound/z80/load_data.s` | `$0101D4-$010CD3` | 21 | Z80 music/SFX data banks and load descriptors |
| `src/sound/engine.s` | `$010CD4-$010D6D` | 69 | Sound driver init and note playback |
| `src/rendering/rle.s` | `$010D6E-$010DE7` | 81 | VRAM address helpers and RLE tilemap decompression |
| `src/game/text_encoding.s` | `$010DE8-$010E87` | 89 | Character-to-tile mapping and random numbers |
| `src/system/vblank.s` | `$010E88-$010F23` | 67 | VBlank interrupt handler |
| `src/rendering/text.s` | `$010F24-$01105B` | 178 | Tilemap coordinates, tile writes, string and number drawing |
| `src/game/world.s` | `$01105C-$011673` | 700 | Objects, camera, collision map, level lifecycle |
| `src/game/rules.s` | `$011674-$01190F` | 300 | Score, timer, enemy placement, pair collisions |
| `src/rendering/level_draw.s` | `$011910-$011BC1` | 302 | Ground tilemap construction and background objects |
| `src/rendering/hud.s` | `$011BC2-$011FAF` | 365 | HUD elements, animations, score and label drawing |
| `src/game/screens/front_end.s` | `$011FB0-$0125BD` | 417 | Title and guide screens |
| `src/game/round/select_and_setup.s` | `$0125BE-$012A93` | 268 | Round selection, init, tileset and palette loading |
| `src/game/round/main_loop.s` | `$012A94-$012F2F` | 440 | Main game state machine |
| `src/game/bonus/mode.s` | `$012F30-$01310F` | 164 | Bonus round flow |
| `src/game/screens/ending.s` | `$013110-$0139A1` | 382 | Ending sequence and credits |
| `src/game/screens/attract_mode.s` | `$0139A2-$013E6F` | 101 | Attract-mode demo playback |
| `src/game/actors/player.s` | `$013E70-$0144DB` | 679 | Player object |
| `src/game/actors/chick.s` | `$0144DC-$01483D` | 377 | Exit door and chick objects |
| `src/game/enemies/cat.s` | `$01483E-$014EC5` | 622 | Cat enemy |
| `src/game/enemies/lizard.s` | `$014EC6-$015507` | 603 | Lizard enemy and its animation tables |
| `src/data/level_layout.s` | `$015508-$015D57` | 159 | Level layout and palette data used by round setup |
| `src/game/enemies/snake.s` | `$015D58-$016311` | 492 | Snake enemy |
| `src/game/enemies/spawner.s` | `$016312-$0164EB` | 212 | Enemy spawner and score popups |
| `src/game/bonus/objects.s` | `$0164EC-$016DA9` | 558 | Bonus-round objects |
| `src/game/screens/game_over.s` | `$016DAA-$016E57` | 32 | Game over and time over text |
| `src/data/art.s` | `$016E58-$01A195` | 15 | Level, sprite, score and logo art |
| `src/data/tables.s` | `$01A196-$01FFFF` | 689 | Trailing data tables and the ROM tail |

## Extracted data

Seventeen binary segments are not in the source at all. They are sliced out of
the reference ROM by `make split`, validated against `assets/manifest.json`, and
pulled back in with `binclude` from the modules under `src/data/` and from
`src/system/startup.s`. They are never tracked by this repository.

AS resolves `include` and `binclude` relative to the including file, so modules
under `src/` could not reach `data/` on their own. The build passes the project
root as an include search path (`-i`), which lets every module spell its paths
from the root exactly as the index does.

## Verification baseline

- ROM size: 131,072 bytes
- ROM SHA-1: `83d8bbf0a9b38c42a0bf492d105cc3abe9644a96`
- ROM MD5: `805CC0B3724F041126A57A4D956FD251`
- ROM CRC32: `4291C8AB`
- Padding byte in unused space: `$FF`
- Verification command: `make verify`

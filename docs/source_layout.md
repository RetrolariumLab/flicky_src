# Source Layout

`src/main.s` is not a source file any more: it is the index. It sets the CPU and
assembly options, pulls in the shared definitions, and then includes 43
modules in ROM address order.

AS assembles the whole thing as a single translation unit, so every label stays
global and cross-module branches need no declaration. That also means **the
include order is the ROM layout**. Moving an include moves code in the output
and `make verify` fails immediately.

## Granularity policy

A module owns one coherent subsystem, the helpers only it uses, and the data
those helpers consume. Modules are not split to satisfy a line count: a
procedure is never cut in half, and a small table stays beside the code that
reads it.

Most modules land between 100 and 500 lines. **700 lines is a soft upper
limit**, enforced by `make lint`; today the largest is
689 lines and the mean is 240.

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

`src/sound/z80_driver_z80.asm` is a separate Z80 translation unit rather than
part of the address-ordered 68000 include tree. It assembles to 4,070 bytes,
is checked against the reference driver, and is included by `bank0.s`.

## Source extensions

AS does not assign a language or processor to a filename extension; the `cpu`
directive inside each translation unit does that. This repository uses the
extension to make the two build boundaries visible instead:

- `.s` is an address-ordered 68000 module included by `src/main.s`;
- `.asm` is a standalone sound translation unit assembled in its own pass;
- `.inc` contains shared definitions and emits no bytes by itself.

The distinction is architectural rather than an assembler requirement. It
also prevents a Z80 source from being mistaken for a module that can be moved
inside the 68000 ROM include order.

## Modules

| File | ROM range | Lines | Responsibility |
| --- | --- | ---: | --- |
| `src/system/vectors_and_header.s` | `$000000-$0001FF` | 80 | Exception vector table and ROM header |
| `src/system/boot.s` | `$000200-$000401` | 188 | Reset entry, hardware bring-up, checksum verification |
| `src/system/sega_screen.s` | `$000402-$000855` | 109 | Sega logo screen and its compressed art |
| `src/system/dma.s` | `$000856-$000AD3` | 273 | Game-state init, DMA helpers and VRAM fills |
| `src/compression/nemesis_enigma.s` | `$000AD4-$000DBF` | 446 | Nemesis and Enigma decompressors |
| `src/system/input.s` | `$000DC0-$000E41` | 65 | Joypad initialization and polling |
| `src/rendering/vdp.s` | `$000E42-$001013` | 244 | VDP registers, sprite area, tilemap writes, palette fade |
| `src/sound/z80_driver.s` | `$001014-$001195` | 183 | Z80 bus arbitration and the sound command queue |
| `src/rendering/tilemap.s` | `$001196-$001315` | 175 | Palette and tilemap loading, VRAM and CRAM transfers |
| `src/data/bank0.s` | `$001316-$00FFFF` | 69 | Source-built Z80 driver image, function table, Japanese 1bpp font |
| `src/system/game_entry.s` | `$010000-$0101D3` | 136 | Game entry point and title-screen VRAM setup |
| `src/data/z80_sound.s` | `$0101D4-$010CD3` | 6 | Z80 music/SFX data banks and load descriptors |
| `src/sound/engine.s` | `$010CD4-$010D6D` | 68 | Sound driver init and note playback |
| `src/rendering/rle.s` | `$010D6E-$010DE7` | 81 | VRAM address helpers and RLE tilemap decompression |
| `src/game/text_encoding.s` | `$010DE8-$010E87` | 89 | Character-to-tile mapping and random numbers |
| `src/system/vblank.s` | `$010E88-$010F23` | 67 | VBlank interrupt handler |
| `src/rendering/text.s` | `$010F24-$01105B` | 178 | Tilemap coordinates, tile writes, string and number drawing |
| `src/game/objects.s` | `$01105C-$01130B` | 304 | Object slots, animation, sprite rendering, handler dispatch |
| `src/game/camera_collision.s` | `$01130C-$011421` | 128 | Camera scrolling and the collision map |
| `src/game/level.s` | `$011422-$011673` | 275 | Level init, object spawning, collision queries |
| `src/game/scoring.s` | `$011674-$0117BF` | 163 | Score, timer, cat placement, palette fade-in |
| `src/game/collision_pairs.s` | `$0117C0-$01190F` | 136 | Object-pair collision testing |
| `src/rendering/level_draw.s` | `$011910-$011BC1` | 302 | Ground tilemap construction and background objects |
| `src/rendering/hud.s` | `$011BC2-$011FAF` | 365 | HUD elements, animations, score and label drawing |
| `src/game/title.s` | `$011FB0-$01228D` | 228 | Title screen and its objects |
| `src/game/guide.s` | `$01228E-$0125BD` | 193 | Guide screen |
| `src/game/round_select.s` | `$0125BE-$012655` | 57 | Round select screen |
| `src/game/round_setup.s` | `$012656-$012A93` | 215 | Round init, tileset and palette loading |
| `src/game/main_loop.s` | `$012A94-$012F2F` | 434 | Main game state machine |
| `src/game/bonus.s` | `$012F30-$01310F` | 164 | Bonus round flow |
| `src/game/ending.s` | `$013110-$0139A1` | 382 | Ending sequence and credits |
| `src/game/demo.s` | `$0139A2-$013E6F` | 95 | Attract-mode demo playback |
| `src/game/player.s` | `$013E70-$0144DB` | 679 | Player object |
| `src/game/chick.s` | `$0144DC-$01483D` | 377 | Exit door and chick objects |
| `src/game/cat.s` | `$01483E-$014EC5` | 622 | Cat enemy |
| `src/game/lizard.s` | `$014EC6-$015507` | 603 | Lizard enemy and its animation tables |
| `src/data/level_layout.s` | `$015508-$015D57` | 159 | Level layout and palette data used by round setup |
| `src/game/snake.s` | `$015D58-$016311` | 492 | Snake enemy |
| `src/game/spawner.s` | `$016312-$0164EB` | 212 | Enemy spawner and score popups |
| `src/game/bonus_objects.s` | `$0164EC-$016DA9` | 558 | Bonus-round objects |
| `src/game/game_over.s` | `$016DAA-$016E57` | 32 | Game over and time over text |
| `src/data/art.s` | `$016E58-$01A195` | 15 | Level, sprite, score and logo art |
| `src/data/tables.s` | `$01A196-$01FFFF` | 689 | Trailing data tables and the ROM tail |

## Extracted data

Seventeen binary segments are not in the source at all. They are sliced out of
the reference ROM by `make split`, validated against `assets/manifest.json`, and
pulled back in with `binclude` from the modules under `src/data/` and from
`src/system/sega_screen.s`. They are never tracked by this repository.

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

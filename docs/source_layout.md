# Source Layout

`src/main.s` is not a source file any more: it is the index. It sets the CPU and
assembly options, pulls in the shared definitions, and then includes 36
modules in ROM address order.

AS assembles the whole thing as a single translation unit, so every label stays
global and cross-module branches need no declaration. That also means **the
include order is the ROM layout**. Moving an include moves code in the output
and `make verify` fails immediately.

The address comments in `src/main.s` give each module's place in the
original ROM; the build's listing gives the current ones.

## Granularity policy

A module owns one coherent subsystem, the helpers only it uses, and the data
those helpers consume. The preferred range is **300-700 lines**. A procedure
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
between the Tiger and Iggy code because that is where the data physically is.

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
under `src/sound/z80/driver/` assemble to 4,070 bytes, which `bank0.s`
includes from `build/`.

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
`game/enemies/{tiger,iggy,spawner}.s`, screen modes are under
`game/screens/`, and bonus, round, actor, and Z80 concerns follow the same
pattern. A file inside one directory therefore does not repeat an `enemy_`,
`screen_`, `round_`, or `z80_` prefix. A new repeated prefix calls for a subdirectory or a more specific name.

The Z80 implementation split is independently visible:

| File | Responsibility |
| --- | --- |
| `driver/abi.asm` | Non-emitting hardware and resident-RAM ABI |
| `driver/core.asm` | Reset, timer interrupt, update loop |
| `driver/fm.asm` | FM event, modulation, envelope, voice handling |
| `driver/control.asm` | Sound commands, track startup, pause and fade |
| `driver/mixer.asm` | Reset/silence, priority polling, DAC path |
| `driver/coordination.asm` | Coordination-flag dispatch and handlers |
| `driver/sequencing_psg.asm` | Calls, loops, PSG update and envelopes |

## Modules

| File | Responsibility |
| --- | --- |
| `src/system/startup.s` | Header, reset/boot sequence, Sega screen |
| `src/system/dma.s` | Game-state init, DMA helpers and VRAM fills |
| `src/compression/nemesis_enigma.s` | Nemesis and Enigma decompressors |
| `src/system/input.s` | Joypad initialization and polling |
| `src/rendering/vdp.s` | VDP registers, sprite area, tilemap writes, palette fade |
| `src/sound/z80/host.s` | Z80 bus arbitration and the sound command queue |
| `src/rendering/tilemap.s` | Palette and tilemap loading, VRAM and CRAM transfers |
| `src/data/bank0.s` | Source-built Z80 driver image, function table, Japanese 1bpp font |
| `src/system/game_entry.s` | Game entry point and title-screen VRAM setup |
| `src/sound/z80/load_data.s` | Z80 music/SFX data banks and load descriptors |
| `src/sound/engine.s` | Sound driver init and note playback |
| `src/rendering/rle.s` | VRAM address helpers and RLE tilemap decompression |
| `src/game/text_encoding.s` | Character-to-tile mapping and random numbers |
| `src/system/vblank.s` | VBlank interrupt handler |
| `src/rendering/text.s` | Tilemap coordinates, tile writes, string and number drawing |
| `src/game/world.s` | Objects, camera, collision map, level lifecycle |
| `src/game/rules.s` | Score, timer, enemy placement, pair collisions |
| `src/rendering/level_draw.s` | Ground tilemap construction and background objects |
| `src/rendering/hud.s` | HUD elements, animations, score and label drawing |
| `src/game/screens/front_end.s` | Title and guide screens |
| `src/game/round/select_and_setup.s` | Round selection, init, tileset and palette loading |
| `src/game/round/main_loop.s` | Main game state machine |
| `src/game/bonus/mode.s` | Bonus round flow |
| `src/game/screens/ending.s` | Ending sequence and credits |
| `src/game/screens/attract_mode.s` | Attract-mode demo playback |
| `src/game/actors/player.s` | Player object |
| `src/game/actors/window_girl_and_throwable.s` | Window girl and throwable item objects |
| `src/game/actors/chirp.s` | Chirp rescue actor |
| `src/game/enemies/tiger.s` | Tiger cat and its animation tables |
| `src/data/level_layout.s` | Level layout and palette data used by round setup |
| `src/game/enemies/iggy.s` | Iggy lizard |
| `src/game/enemies/spawner.s` | Enemy spawner and score popups |
| `src/game/bonus/objects.s` | Bonus-round objects |
| `src/game/screens/game_over.s` | Game over and time over text |
| `src/data/art.s` | Level, sprite, score and logo art |
| `src/data/tables.s` | Trailing data tables and the ROM tail |

## Extracted data

`make split` extracts seventeen segments from the ROM and checks them against
`assets/manifest.json`. Fifteen are included directly by the 68000 modules. The
two Z80 segments are the original driver and sound banks; the build assembles
those from source instead, and Retrolarium Kit's Studio build compares its
driver with them. Extracted segments are never tracked by this repository.

AS resolves `include` and `binclude` relative to the including file, so modules
under `src/` could not reach `data/` on their own. The build passes the project
root as an include search path (`-i`), which lets every module spell its paths
from the root exactly as the index does.

## Padding

Unused ROM space is `$FF`; `make verify` compares the whole image.

# Subsystems

`source_layout.md` says where the code is. This page says what it does and who
calls whom, so a change can be scoped without reading the whole ROM.

## The shape of the program

Two things run: a main loop that never returns, and a VBlank handler.

`Sys_MainLoop` reads `Ram_NextGameMode` and jumps through
`Sys_GameModeTable`, eighteen branches covering the title screen, the guide,
round select, the four gameplay phases, the bonus round, the ending, the demo
and the Sega logo. Each mode routine runs one frame's worth of work and
returns; the loop increments `Ram_FrameCounter` and goes round again. A mode
switches by writing a new value to `Ram_NextGameMode`.

`Int_VBlankHandler` reads `Ram_VBlankRequest` and jumps through
`Int_VBlankModeTable`. Mode 0 returns immediately; the others run
`Int_VBlankMain`, which updates the scroll registers, compares the working
palette against its backup and queues a CRAM transfer if they differ.
`Sys_WaitVBlank` is how the main loop hands the frame over: it copies
`Ram_VBlankMode` into `Ram_VBlankRequest` and spins until the handler clears it.

Nearly every routine that wants to advance a frame calls
`j_Sound_QueueSFX` instead of `Sys_WaitVBlank` directly, because that routine
flushes one queued sound effect and then falls into the wait. That is why
`jsr (j_Sound_QueueSFX)` appears throughout the source where a plain frame wait
would be expected.

## Boot

`Boot_EntryPoint` brings up the hardware -- security register, VDP, Z80, PSG, work
RAM, CRAM, VSRAM -- then verifies the cartridge checksum against the value in
the header and jumps to `CheckSumError` if it does not match. `Boot_CheckInitFlag`
tests a magic longword so a soft reset skips the RAM clear. Finally the whole
first 48 KiB of the second bank is copied to work RAM and executed from there,
which is what makes `Sys_GameEntryPoint` at `$10000` the fixed point everything
else is measured from.

`Sys_LoadFuncTable` builds the trampoline block described in
[`ram_fields.md`](ram_fields.md) so the relocated code can still reach the
routines that stayed in the first bank.

## Rendering

| Concern | Where |
| --- | --- |
| VDP register setup, sprite table clear, palette fade | `src/rendering/vdp.s` |
| DMA fills and copies to VRAM and CRAM | `src/system/dma.s` |
| Palette and tilemap loading, bulk VRAM transfers | `src/rendering/tilemap.s` |
| Tilemap coordinates, single tiles, strings, BCD numbers | `src/rendering/text.s` |
| Ground tilemap construction, background objects | `src/rendering/level_draw.s` |
| HUD, animated overlays, score and label drawing | `src/rendering/hud.s` |
| RLE tilemap decompression | `src/rendering/rle.s` |

Sprites are not drawn directly. `Sprite_BuildTable` walks all 32 object slots
once per frame, calls `Sprite_RenderObject` for each live one, and chains the
resulting entries into the sprite attribute table through
`Ram_SpriteTableCursor`. An object contributes nothing by being alive; it
contributes by having a mapping pointer at offset `$C`.

## Objects

`Object_CallHandler` reads an object's type word and jumps through
`Object_HandlerTable`, twenty-two entries covering the player, chick, cat,
lizard, snake, spawner, the popups, the bonus-round actors, the title and
credits actors, the exit door and the two end-of-round texts. Type 0 is the
empty slot and dispatches to `Object_NullHandler`.

`Object_UpdateAll` decides which ranges of slots to walk, and takes a different
route in the bonus round (`Ram_BonusRoundFlag`). Positions are integrated by
`Object_UpdatePosition`, which wraps the world X coordinate into a fixed range
and derives the screen position by subtracting `Ram_CameraX`.

Each actor keeps its state index in offset `$3C` and dispatches through its own
small table -- `Player_StateTable`, `Cat_StateTable`, `Lizard_StateTable`,
`Snake_StateTable` and so on -- so the actors are all built the same way.

## Collision

Two independent mechanisms:

- **Against the level.** `Ram_CollisionMap` is a 32-column byte grid.
  `Collision_GetTileAtPos` converts a world position to a cell;
  `Collision_GetTileAtObject` does the same relative to an object. The low
  nibble is the tile type and the upper bits are flags that
  `Collision_SetSpecialTiles` writes per round.
- **Against other objects.** `Collision_CheckObjectPair` tests two axis-aligned
  boxes taken from `Collision_BoxLeftTable` and its three sibling field bases,
  indexed by object type times eight.

`Level_BuildGroundTilemap` reads the same collision map to choose ground tiles,
picking one of five neighbour patterns depending on which of the four
surrounding cells are solid and whether the column is at a map edge.

## Gameplay flow

`Game_MainLoop` dispatches through `Game_StateTable`: play, round complete,
bonus check, skip-bonus check, next round. The player reaching the exit door
sets `Ram_RoundEndingFlag`, which most actors test and use to freeze
themselves.

Chicks form a chain. Picking one up increments `Ram_ChickChainCount` and stores
the position of the chick in the player's trail buffer
(`Player_RecordHistory` keeps 64 past positions); delivering the chain to the
cat door awards points from `Chick_DeliveryScoreTable`, which scale with chain
length.

Difficulty is a per-round computation. `Game_CalcDifficulty` derives the lizard
chase speed and the snake speed from the round number, and selects a jump arc
from `Lizard_JumpSpeedTable` through the per-round index in
`Lizard_JumpSpeedIndex`.

## Sound

The 68000 never generates audio. It copies two Z80 images into sound RAM at
boot (`LoadZ80Driver`, `Sound_InitDriver`) and afterwards communicates by
writing single bytes: `Z80_MusicCommand` for music, three `Z80_SFXSlot` bytes
for effects, `Z80_PauseFlag` for pause. Every access takes the Z80 bus first
through `Sound_RequestZ80Bus` and releases it afterwards.

`Sound_QueueToBuffer` and `Sound_QueueSFX` implement a small queue so that
effects requested during a frame are emitted one per frame rather than fighting
over the three slots. What the driver does with a command is
[SND-001](unknowns.md).

## Compression

Two formats, both from the Sega house toolset:

- **Nemesis** -- Huffman-coded tile art. `Nem_Decomp` builds a code table into
  `Ram_DecompCodeTable`, then emits rows either straight to the VDP data port
  or into RAM, optionally XOR-ing against the previous row.
- **Enigma** -- run-coded tilemaps. `Eni_Decompress` reads an opcode, dispatches
  through `Eni_OpcodeJumpTable`, and writes runs of incrementing, repeating,
  static or inline tile words.

A third routine in the same module expands 1bpp font data to 4bpp
(`Nem_Decomp1bpp_Begin`), which is unrelated to Nemesis despite sharing the
prefix its callers gave it.

## Data ownership

The per-round appearance of a level is a block of pointers at `$FFD800` that
`Level_LoadTileset` fills from tables indexed by the round number. Six of those
slots are the background object mappings, listed in order by
`Level_BackgroundMappingPointers`. The level's object placement comes from
`Level_DataPointers`, its special collision tiles from
`Level_SpecialTilePointers`, and its palette from `Level_PalettePointers` plus a
four-colour accent set.

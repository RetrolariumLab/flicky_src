# Documentation Index

## Start here

| Document | What it answers |
| --- | --- |
| [`source_layout.md`](source_layout.md) | Where the code lives and why it is split that way |
| [`subsystems.md`](subsystems.md) | What the program does and who calls whom |
| [`build.md`](build.md) | How the build works, what to supply, and what each failure means |
| [`retrolarium.md`](retrolarium.md) | How the game is edited in Retrolarium Studio |

## Working on the source

| Document | What it answers |
| --- | --- |
| [`naming.md`](naming.md) | How to name a symbol, and what to do when you cannot |
| [`assembly_style.md`](assembly_style.md) | The layout rules the formatter enforces |
| [`ram_fields.md`](ram_fields.md) | What every work RAM address is for |
| [`unknowns.md`](unknowns.md) | What is still unresolved, and the experiment that would settle it |
| [`data_formats.md`](data_formats.md) | What each extracted segment is and how well it is understood |
| [`z80_sound_driver.md`](z80_sound_driver.md) | The Z80 sound driver and its data banks |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | The workflow, from a fresh clone to a reviewed change |

## Reading order

For a first pass at the program itself, follow the ROM:

1. `src/system/startup.s` -- hardware bring-up, checksum, relocation to RAM.
2. `src/system/game_entry.s` -- `Sys_MainLoop` and the eighteen-entry mode table.
3. `src/system/vblank.s` -- the other half of the frame.
4. `src/game/world.s` -- the slot array and the object handler table.
5. `src/game/actors/player.s` -- the actor pattern, worked through in full.
6. Any one enemy (`tiger.s`, `iggy.s`) -- the same pattern again.
7. `src/rendering/` -- how any of it reaches the screen.

## The verification rule

After every edit batch run `make test`; among other things `make verify` must
print:

```
[OK] Byte-identical ROM reproduced (SHA1 83d8bbf0a9b38c42a0bf492d105cc3abe9644a96)
```

Annotation, renaming and reformatting must never change the assembled bytes.
Any difference means the edit was wrong, not that the gate is too strict.
`make test-full` also plays both movies in MAME on the packed ROM.

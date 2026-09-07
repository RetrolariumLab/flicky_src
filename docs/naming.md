# Symbol Naming

A symbol names a role in the program, never a location in the ROM. Addresses
belong in the listing, the map file and provenance comments; they must not be
the identity of a live symbol.

`loc_11F2A` tells you nothing except where the disassembler happened to find
something, and it stops being true the moment anything moves. `Title_DrawCast`
survives every rebuild and answers the question you actually had.

## Vocabulary

The reconstruction uses `Category_Detail` in CamelCase. The category is the
subsystem that owns the symbol; the detail says what it is or does.

### Code

| Form | Meaning |
| --- | --- |
| `Category_VerbNoun` | A routine entered with `bsr` or `jsr` and left with `rts` |
| `Owner_Detail` | A branch target inside `Owner`, reached with `bra`/`bcc`/`dbf` |
| `Owner_Return` | A shared `rts` that several paths in `Owner` branch to |
| `Category_HandlerName` | An entry selected through a jump table |
| `Int_Name` | An interrupt or exception entry point |

A branch target is named after the procedure that contains it, so the reader
can see at a glance where a `bra` stays inside the current routine and where it
leaves. That convention is already in the source:

```asm
Nem_PCD_WritePixel:
                ...
Nem_PCD_WritePixel_Loop:
                ...
```

### Data

| Form | Meaning |
| --- | --- |
| `Category_NameTable` | An indexed lookup table |
| `Category_NamePointers` | A table of addresses |
| `Category_NameData` | A block of data reached through a pointer |
| `Category_NameText` | A character string |
| `Ram_Name` | A work RAM field, defined in `src/memory/ram.inc` |
| `Unused_Name` | Code or data proven unreachable in this ROM |

Hardware ports and the Z80 memory map keep their uppercase names in
`src/memory/hardware.inc` (`VDP_CTRL`, `IO_CT1_DATA`, `Z80_RAM`). That casing is
reserved for them, so a register is recognizable anywhere it appears.

## Categories

The categories in use are those the subsystem split already established:

`Sys_` `Int_` `Gfx_` `DMA_` `Nem_` `Eni_` `Input_` `Sound_` `Text_` `Math_`
`Game_` `Level_` `Object_` `Sprite_` `Anim_` `Camera_` `Collision_` `Score_`
`Timer_` `UI_` `Title_` `Guide_` `RoundSelect_` `Demo_` `Bonus_` `Ending_`
`Player_` `Chick_` `Cat_` `Lizard_` `Snake_` `Spawner_` `Enemy_` `Obj_` `Data_`
`Ram_` `Unused_`

Add a category only when an existing one genuinely does not fit.

## Rules

1. Prefer the role over the address: `Player_CheckGround`, never `sub_1407E`.
2. Add subsystem context when a bare description would collide. Two routines
   may both check a wall; only one of them is `Cat_CheckWallCollision`.
3. Keep a number when it is part of a decoded format, such as a state index or
   an opcode. Do not keep it when it is a ROM offset.
4. Record the original name as provenance on the line that defines the symbol:

   ```asm
   Player_CheckGround:  ; was: sub_1407E
   ```

5. A plausible reading is not evidence. If the purpose is unclear, keep a
   neutral name (`Ram_UnknownState03`, `Level_UnidentifiedTable`) and open an
   entry in [`unknowns.md`](unknowns.md) with an evidence tag. An honest
   neutral name is better than a confident wrong one, because the wrong one
   stops anyone from looking again.
6. Every rename must leave the ROM byte-identical. Run `make format` and then
   `make verify` after each batch; `make lint --strict-naming` refuses any
   surviving address-derived identifier.

`make format` belongs in that order because a name is also a width. Label lines
share a column across a run, so renaming one symbol in a table can move the
column for the whole table -- see [`assembly_style.md`](assembly_style.md).

## Tooling

`scripts/workflow/rename_symbols.py` takes a CSV of `old,new` pairs, rewrites every
reference across `src/`. It
refuses to run if a target name already exists, if two renames collide, or if a
source name is not defined anywhere -- so a typo cannot silently do nothing.

```bash
python scripts/run.py workflow.rename_symbols workflow/rename_batch.csv
make format
make verify
```

A rename also changes what `docs/provenance/label_renames.json` should say, and
`make test` fails until it does: the table has to cover the source exactly.

`make lint` checks the vocabulary itself. Every symbol must begin with one of
the categories above, derive from a symbol that exists (`Owner_Detail`,
`Block_End`), or be one of the two named exceptions -- the hardware and
memory-map names in `src/memory/`, and the cartridge header fields, which keep
the names the Mega Drive format gives them.

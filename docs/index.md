# Documentation Index

## Start here

| Document | What it answers |
| --- | --- |
| [`roadmap.md`](roadmap.md) | What this project is for, what is done, what is next |
| [`source_layout.md`](source_layout.md) | Where the code lives and why it is split that way |
| [`subsystems.md`](subsystems.md) | What the program does and who calls whom |
| [`validation.md`](validation.md) | Which check proves what |
| [`source_reconstruction_1_0.md`](source_reconstruction_1_0.md) | What the 1.0 release claims, and what it does not |

## Working on the source

| Document | What it answers |
| --- | --- |
| [`naming.md`](naming.md) | How to name a symbol, and what to do when you cannot |
| [`assembly_style.md`](assembly_style.md) | The layout rules the formatter enforces |
| [`ram_fields.md`](ram_fields.md) | What every work RAM address is for |
| [`unknowns.md`](unknowns.md) | What is still unresolved, and the experiment that would settle it |
| [`data_formats.md`](data_formats.md) | What each extracted segment is and how well it is understood |
| [`debugger_workflow.md`](debugger_workflow.md) | Exporting symbols and using them on a trace |
| [`runtime_evidence.md`](runtime_evidence.md) | The twelve replays, what they observe, and how the dumps are read |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | The workflow, from a fresh clone to a reviewed change |

## Reading order

For a first pass at the program itself, follow the ROM:

1. `src/system/boot.s` -- hardware bring-up, checksum, relocation to RAM.
2. `src/system/game_entry.s` -- `Sys_MainLoop` and the eighteen-entry mode table.
3. `src/system/vblank.s` -- the other half of the frame.
4. `src/game/objects.s` -- the slot array and the object handler table.
5. `src/game/player.s` -- the actor pattern, worked through in full.
6. Any one enemy (`cat.s`, `lizard.s`, `snake.s`) -- the same pattern again.
7. `src/rendering/` -- how any of it reaches the screen.

## The verification rule

After every edit batch:

```bash
make lint
make verify
```

`make verify` must print:

```
[OK] Byte-identical ROM reproduced (SHA1 83d8bbf0a9b38c42a0bf492d105cc3abe9644a96)
```

Annotation, renaming and reformatting must never change the assembled bytes.
Any difference means the edit was wrong, not that the gate is too strict.

## Current status

Source Reconstruction 1.0, all nine milestones complete: the byte-identity
gate compares against the cartridge dump, the source is modular and
consistently styled, every symbol is semantic, the subsystems and the memory
map are documented, the authored data formats have codecs, the symbol map is
exported, twelve scenarios replay under the emulator with 68 checked
expectations about work RAM, and `make release-check` audits the whole
contract.

See [`runtime_evidence.md`](runtime_evidence.md) for what the replays observe
and [`source_reconstruction_1_0.md`](source_reconstruction_1_0.md) for what the
release does and does not claim.

Seven questions are open in [`unknowns.md`](unknowns.md).

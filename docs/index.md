# Documentation Index

## Start here

| Document | What it answers |
| --- | --- |
| [`roadmap.md`](roadmap.md) | What this project is for, what is done, what is next |
| [`source_layout.md`](source_layout.md) | Where the code lives and why it is split that way |
| [`subsystems.md`](subsystems.md) | What the program does and who calls whom |
| [`build.md`](build.md) | How the build works, what to supply, and what each failure means |
| [`content_authoring.md`](content_authoring.md) | How isolated editable builds and the 2.0 studios work |
| [`validation.md`](validation.md) | Which check proves what |
| [`source_reconstruction_1_0.md`](source_reconstruction_1_0.md) | What the 1.0 release claims, and what it does not |
| [`source_reconstruction_2_0.md`](source_reconstruction_2_0.md) | What the 2.0 authoring release adds and how it is accepted |
| [`provenance.md`](provenance.md) | Where every name and every extracted byte came from |
| [`source_reconstruction_2_0.md`](source_reconstruction_2_0.md#draft-history-reconstruction) | How the unpublished Source 2.0 draft maps to the reviewed history |

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

1. `src/system/startup.s` -- hardware bring-up, checksum, relocation to RAM.
2. `src/system/game_entry.s` -- `Sys_MainLoop` and the eighteen-entry mode table.
3. `src/system/vblank.s` -- the other half of the frame.
4. `src/game/world.s` -- the slot array and the object handler table.
5. `src/game/actors/player.s` -- the actor pattern, worked through in full.
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

Source Reconstruction 1.0 is preserved and complete; Source Reconstruction
2.0 is a tag-ready candidate on its release branch. Its aggregate
`make source-2-check`
starts with the permanent 1.0 gate, then verifies relocatability, zero-edit
content identity, all three Studio models, direct level playtesting, sound-
sequencer fidelity, and the machine-readable 2.0 contract.

See [`runtime_evidence.md`](runtime_evidence.md) for what the replays observe,
[`source_reconstruction_1_0.md`](source_reconstruction_1_0.md) for the preserved
base, and [`source_reconstruction_2_0.md`](source_reconstruction_2_0.md) for the
authoring release.

Five entries remain open in [`unknowns.md`](unknowns.md), and three are
resolved. The open entries record four questions about the original program
and the non-byte-exact Nemesis encoder; none is hidden by the 2.0 release
claim.

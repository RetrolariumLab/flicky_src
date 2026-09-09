# 2. Declare the ROM layout instead of relying on include order

**Status:** accepted, 1.0
**Depends on:** [ADR 1](0001-as-assembler.md)

## Context

Choosing AS means there is no linker and no linker script, so the release
contract's `config/linker/` has nothing to hold. The layout lives implicitly in
the include order of `src/main.s`, and it was documented only as a prose table in
`docs/source_layout.md`.

Prose drifts. A module that grows past its neighbour's start address, a
reordered include, a landmark that moves — each of these changes the ROM, and
`make verify` reports them as a byte offset with no name attached. The table
would simply be silently wrong.

There was a live example: the entry point was recorded as `$000200` while
`Boot_EntryPoint` is actually at `$000206`; `Sys_ErrorTrap` occupies the first six bytes.

## Decision

Declare the layout in `config/linker/rom_layout.json` — memory regions, ROM landmarks
by symbol, the padding gap, the shared includes that emit no bytes, and the
address range of all 43 modules — and check it with
`scripts/validation/verify_layout.py` (`make verify-layout`), which is part of the gate.

The three checks read three different ground truths: module ranges come from
the addresses the assembler recorded for each `include` in its listing,
landmarks from the symbol table, and the padding gap from the built image.

## Consequences

A layout change now fails by name: "`src/system/input.s` starts at `0x000DC0`,
the layout declares `0x000DC1`" rather than a raw offset. The `Boot_EntryPoint`
mistake above was caught this way.

The declaration has to be regenerated when the layout legitimately changes, which
is the intended cost: moving a module is a deliberate act and should require
saying so.

`config/linker/rom_layout.json` is recorded in the release manifest as a
`layout_deviation` from the recommended `config/linker/`, with this file as the
equivalent control.

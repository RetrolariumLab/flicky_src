# Assembly Style

The source uses one small, mechanically checked AS style. It is not a new style
imposed on the reconstruction: it is the layout the disassembly already had,
written down so that a tool can enforce it.

The rules exist to keep diffs meaningful. Every formatting change must be
byte-neutral — `make verify` is the arbiter, and a formatting commit that moves
a byte is wrong by definition.

## Characters and file shape

- Printable ASCII only (`0x20`-`0x7E`) plus LF line endings. Non-ASCII text in
  `.s` and `.inc` files is rejected and must be rewritten in English by hand;
  the formatter never translates or deletes it.
- Exactly one final newline. No trailing whitespace. No tabs.
- At most one blank line in a row, and no blank line at the top of a file.

## Layout

- A label starts at column zero and ends with `:`.
- Instructions, directives and data live at **column 17** (16 leading spaces),
  whether they follow a label on the same line or stand alone.

Both label forms are in use and both are correct. A label on its own line marks
an entry point that the following block belongs to; a label sharing its line
with data marks the datum itself.

```asm
Gfx_ClearSpriteArea:
                move.w  #$B000,d2
                moveq   #0,d0

Checksum:       dc.w $B7E0
```

- Inside a `macro` / `endm` block the body is indented one further level.

## Case

- 68000 mnemonics are lowercase: `move.w`, `bsr.w`, `rts`.
- AS directives are lowercase: `dc.b`, `dc.w`, `dc.l`, `binclude`, `org`, `even`.
- Labels, constants and operands keep their declared case.

## Comments

- One space after `;`.
- Exactly two spaces before an inline comment. Inline comments are **not**
  aligned to a shared column: alignment turns an edit to one line into a diff
  across the whole block.
- Prefer comments that explain intent, invariants, state transitions, data
  formats or hardware consequences. A comment that restates the instruction in
  English earns nothing.

```asm
; Clear the sprite attribute table and the sprite bookkeeping variables
Gfx_ClearSpriteArea:
                move.w  #$B000,d2  ; sprite table base in VRAM
```

- A renamed symbol keeps its original disassembly name as provenance on the
  line that defines it:

```asm
Sys_GameEntryPoint:
                move    #$2700,sr  ; was: sub_10000
```

## Procedure contracts

Where a routine's contract is not obvious, record it above the label. Use only
the parts that are actually known:

```asm
; Convert a tilemap coordinate into a VDP write command.
;
; Inputs:
; - d0: tile column
; - d1: tile row
; Outputs:
; - d0: VDP control-port command word
; Clobbers: d2
```

Do not invent inputs, outputs or clobbers to fill in the template. An unknown
belongs in `docs/unknowns.md` with an evidence tag, not in a guessed contract.

## Tooling

Check without modifying anything:

```bash
make lint
```

Apply the deterministic fixes, then re-check:

```bash
make format
```

`make format` only normalizes whitespace, tabs, label layout and directive case.
Semantic names, comments, contracts and data are a review responsibility; the
formatter will not touch them.

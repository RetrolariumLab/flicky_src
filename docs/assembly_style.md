# Assembly Style

The address-ordered 68000 `.s` modules and shared `.inc` files use one small,
mechanically checked AS style. It is not a new style
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

The `.asm` files form the separately assembled Z80/sound-data trees. Their
entrypoints and included implementation modules follow the same ASCII, LF and
whitespace hygiene, but retain their processor-specific table layout and are
not rewritten by `make format`.

## Layout

Four columns, and every one of them is on an eight-column grid:

| Column | What sits there |
| ---: | --- |
| 0 | Labels, and the names in `equ`, `set` and `macro` definitions |
| 16 | The mnemonic or directive |
| 24 | Its operand |
| 56 | Inline comments |

```asm
Gfx_ClearSpriteArea:
                move.w  #$B000,d2                       ; sprite table base
                moveq   #0,d0
```

A mnemonic that fills the field keeps a single space rather than pushing its
operand out of line: `movea.l d1,a6`, not `movea.l  d1,a6`.

### Why those columns, and why spaces

They are the Sonic disassembly layout, which is what a Mega Drive reader
expects. `s1_improvements/sonic.asm` writes it with tabs: two of them before
4,793 of its statement lines, one between the mnemonic and the operand 4,012
times, and one after every label that carries a directive. At the tab width
that layout assumes, that is column 16, column 24 and column 16 -- the three
columns above. The width is not a guess: only 51 mnemonics in that file
overflow an eight-column field, against 3,352 that overflow a four-column one.

This project renders the same columns with spaces. The picture is identical at
a tab width of 8 and stays identical at every other width, which a tabbed file
does not -- at width 4 the operand lands in column 12. `alien_soldier_src`, the
closest Mega Drive sibling to this reconstruction, makes the same choice, and
`.editorconfig`, `.gitattributes` and `make lint` all enforce it.

The one place this parts company with Sonic is the comment column. There a tab
after the operand puts the comment wherever the operand's length leaves it --
37, 44, 39, 47, with only 125 of 1,240 landing on a multiple of eight. Here it
is fixed, which is worth more now than it would have been: the provenance table
took the inline comment count from 1,838 down to 57, so what is left is
commentary rather than bookkeeping.

Both label forms are in use and both are correct. A label on its own line marks
an entry point that the following block belongs to; a label sharing its line
with a directive marks the datum itself.

### Where a shared column comes from

A label that carries a directive does not simply pad to column 16 -- most
labels here are longer than that. Instead, **a run of consecutive label lines
shares one column**, the first tab stop that clears the longest name in the
run:

```asm
Z80_CommandBlock:               equ     $A01C04         ; was: unk_A01C04
Z80_MusicCommand:               equ     $A01C09         ; was: byte_A01C09
Z80_SFXSlot0:                   equ     $A01C0A         ; was: byte_A01C0A
```

That is what makes `src/memory/ram.inc` read as a table of 194 addresses rather
than as a column that steps between 16 and 24 line by line.

A run is broken by a blank line, a comment or an instruction, so a long data
label cannot drag an unrelated table to the right. A **bare label is
transparent**: `src/data/art.s` alternates `Name: binclude ...` with `Name_End:`,
and treating those end markers as separators would leave every include in a run
of its own.

- Inside a `macro` / `endm` block the body is indented one further level.

## Case

- 68000 mnemonics are lowercase: `move.w`, `bsr.w`, `rts`.
- AS directives are lowercase: `dc.b`, `dc.w`, `dc.l`, `binclude`, `org`, `even`.
- Labels, constants and operands keep their declared case.

## Comments

- One space after `;`, and no period ending a comment.
- Inline comments start at **column 56**. A line whose code already reaches
  that column keeps two spaces and simply sticks out -- the alternative is
  letting one long data table row push every comment in the file to the right.
- A whole-line comment is indented in multiples of four.
- A banner of repeated `;`, `-` or `=` is left exactly as written.
- Prefer comments that explain intent, invariants, state transitions, data
  formats or hardware consequences. A comment that restates the instruction in
  English earns nothing.

```asm
; Clear the sprite attribute table and the sprite bookkeeping variables
Gfx_ClearSpriteArea:
                move.w  #$B000,d2                       ; sprite table base
```

- A renamed symbol keeps its original disassembly name as provenance on the
  line that defines it:

```asm
Sys_GameEntryPoint:
                move    #$2700,sr                       ; was: sub_10000
```

A renamed label keeps its marker on the label line rather than above it, and
the comment column applies there like anywhere else:

```asm
Game_MainLoop_PostFrame:                                ; was: loc_12B5E
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

`make format` normalizes whitespace, tabs, label and comment columns, and the
one comment detail it is allowed to rewrite: the space after `;` and a trailing
period. Semantic names, comment *content*, contracts and data are a review
responsibility; the formatter will not touch them.

Two invariants make the formatter safe to run on the whole tree:

- **It never changes the line count.** Formatting is whitespace and comment
  text; adding or dropping a line would mean it is rewriting the program.
- **It never reflows an operand.** Collapsing whitespace inside one once
  rewrote the ROM header and moved 48,105 bytes, so the operand is copied
  verbatim. The comment splitter is quote-aware for the same reason: the source
  contains `dc.b "; 250 PTS.=      PTS.",0`, and splitting on the first
  semicolon would turn that string into a comment.

`make verify` is the arbiter either way. Reformatting all 47 sources for this
style left the ROM byte-identical.

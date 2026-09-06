# 3. Base runtime evidence on work RAM, not on screenshots

**Status:** accepted, 1.0
**Supersedes:** the frame-hash-only validator that shipped with the declared
scenarios

## Context

The runtime layer began as a capture that replayed the two movies and compared
screenshots against a reference directory. With no reference tracked, it
degraded to counting frames and printing `no reference to compare` — a liveness
check that proves the emulator started, and nothing about the game.

Committing a reference capture would have made it meaningful, but at a cost:
hundreds of megabytes of PNGs in git, invalidated by any emulator change, and a
failure mode that says "frame 001360 differs" without saying what differs.

## Decision

Assert values of 68000 work RAM instead. Each scenario declares fields that must
`hold` across its whole frame range or be `reached` inside it, resolved through
the symbols in `src/memory/ram.inc` rather than written as addresses. Frame
comparison remains available behind `--reference-dir` for anyone who wants it.

## Consequences

A failure names the field, the frame and the value found:
"`Ram_Score` should hold `$00022560` ... but is `$00022561` at frame 1460".

Because expectations name symbols, a rename that misses `ram.inc` breaks the
scenarios loudly instead of silently reading the wrong memory.

The captures stay small. Only the declared window is kept, which took a full
capture from 1.2 GB to 113 MB.

Rendering is covered only where it reaches memory. A palette or sprite-layout
regression that never touches an asserted field will pass — recorded in the
release manifest as the excluded `frame_image_comparison`.

Reading the dumps required establishing that Gens stores work RAM as host-endian
16-bit words, so the bytes of every word are swapped. `scripts/genstate.py`
undoes it, and `Ram_InitFlag` — which spells the ASCII `init` only after the
swap — is the check that settles whether a reader has it right.

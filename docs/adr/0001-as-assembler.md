# 1. Assemble with AS, not a modern toolchain

**Status:** accepted, 1.0
**Supersedes:** nothing

## Context

The reconstruction has to reassemble into the cartridge image byte for byte. The
choice of assembler is therefore not a matter of taste: it decides which
encodings are reachable, how `dc.b` padding and alignment behave, and whether
the same source produces the same bytes on another machine years from now.

Three options were live. The sibling NES projects in this family use **ca65**,
which is 6502-only and cannot assemble 68000 at all. **vasm** is maintained and
pleasant, but Mega Drive disassemblies are not written against it, and its
optimisation defaults differ from what this source was disassembled from.
**AS** (Alfred Arnold's macro assembler) is what `s1_improvements`,
`s2_improvements`, `sk_improvements` and `alien_soldier_src` all use, vendoring
the same binaries.

## Decision

Vendor AS 1.42 Beta [Bld 212] and the Sonic-disassembly `p2bin`, under
`bin/<platform>/`, and assemble the whole project as a single translation unit.

`p2bin` is invoked with `-p=FF`. This is not a detail: the cartridge pads unused
space with `$FF`, and p2bin's default of `$00` corrupts 18,015 bytes in the
middle of the image.

## Consequences

The project inherits the Mega Drive disassembly convention, so a reader coming
from any Sonic disassembly is immediately at home, and the encodings the
original assembler produced are reachable.

There is no linker. AS emits one object and `p2bin` flattens it, so nothing owns
the memory layout the way a linker script would — the include order in
`flicky.s` *is* the layout. That gap is filled deliberately by
[ADR 2](0002-rom-layout-contract.md).

Vendoring binaries makes the build reproducible from a fresh clone but puts
executables in the repository. They are general-purpose tools containing no game
code, hashed in `config/toolchain.json` and checked by `make verify-toolchain`
before they are ever run.

macOS is not covered: no `bin/macos_*` is vendored, and the Makefile's autodetect
will look for a directory that does not exist.

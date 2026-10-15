# Building

```bash
make verify
```

That is the whole thing, once the inputs are in place. It assembles the source,
converts it to a flat image and requires that image to equal the cartridge dump
byte for byte. Anything less than equal is a failure with the first differing
offset printed.

## What you have to supply

Two things are never in this repository, because both are the game.

**The cartridge dump**, `Flicky (UE) [!].bin`, in the project root. Its identity
is recorded in `assets/manifest.json`:

| | |
| --- | --- |
| Size | 131,072 bytes |
| SHA-1 | `83d8bbf0a9b38c42a0bf492d105cc3abe9644a96` |
| MD5 | `805CC0B3724F041126A57A4D956FD251` |
| CRC32 | `4291C8AB` |

**The extracted data segments** under `data/`. They come out of that dump:

```bash
make init      # validate the dump, extract the segments, build and verify
```

`make init` is the one-command setup. `make split` re-extracts on its own, and
it is the only command that ever writes to `data/`; ordinary builds only read.
`make check-assets` re-checks every segment against the manifest without
touching anything, and both `build` and `verify` depend on it, so a corrupted
segment fails by name rather than as a mysterious byte difference.

## The pipeline

```text
src/main.s ──[asw]──> build/main.p ──[p2bin -p=FF]──> fbuilt.bin ──[compare]──> the dump
```

**Assembling.** `src/main.s` includes 36 modules in ROM address order and AS
assembles all of it as a single translation unit, so every label is global and
cross-module branches need no declaration. Includes are written relative to `src/main.s`; the `-i <project root>` flag is
what lets a module under `src/` reach `data/` with `binclude`, since AS would
otherwise resolve that relative to the module's own directory.

**Converting.** `p2bin` flattens the object into the cartridge image. The
`-p=FF` is not optional: the cartridge pads unused space with `$FF` and p2bin
defaults to `$00`, which would corrupt 18,015 bytes in the middle of the image.
The converter writes a temporary sibling first and replaces the destination
atomically only after successful conversion, preserving a prior valid ROM when
the converter fails or is interrupted.

**Comparing.** `scripts/validation/compare_roms.py` compares the result with the dump byte
by byte and reports the first difference. A matching hash is not accepted as a
substitute.

## The toolchain

The build runs AS and `p2bin` as Retrolarium Kit builds and ships them, from the
kit's `megadrive` suite: `AS_BIN` and `P2BIN` default to
`$(RLTOOL) build-tools path megadrive asl` (and `p2bin`), with `RLTOOL` naming
the kit command (default `rltool`). AS reads its message catalogs from beside
the assembler (`AS_MSGPATH`). The kit has builds for Windows and Linux x86-64;
this repository holds no executables.

`make verify-toolchain` hashes the kit's files against `config/toolchain.json`,
and `build` and `verify` both depend on it. This runs *before* the assembler, so
a swapped binary is named as the problem instead of surfacing as an unexplained
diff.

`p2bin` must be invoked with `-p=FF`. The original cartridge pads unused ROM
space with `$FF`; p2bin's default of `$00` produces a ROM that differs from the
reference in every gap, 73,045 bytes of the 128 KiB image. The padding byte is
recorded in `assets/manifest.json` and applied by `scripts/build/build_rom.py`.

Source Reconstruction 1.0 and 2.0 vendored AS 1.42 Beta [Bld 212] and `p2bin`
under `bin/<platform>/`, with their provenance in `bin/README.md`. Those files
remain at the tags `source-reconstruction-1.0` and `source-reconstruction-2.0`,
where the 2.0 audits still run them.

`AS_BIN` and `P2BIN` can point at another filesystem location, but they do not
waive identity checks. The verifier resolves and hashes the exact executable
paths selected by those variables before every assembly or conversion target,
including standalone Z80 builds and listing generation.

## Why AS and p2bin

Byte identity makes the assembler an architectural choice rather than a matter
of taste: it determines which encodings are reachable and how data directives,
alignment, and padding behave. ca65 cannot assemble 68000 code. vasm is actively
maintained, but the established Mega Drive disassembly syntax targets AS and its
optimization defaults differ from the source this project inherited.

The project therefore builds with AS 1.42 Beta [Bld 212] and the
Sonic-disassembly variant of Clownacy's `p2bin` at commit
`e26d8aa8c43e285bac5e3b7df3be1adae515994f`. The whole 68000 program is one
translation unit, while the Z80 program and data are separate checked
translation units. Exact executable origins, sizes, and SHA-256 values live in
`config/toolchain.json`; alternate `AS_BIN` and `P2BIN` paths must match those
approved identities before use.

The converter always receives `-p=FF`, because its `$00` default would corrupt
the cartridge's 18,015-byte `$FF` padding gap. AS emits one object and `p2bin`
flattens it, so there is no linker script: include order owns placement and
`config/linker/rom_layout.json` supplies the independently checked layout
contract. Vendoring the tools makes supported clean builds self-contained but
leaves macOS unsupported because no matching binary set is provided.

## What gets written

Everything generated is disposable and ignored by git:

| Path | What it is |
| --- | --- |
| `build/main.p` | AS object file |
| `build/main.lst` | AS listing, the source of the symbol map and the layout check |
| `fbuilt.bin` | The assembled ROM |
| `build/` | Symbol map, format round-trip results, runtime captures, summaries |

`make clean` removes only resolved, project-approved generated paths, including
the build tree and Python caches below the tooling and test trees. It never
selects a directory merely because it is named `tmp`, so ignored local content
such as `content/workspace/tmp` survives. Nothing in a release depends on a
generated artifact surviving, which prevents stale output from masking a
regression without putting user work at risk.

## When the build disagrees

The failure tells you which layer to look at.

**`make verify-toolchain` fails.** The assembler the kit (or `AS_BIN`) names is
not the one this release was built with. Use the kit release the manifest
records rather than re-recording the hash, unless you are deliberately changing
toolchain, in which case `config/toolchain.json` and the release manifest change
with it.

**`make check-assets` fails.** A segment under `data/` does not match the
manifest. Re-run `make split` against the correct dump.

**The assembler reports an error.** Ordinary source problem; the listing gives
the file and line. `AS_ARGS` defaults to `-maxerrors 2` to keep the output
short.

**`make verify` reports a differing offset.** The source now assembles to
something else. Find the module owning that address in
`config/linker/rom_layout.json` -- or run `make verify-layout`, which reports a moved
module by name instead of by offset.

**`make verify-layout` fails but `make verify` passes.** The layout declaration
is stale rather than the build being wrong. That happens when a module
legitimately changes size; update `config/linker/rom_layout.json` deliberately, which
is the intended cost of moving code. See the rationale in
[`source_layout.md`](source_layout.md#why-the-layout-is-machine-readable).

## The checks

`make test` runs the unit tests, `verify`, `verify-layout`,
`verify-relocation` and the studio check, in about a minute. `make test-full`
then plays the longplay in MAME on the packed ROM, whose game code starts at
`$00290A` instead of `$010000`, and compares the game's state at seven
checkpoints with what the original ROM gives
(`movies/flicky_longplay.check.json`, recorded by `make golden`).

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

## Choosing a toolchain

The assembler is vendored under `bin/<platform>/` so a fresh clone can build
without hunting for a matching release. The Makefile picks the directory from
the host:

| Host | Directory | Assembler |
| --- | --- | --- |
| Windows | `bin/windows_i386` | `asw.exe`, `p2bin.exe` |
| Linux x86-64 | `bin/linux_x86_64` | `asl`, `p2bin` |

Override with `make PLATFORM=<subdirectory>`. macOS has no vendored directory,
so the autodetect will look for one that does not exist.

`make verify-toolchain` hashes those files against `config/toolchain.json`, and
`build` and `verify` both depend on it. This runs *before* the assembler, so a
swapped binary is named as the problem instead of surfacing as an unexplained
diff. See [`bin/README.md`](../bin/README.md) for the provenance and
the rationale below for why AS remains part of the build contract.

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

The project therefore vendors AS 1.42 Beta [Bld 212] and the Sonic-disassembly
variant of Clownacy's `p2bin` at commit
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
selects a directory merely because it is named `tmp`, so ignored editor content
such as `content/workspace/tmp` survives. Nothing in a release depends on a
generated artifact surviving, which prevents stale output from masking a
regression without putting user work at risk.

## When the build disagrees

The failure tells you which layer to look at.

**`make verify-toolchain` fails.** The vendored assembler is not the one this
release was built with. Restore it rather than re-recording the hash, unless you
are deliberately changing toolchain, in which case `config/toolchain.json` and
the release manifest change with it.

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

## The full gate

```bash
make release-check
```

runs `verify-toolchain`, `check-assets`, `lint`, `test`, `roundtrip-formats`,
`verify`, `verify-layout`, `symbols`, `trace` and `release-audit`, in that
order, cheapest first. It takes a few minutes, most of it in `trace`, which
replays 67,000 frames under the emulator. See
[`validation.md`](validation.md) for what each layer can and cannot tell you.

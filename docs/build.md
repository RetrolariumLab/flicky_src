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
flicky.s ──[asw]──> flicky.p ──[p2bin -p=FF]──> fbuilt.bin ──[compare]──> the dump
```

**Assembling.** `flicky.s` includes 43 modules in ROM address order and AS
assembles all of it as a single translation unit, so every label is global and
cross-module branches need no declaration. The `-i <project root>` flag lets a
module under `src/` resolve its `binclude` paths from the repository root rather
than from its own directory.

**Converting.** `p2bin` flattens the object into the cartridge image. The
`-p=FF` is not optional: the cartridge pads unused space with `$FF` and p2bin
defaults to `$00`, which would corrupt 18,015 bytes in the middle of the image.

**Comparing.** `scripts/compare_roms.py` compares the result with the dump byte
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
[ADR 1](adr/0001-as-assembler.md) for why AS.

## What gets written

Everything generated is disposable and ignored by git:

| Path | What it is |
| --- | --- |
| `flicky.p` | AS object file |
| `flicky.lst` | AS listing, the source of the symbol map and the layout check |
| `fbuilt.bin` | The assembled ROM |
| `build/` | Symbol map, format round-trip results, runtime captures, summaries |

`make clean` removes them. Nothing in a release depends on anything surviving
there, which is deliberate: a stale artifact must not be able to mask a
regression.

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
`config/rom_layout.json` -- or run `make verify-layout`, which reports a moved
module by name instead of by offset.

**`make verify-layout` fails but `make verify` passes.** The layout declaration
is stale rather than the build being wrong. That happens when a module
legitimately changes size; update `config/rom_layout.json` deliberately, which
is the intended cost of moving code. See
[ADR 2](adr/0002-rom-layout-contract.md).

## The full gate

```bash
make release-check
```

runs `verify-toolchain`, `check-assets`, `lint`, `test`, `roundtrip-formats`,
`verify`, `verify-layout`, `symbols`, `trace` and `release-audit`, in that
order, cheapest first. It takes about thirteen minutes, almost all of it in
`trace`, which replays 67,000 frames under the emulator. See
[`validation.md`](validation.md) for what each layer can and cannot tell you.

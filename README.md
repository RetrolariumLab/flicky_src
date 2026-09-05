# Flicky (Sega Mega Drive) Disassembly

An annotated reconstruction of Flicky for the Sega Mega Drive, plus the tooling
that rebuilds the ROM and compares it byte for byte against the original
cartridge dump.

The source assembles with the AS Macro Assembler, which is vendored in `bin/`.
Approaches are shared with the sibling
[alien_soldier_src](https://github.com/oranguthang/alien_soldier_src) project.

## Status

The build reproduces the reference ROM exactly, verified against the dump
itself. `flicky.s` is no longer a source file: it is an index of 43
address-ordered modules, and every symbol in them says what it is for -- there
are no disassembler-generated names left anywhere in the source.

Milestones 0 through 4 are complete. Data round trips, debugger symbols,
runtime evidence and the automated release audit are planned; see
[`docs/roadmap.md`](docs/roadmap.md).

The gate for every change is `make verify`. Annotating, renaming and
reformatting must never alter the assembled bytes, so any difference means the
edit was wrong.

## Quick start

```bash
git clone <repo>
cd flicky_src

# Place a legally obtained original ROM in the project root:
#   Flicky (UE) [!].bin   SHA-1 83d8bbf0a9b38c42a0bf492d105cc3abe9644a96

make init           # Validate the ROM, extract data, build and verify
make verify         # The permanent gate
```

A successful verify prints:

```
[OK] Byte-identical ROM reproduced (SHA1 83d8bbf0a9b38c42a0bf492d105cc3abe9644a96)
```

The ROM is never tracked by this repository and is not distributed with it.
Neither is anything extracted from it.

## Project structure

```text
flicky_src/
|-- assets/
|   `-- manifest.json       # Reference ROM identity and per-segment SHA-1
|-- bin/                    # Vendored AS toolchain, one folder per platform
|   |-- windows_i386/       # asw.exe, p2bin.exe, message catalogs
|   |-- linux_x86_64/       # asl, p2bin, message catalogs
|   `-- README.md           # Provenance, hashes, why -p=FF matters
|-- data/                   # Extracted binary segments (ignored, from make split)
|-- docs/                   # See docs/index.md
|-- movies/                 # Gens input recordings and their scene indexes
|-- scripts/                # Build, validation and analysis tooling
|-- src/
|   |-- compression/        # Nemesis and Enigma decompressors
|   |-- data/               # Binary includes and the large data tables
|   |-- game/               # Modes, actors, collision, scoring
|   |-- macros/             # Alignment pseudo-instructions
|   |-- memory/             # Hardware ports, constants, work RAM map
|   |-- rendering/          # VDP, tilemaps, text, HUD, level drawing
|   |-- sound/              # Z80 bus handling and the command queue
|   `-- system/             # Boot, entry point, interrupts, DMA, input
|-- tools/                  # C and Python decompressors
|-- flicky.s                # Address-ordered include index
`-- Makefile
```

## Make targets

```bash
make init           # Validate the ROM, extract data, build and verify
make build          # Assemble; a mismatch is reported as a warning
make verify         # Assemble; a mismatch fails the build (the gate)
make compare        # Compare an existing build without reassembling
make check-assets   # Validate data/ against assets/manifest.json
make split          # Re-extract data segments (the only writer of data/)
make lint           # Style, naming, documentation and evidence checks
make format         # Apply the deterministic fixes, then lint
make tools          # Build the C decompressors
make unpack-data    # Decompress the Nemesis and Enigma segments
make clean          # Remove build artifacts; extracted data is kept
make help           # Everything, including the analysis workflow
```

The toolchain folder is chosen from the host platform; override it with
`make PLATFORM=linux_x86_64`.

`make split` is deliberately explicit and destructive, and `make build` never
touches `data/`. That asymmetry means locally modified assets survive a
rebuild.

## Working flow

1. Find the owning module with [`docs/source_layout.md`](docs/source_layout.md)
   and its callers with [`docs/subsystems.md`](docs/subsystems.md).
2. Make the change, then run `make format`, `make lint` and `make verify`.
3. If something cannot be named with confidence, give it a neutral name and
   open an entry in [`docs/unknowns.md`](docs/unknowns.md).

Full workflow in [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Analysis workflow

Automated procedure analysis stubs a routine with an early return, rebuilds and
diffs emulator screenshots against a reference capture. It needs the
instrumented Gens build from
[gens_automation](https://github.com/oranguthang/gens_automation) as a sibling
checkout.

```bash
make build-gens                 # Clone and build it into ../gens_automation
make reference MOVIE=longplay   # Capture the reference frames
make find-unanalyzed            # List procedures still to analyze
make analyze MOVIE=longplay     # Stub and diff
make report MOVIE=longplay      # Build the report
```

`MOVIE` is `longplay` or `demos`; see [`movies/README.md`](movies/README.md).

## Game information

| | |
|---|---|
| **Title** | FLICKY |
| **Platform** | Sega Mega Drive / Genesis |
| **Release** | February 1991 |
| **Product code** | GM 00001022-00 |
| **ROM size** | 128 KB |
| **Regions** | Japan, USA, Europe |

Bit 7 of the version register selects the domestic revision, so the ROM carries
two sets of on-screen text: Japanese for Japan and English elsewhere. Symbols
for the Japanese variants carry a `JP` suffix.

## Known gaps

- **`Sys_GameEntryPoint` must stay at `$10000`.** The Z80 sound data contains
  pointer offsets that assume it, and the build does not recompute them.
  Inserting padding before that address shifts the code without shifting the
  data and the game hangs. Tracked as DATA-001 in
  [`docs/unknowns.md`](docs/unknowns.md).
- **The Z80 sound driver is not disassembled.** Both images are copied verbatim
  and the 68000 side only writes command bytes. Tracked as SND-001.
- **No data round trips yet.** The Nemesis and Enigma formats can be decoded
  but not re-encoded, so there is no proof yet that a decoded segment can be put
  back exactly. See [`docs/data_formats.md`](docs/data_formats.md).
- Five further open questions are listed in
  [`docs/unknowns.md`](docs/unknowns.md).

## Credits

- Approaches shared with [alien_soldier_src](https://github.com/oranguthang/alien_soldier_src)
- AS Macro Assembler by Alfred Arnold
- Original game by Sega

## License

Reverse engineering for educational and preservation purposes. No original ROM
data is distributed with this repository. The original game is copyright Sega.

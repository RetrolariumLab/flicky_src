# Flicky (Sega Mega Drive) Disassembly

An annotated reconstruction of Flicky for the Sega Mega Drive, plus the tooling
that rebuilds the ROM and compares it byte for byte against the original
cartridge dump.

The source assembles with the AS Macro Assembler, which is vendored in `bin/`.
Approaches are shared with the sibling
[alien_soldier_src](https://github.com/oranguthang/alien_soldier_src) project.

## Status

The build reproduces the reference ROM exactly, verified against the dump
itself. `src/main.s` is an index of 36 address-ordered modules. The source uses
semantic names, with uncertain interpretations recorded in
[`docs/unknowns.md`](docs/unknowns.md).

Source Reconstruction 1.0 and 2.0 are tagged. Source 2.0 adds isolated Level,
Graphics, and Sound studios. The project includes data-format codecs, exports a
symbol map for debuggers, and replays twelve scenarios under the emulator
against 68 declared facts about work RAM. `make release-check` audits the 1.0
contract; `make source-2-check` also runs the 2.0 acceptance checks. See
[`docs/source_reconstruction_1_0.md`](docs/source_reconstruction_1_0.md) and
[`docs/source_reconstruction_2_0.md`](docs/source_reconstruction_2_0.md) for
the release scopes and limitations.

The gate for every change is `make verify`. Annotating, renaming and
reformatting must never alter the assembled bytes, so any difference means the
edit was wrong.

## Quick start

```bash
git clone https://github.com/oranguthang/flicky_src.git
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
|-- config/                 # Build, authoring, runtime, and release contracts
|   |-- authoring/          # Studio inventory and editable data formats
|   |-- debugger/           # Symbol-resolved breakpoints and watches
|   |-- linker/             # ROM map, landmarks, padding gap, module ranges
|   |-- reconstruction/     # 300-700-line source policy and exceptions
|   |-- runtime/            # Emulator capture configuration
|   |-- toolchain.json      # Toolchain hashes, pins, and supported hosts
|   |-- source_reconstruction_1_0.json
|   `-- source_reconstruction_2_0.json
|-- data/                   # Extracted reference segments (ignored, from make split)
|-- docs/                   # Task-oriented guides; see docs/index.md
|-- movies/                 # Gens input recordings and their scene indexes
|-- scenarios/              # Runtime scenarios and their state expectations
|-- scripts/                # Categorized tooling, dispatched by run.py
|   |-- authoring/          # Content models, studios, and native preview support
|   |-- build/              # Assembly, extraction and housekeeping
|   |-- formats/            # Shared Nemesis and Enigma Python codecs
|   |-- runtime/            # Emulator capture and state validation
|   |-- validation/         # Static, binary and release gates
|   `-- workflow/           # Reverse-engineering maintenance tools
|-- tests/                  # Tests mirroring authoring/runtime/validation
|-- src/
|   |-- compression/        # Nemesis and Enigma decompressors
|   |-- data/               # Binary includes and the large data tables
|   |-- game/               # World/rules plus actors, enemies, rounds, screens
|   |-- macros/             # Alignment pseudo-instructions
|   |-- memory/             # Hardware ports, constants, work RAM map
|   |-- rendering/          # VDP, tilemaps, text, HUD, level drawing
|   |-- sound/              # 68000 host plus modular Z80 driver and sound data
|   |-- system/             # Boot, entry point, interrupts, DMA, input
|   `-- main.s              # Address-ordered include index, the entrypoint
|-- mk/                     # Authoring, runtime, validation, workflow recipes
`-- Makefile                # Public interface and build primitives
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
make unpack-data    # Decompress the Nemesis and Enigma segments
make clean          # Remove build artifacts; extracted data is kept
make help           # Everything, including the analysis workflow

make test           # Unit tests for the Python tooling
make roundtrip-formats   # Decode and re-encode the authored data
make symbols        # Export build/main.sym for debuggers
make verify-toolchain  # Hash-check the selected build tools before they run
make verify-emulator   # Check the selected Gens executable and source revision
make verify-layout     # Check the ROM layout against config/linker/rom_layout.json
make verify-relocation # Check sound loads in a packed ROM layout
make z80-check         # Assemble and byte-check the resident Z80 driver
make z80-data-check    # Assemble and byte-check the Z80 sound banks
make check-source-structure # Enforce 300-700 lines, justified exceptions, paths
make release-check  # The 1.0 acceptance gate

make init-content              # Initialize the ignored editor workspace
make build-content             # Build an isolated editable ROM
make check-content-zero-edit   # Prove editable baseline byte identity
make level-studio              # Open the visual level editor
make graphics-studio           # Open the visual graphics editor
make sound-studio              # Open the music and SFX editor
make preview-sound SOUND=zMusic81Header  # Render standalone VGM and WAV audio
make verify-sound-sequencer    # Compare Python YM2612 writes with the real Z80 driver
make check-studios             # Validate Studio models without opening GUI
make smoke-studios-workstation # Exercise real Tk windows and public Studio actions
make source-2-audit            # Check the Source 2.0 manifest
make source-2-check            # Complete 1.0 + 2.0 acceptance gate
make source-2-pre-tag-check    # Clean-tree check before creating the tag
make source-2-tag-check        # Verify the annotated tag at HEAD
```

The toolchain folder is chosen from the host platform; override it with
`make PLATFORM=linux_x86_64`.

`make split` is deliberately explicit and destructive, and `make build` never
touches `data/`. That asymmetry means locally modified assets survive a
rebuild. The extracted Z80 segments remain byte-exact references; the driver
and SFX/music banks are assembled from source into separate build files.

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
checkout; `make build-gens` cross-compiles it in Docker, so Visual Studio is
optional. The command reads the exact source revision from
`config/toolchain.json`: it checks out that revision for a new clone and rejects
an existing checkout at any other revision before compiling. Every public
capture and playtest also verifies the resolved `GENS_EXE` against the approved
binary hash before launch.
The cross-build sets the PE timestamp and checksum recorded in the manifest so
rebuilding the same source reproduces that approved binary hash.

The same sibling build contains a Z80 sound-port tracer. `make trace-sound`
captures the title music into `build/sound_trace/`, using an isolated sound-on
configuration rather than modifying the user's `Gens.cfg`.

```bash
make build-gens                 # Check out the pinned revision and cross-build in Docker
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

- **Nemesis does not re-encode byte for byte.** Eight of the seventeen extracted
  segments round-trip exactly, including Enigma; the six Nemesis streams
  round-trip semantically with smaller valid encodings. Tracked as DATA-002; see
  [`docs/data_formats.md`](docs/data_formats.md).
- **The runtime layer checks state, not pixels.** The twelve replays assert
  declared values of work RAM, which catches a game that diverges; comparing
  screenshots needs a reference capture, and none is tracked. See
  [`docs/runtime_evidence.md`](docs/runtime_evidence.md).
- Four further open questions are listed in
  [`docs/unknowns.md`](docs/unknowns.md).

The former fixed-address sound limitation is resolved in Source 2.0:
`make verify-relocation` packs the ROM without its layout gaps and checks the
recomputed Z80 data sources. See DATA-001 in
[`docs/unknowns.md`](docs/unknowns.md).

## Credits

- Approaches shared with [alien_soldier_src](https://github.com/oranguthang/alien_soldier_src)
- AS Macro Assembler by Alfred Arnold
- Original game by Sega

## License

Reverse engineering for educational and preservation purposes. No original ROM
data is distributed with this repository. The original game is copyright Sega.

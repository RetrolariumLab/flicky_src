# Flicky (Genesis) Disassembly

Disassembly of Flicky for Sega Genesis/Mega Drive. The source assembles with the AS Macro Assembler to produce a byte-accurate ROM.

This project is based on approaches from [alien_soldier_src](https://github.com/oranguthang/alien_soldier_src).

**AS Assembler**: http://john.ccac.rwth-aachen.de:8000/as/index.html

## Build Status

- ✅ **Byte-accurate assembly verified** - ROM matches original perfectly
- 📁 `flicky.bin` - Original ROM (128 KB)
- 🔨 `fbuilt.bin` - Assembled ROM from source

## Project Structure

```
flicky_src/
├── bin/                    # Assembler tools
│   ├── asw.exe            # AS Macro Assembler 1.42 Beta
│   ├── p2bin.exe          # Object to binary converter
│   └── *.msg              # Assembler message catalogs
├── data/                   # Binary data segments (14 files)
│   ├── data_*Tiles.bin    # Graphics tiles (SEGA logo, levels, sprites)
│   ├── data_z80_*.bin     # Z80 sound driver code
│   ├── data_*.bin         # Data tables and lookup arrays
│   └── data_addrs.txt     # Addresses for ROM extraction
├── scripts/                # Python build and analysis tools
├── src/                    # Include files
│   ├── macros.inc         # Assembler macros
│   ├── ports.inc          # Hardware I/O port definitions
│   ├── equals.inc         # Constants and equates
│   └── ram_addrs.inc      # RAM address definitions
├── workflow/               # Documentation workflow state
├── flicky.s                # Main disassembled source (~10k lines)
├── flicky.bin              # Original ROM for comparison
└── Makefile                # Build system
```

## Make Targets

### Basic Commands

```bash
make build          # Assemble source → fbuilt.bin
make compare        # Compare built ROM with original
make split          # Extract binary data from original ROM
make clean          # Remove all build artifacts
make symbols        # Extract symbols from listing file
make help           # Show all available targets
```

### Analysis Workflow

Automated procedure analysis using emulator screenshots:

```bash
make reference MOVIE=longplay   # Generate reference screenshots
make find-unanalyzed            # Find procedures needing analysis
make analyze MOVIE=longplay     # Run automated analysis
make report MOVIE=longplay      # Generate analysis report
```

### Documentation Workflow

Semi-automated procedure naming with Claude AI:

```bash
make set-movie MOVIE=longplay   # Set movie type for session
make prepare-batch COUNT=40     # Prepare batch of procedures
# → Claude reads workflow/batch_procedures.txt
# → Claude creates workflow/rename_batch.csv
make rename                     # Apply renames to source
make build && make compare      # Verify ROM unchanged
```

### Utility Commands

```bash
make show-movie     # Display current movie setting
make stop           # Kill running Gens emulator instances
make build-gens     # Build modified Gens emulator (VS2022)
```

## Scripts

| Script | Purpose |
|--------|---------|
| `build_rom.py` | Orchestrates ROM assembly (AS → p2bin) |
| `compare_roms.py` | Binary comparison of built vs original ROM |
| `split_data_from_rom.py` | Extracts binary data segments from ROM |
| `clean_project.py` | Cross-platform cleanup of build artifacts |
| `extract_symbols.py` | Extracts symbols from AS listing file |
| `find_unnamed_procedures.py` | Lists procedures still named `sub_*`, `loc_*` |
| `prepare_batch.py` | Prepares batch of procedures for documentation |
| `rename_procedures.py` | Applies rename CSV to source file |
| `analyze_procedures.py` | Automated procedure analysis with emulator |
| `generate_analysis_report.py` | Generates report from analysis data |

## How to Build

### Prerequisites

- Python 3.x
- Make (Git Bash / WSL on Windows)
- AS Macro Assembler (included in `bin/`)

### Building

```bash
git clone <repo>
cd flicky_src
# Add original ROM as flicky.bin
make build
make compare    # Verify byte-accurate match
```

### Extracting Data from ROM

```bash
make split      # Creates data/*.bin from flicky.bin
```

## Game Information

| | |
|---|---|
| **Title** | FLICKY |
| **Platform** | Sega Mega Drive / Genesis |
| **Release** | February 1991 |
| **Product Code** | GM 00001022-00 |
| **ROM Size** | 128 KB |
| **Regions** | Japan, USA, Europe (JUE) |

## Known Issues

### Pointer Hardcoding at $10000

When adding padding before `Sys_GameEntryPoint` (address $10000), the game freezes in certain places. This is caused by hardcoded pointer offsets in `data/data_z80_part2.bin` that don't get recalculated when the ROM layout shifts.

The code in `Sound_LoadZ80Table` uses `suba.l #Sys_GameEntryPoint,a0` to convert offsets, but the offsets stored in the binary data file remain unchanged.

**Workaround**: Keep `Sys_GameEntryPoint` at exactly $10000.

## Credits

- Based on approaches from [alien_soldier_src](https://github.com/oranguthang/alien_soldier_src)
- AS Macro Assembler by Alfred Arnold
- Original game by Sega (1984/1991)

## License

This is a work of reverse engineering for educational and preservation purposes. The original game is copyright Sega.

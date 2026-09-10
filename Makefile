# Flicky (Sega Mega Drive) build system.
#
# The Makefile holds only thin entrypoints; all platform-specific logic lives
# in the Python scripts under scripts/. The permanent gate is "make verify",
# which requires the build to reproduce the reference ROM byte for byte.

PYTHON ?= python
PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# Toolchain selection: detect the host OS/arch and pick the matching folder
# under bin/. Override with: make PLATFORM=<subfolder>
ifeq ($(OS),Windows_NT)
    PLATFORM ?= windows_i386
    AS_EXE = asw.exe
    P2BIN_EXE = p2bin.exe
else
    UNAME_S := $(shell uname -s)
    UNAME_M := $(shell uname -m)
    ifeq ($(UNAME_S),Darwin)
        PLATFORM ?= macos_$(UNAME_M)
    else
        PLATFORM ?= linux_$(UNAME_M)
    endif
    AS_EXE = asl
    P2BIN_EXE = p2bin
endif

TOOLS_DIR ?= bin/$(PLATFORM)
AS_BIN ?= $(TOOLS_DIR)/$(AS_EXE)
P2BIN ?= $(TOOLS_DIR)/$(P2BIN_EXE)
AS_ARGS ?= -maxerrors 2

# AS looks for as.msg, cmdarg.msg and ioerrs.msg here.
export AS_MSGPATH = $(TOOLS_DIR)

# Sources and outputs
SRC ?= src/main.s
OBJ ?= build/main.p
ROM ?= fbuilt.bin
ORIGINAL_ROM ?= Flicky (UE) [!].bin
ASSET_MANIFEST ?= assets/manifest.json
DATA_DIR ?= data
DATA_ADDRS ?= $(DATA_DIR)/data_addrs.txt
SCRIPTS_DIR ?= scripts
RUN_SCRIPT ?= $(SCRIPTS_DIR)/run.py
DATA_FORMAT_MANIFEST ?= config/authoring/data_formats.json
DATA_FORMAT_SUMMARY ?= build/data_formats.json
DEBUG_BREAKPOINTS ?= config/debugger/breakpoints.json
DEBUG_WATCHES ?= config/debugger/watches.json
SYMBOL_FILE ?= build/main.sym
DEBUG_SUMMARY ?= build/debug_symbols.json
RUNTIME_SCENARIOS ?= scenarios/runtime_scenarios.json
RUNTIME_DIR ?= build/runtime
RUNTIME_SUMMARY ?= build/runtime_scenarios.json
RELEASE_CONTRACT ?= config/source_reconstruction_1_0.json
SOURCE_2_MANIFEST ?= config/source_reconstruction_2_0.json
TOOLCHAIN_MANIFEST ?= config/toolchain.json
TOOLCHAIN_EXECUTABLES = --require-executable "assembler=$(AS_BIN)" --require-executable "binary_converter=$(P2BIN)"
EMULATOR_EXECUTABLE = --require-executable "emulator=$(GENS_EXE)"
ROM_LAYOUT ?= config/linker/rom_layout.json
SOURCE_STRUCTURE ?= config/reconstruction/source_structure.json
LISTING ?= build/main.lst
M68K_SOURCE_FILES := $(shell $(PYTHON) -c "from pathlib import Path; print(' '.join(p.as_posix() for p in Path('src').rglob('*') if p.suffix in {'.s', '.inc'}))")
Z80_SOURCE ?= src/sound/z80/driver.asm
Z80_DRIVER_MODULES := $(wildcard src/sound/z80/driver/*.asm)
Z80_OBJ ?= build/z80_driver.p
Z80_BIN ?= build/z80_driver.bin
Z80_REFERENCE ?= data/sound/data_z80_part1.bin
Z80_DATA_SOURCE ?= src/sound/z80/data.asm
Z80_DATA_OBJ ?= build/z80_sound_data.p
Z80_DATA_BIN ?= build/z80_sound_data.bin
Z80_DATA_REFERENCE ?= data/sound/data_z80_part2.bin
CONTENT_MANIFEST ?= config/authoring/content_studios.json
CONTENT_WORKSPACE ?= content/workspace
CONTENT_LEVEL_WORKSPACE ?= $(CONTENT_WORKSPACE)/level/levels.json
CONTENT_GRAPHICS_WORKSPACE ?= $(CONTENT_WORKSPACE)/graphics/graphics.json
CONTENT_SEMANTICS_WORKSPACE ?= $(CONTENT_WORKSPACE)/graphics/semantics.json
CONTENT_SEQUENCES_WORKSPACE ?= $(CONTENT_WORKSPACE)/graphics/sequences.json
CONTENT_SOUND_WORKSPACE ?= $(CONTENT_WORKSPACE)/sound/z80_sound_data.asm
CONTENT_ROM ?= build/content/flicky.bin
YMFM_RENDERER ?= bin/windows_i386/ymfm_renderer.exe
SOUND ?= zMusic81Header
SOUND_SECONDS ?= 30
SOUND_TRACE_CONFIG ?= config/runtime/gens_sound_trace.cfg
SOUND_TRACE_FILE ?= build/sound_trace/gens.csv
SOUND_TRACE_FRAMES ?= build/sound_trace/frames

# Emulator: a sibling checkout, like fceux_automation in the NES projects.
GENS_DIR ?= ../gens_automation
GENS_EXE ?= $(GENS_DIR)/Output/Gens.exe
# Its Docker cross-build, which needs no Visual Studio. Override both to build
# with MSBuild instead: GENS_MAKEFILE=Makefile GENS_TARGET=release
GENS_MAKEFILE ?= Makefile.docker
GENS_TARGET ?= win-i386

# Analysis configuration
WORKFLOW_DIR ?= workflow
MOVIE_FILE_longplay = movies/flicky_longplay.gmv
MOVIE_FILE_demos = movies/flicky_demos.gmv
MAX_FRAMES_longplay = 67000
MAX_FRAMES_demos = 0
ANALYSIS_WORKERS ?= 24
ANALYSIS_GRID_COLS ?= 6
ANALYSIS_FRAMESKIP ?= 8
ANALYSIS_INTERVAL ?= 20
ANALYSIS_MAX_DIFFS ?= 10
ANALYSIS_DIFF_COLOR ?= pink
PROCEDURES_FILE = $(WORKFLOW_DIR)/unanalyzed_procedures.txt
BATCH_COUNT ?= 40

# Milestone 3 removed every address-derived identifier, so the linter now
# refuses any that come back.
STRICT_NAMING ?= --strict-naming

MAKE_FRAGMENTS := mk/authoring.mk mk/runtime.mk mk/validation.mk mk/workflow.mk

include $(MAKE_FRAGMENTS)

.DEFAULT_GOAL := build

.PHONY: all build verify z80-check z80-data-check verify-toolchain verify-emulator verify-layout verify-relocation check-source-structure init split check-assets \
        compare lint format format-check scaffold-check unpack-data \
        roundtrip-formats symbols trace trace-runtime validate-runtime \
        init-content inspect-content validate-content build-content check-content-zero-edit level-studio playtest-level smoke-level-playtest graphics-studio sound-studio preview-sound trace-sound verify-sound-sequencer check-studios smoke-studios-workstation \
        test release-audit release-check source-2-audit source-2-release-audit source-2-check source-2-pre-tag-check source-2-tag-check clean \
        reference analyze find-unanalyzed report set-movie show-movie \
        prepare-batch rename build-gens build-ymfm-renderer stop help \
        _require-assets _require-movie _require-toolchain _require-emulator

all: build

# ---------------------------------------------------------------------------
# Build and verification
# ---------------------------------------------------------------------------

# Assemble and report byte identity as a warning.
build: _require-toolchain _require-assets $(Z80_BIN) $(Z80_DATA_BIN)
	@$(PYTHON) $(RUN_SCRIPT) build.build_rom \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--manifest $(ASSET_MANIFEST) --original-rom "$(ORIGINAL_ROM)" \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# The permanent gate: any difference from the reference ROM fails the build.
verify: _require-toolchain _require-assets $(Z80_BIN) $(Z80_DATA_BIN)
	@$(PYTHON) $(RUN_SCRIPT) build.build_rom \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--manifest $(ASSET_MANIFEST) --original-rom "$(ORIGINAL_ROM)" \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)" \
		--verify

$(Z80_BIN): $(Z80_SOURCE) $(Z80_DRIVER_MODULES) $(RUN_SCRIPT) $(SCRIPTS_DIR)/build/build_z80_driver.py $(Z80_REFERENCE) | _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) build.build_z80_driver \
		--source $(Z80_SOURCE) --obj $(Z80_OBJ) --output $(Z80_BIN) \
		--reference $(Z80_REFERENCE) --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)"

z80-check: $(Z80_BIN)

$(Z80_DATA_BIN): $(Z80_DATA_SOURCE) $(RUN_SCRIPT) $(SCRIPTS_DIR)/build/build_z80_driver.py $(Z80_DATA_REFERENCE) | _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) build.build_z80_driver \
		--source $(Z80_DATA_SOURCE) --obj $(Z80_DATA_OBJ) --output $(Z80_DATA_BIN) \
		--reference $(Z80_DATA_REFERENCE) --reference-offset 12 \
		--description "Z80 sound-data banks" --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)"

z80-data-check: $(Z80_DATA_BIN)

# Validate the reference ROM, extract data, then build and verify.
init: _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) build.init_project \
		--orig-rom "$(ORIGINAL_ROM)" --manifest $(ASSET_MANIFEST) \
		--data-dir $(DATA_DIR) --data-addrs $(DATA_ADDRS) \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# Extract binary segments from the reference ROM. This is the only command
# that overwrites data/; ordinary builds never touch it.
split:
	@$(PYTHON) $(RUN_SCRIPT) build.split_data_from_rom \
		--rom-file "$(ORIGINAL_ROM)" --output $(DATA_DIR) --addrs $(DATA_ADDRS)

check-assets:
	@$(PYTHON) $(RUN_SCRIPT) build.check_assets \
		--manifest $(ASSET_MANIFEST) --asset-dir $(DATA_DIR)

_require-assets:
	@$(PYTHON) $(RUN_SCRIPT) build.check_assets \
		--manifest $(ASSET_MANIFEST) --asset-dir $(DATA_DIR)

# The assembler is checked before it is used, not after the ROM disagrees.
verify-toolchain:
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_toolchain --config $(TOOLCHAIN_MANIFEST) $(TOOLCHAIN_EXECUTABLES)

_require-toolchain:
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_toolchain --config $(TOOLCHAIN_MANIFEST) $(TOOLCHAIN_EXECUTABLES)

# ---------------------------------------------------------------------------
# Data tools
# ---------------------------------------------------------------------------

unpack-data:
	@$(PYTHON) $(RUN_SCRIPT) build.unpack_data --data-dir $(DATA_DIR) -v

# Decode every authored segment and check it round-trips as declared.
roundtrip-formats: _require-assets
	@$(PYTHON) $(RUN_SCRIPT) authoring.data_formats 		--manifest $(DATA_FORMAT_MANIFEST) --data-dir $(DATA_DIR) 		--summary $(DATA_FORMAT_SUMMARY)

clean:
	@$(PYTHON) $(RUN_SCRIPT) build.clean_project


# ---------------------------------------------------------------------------

help:
	@echo "Flicky (Sega Mega Drive) build system"
	@echo ""
	@echo "Setup:"
	@echo "  make init                      Validate the reference ROM, extract data, verify"
	@echo "  make split                     Re-extract data segments (overwrites data/)"
	@echo "  make check-assets              Validate data/ against assets/manifest.json"
	@echo ""
	@echo "Build:"
	@echo "  make build                     Assemble; report byte identity as a warning"
	@echo "  make verify                    Assemble; require byte identity (the gate)"
	@echo "  make z80-check                 Assemble and byte-check the Z80 sound driver"
	@echo "  make z80-data-check            Assemble and byte-check the Z80 sound banks"
	@echo "  make compare                   Compare an existing build without reassembling"
	@echo "  make clean                     Remove build artifacts"
	@echo ""
	@echo "Content authoring:"
	@echo "  make init-content              Initialize missing files in $(CONTENT_WORKSPACE)"
	@echo "  make inspect-content           Show which workspace artifacts are edited"
	@echo "  make validate-content          Validate the editable workspace"
	@echo "  make build-content             Build the isolated editable ROM"
	@echo "  make check-content-zero-edit   Prove tracked content still reproduces the ROM"
	@echo "  make level-studio              Open the visual level editor"
	@echo "  make playtest-level ROUND=1    Build and play one round directly in Gens"
	@echo "  make smoke-level-playtest      Prove direct round entry in Gens"
	@echo "  make graphics-studio           Open the visual graphics editor"
	@echo "  make sound-studio              Open the music and SFX editor"
	@echo "  make preview-sound SOUND=zMusic81Header  Render a song/SFX to VGM and WAV"
	@echo "  make trace-sound               Capture the real Z80 chip-register stream"
	@echo "  make verify-sound-sequencer    Compare Python playback with Gens"
	@echo "  make check-studios             Load Studio models without opening a GUI"
	@echo "  make smoke-studios-workstation Exercise real Tk windows and public actions"
	@echo ""
	@echo "Validation:"
	@echo "  make verify-toolchain          Hash-check the selected build tools"
	@echo "  make verify-emulator           Check the selected Gens binary and checkout"
	@echo "  make verify-layout             Check the ROM layout contract"
	@echo "  make verify-relocation         Pack the ROM and check relocatable sound loads"
	@echo "  make lint                      Style, naming and repository checks"
	@echo "  make format                    Apply the deterministic fixes, then lint"
	@echo "  make format-check              Check formatting without changing files"
	@echo "  make scaffold-check            Static checks that need no private ROM"
	@echo "  make test                      Unit tests for the Python tooling"
	@echo "  make release-audit             Check the 1.0 release contract"
	@echo "  make release-check             The complete acceptance gate"
	@echo "  make source-2-audit            Check the Source 2.0 manifest"
	@echo "  make source-2-check            Run 1.0 plus every Source 2.0 gate"
	@echo "  make source-2-pre-tag-check    Validate a clean tag-ready release commit"
	@echo "  make source-2-tag-check        Validate the annotated release tag at HEAD"
	@echo ""
	@echo "Data tools:"
	@echo "  make unpack-data               Decompress Nemesis/Enigma segments"
	@echo "  make roundtrip-formats         Decode and re-encode the authored data"
	@echo "  make symbols                   Export $(SYMBOL_FILE) for debuggers"
	@echo "  make trace                     Capture and validate runtime scenarios"
	@echo "  make validate-runtime          Re-check an existing capture"
	@echo ""
	@echo "Analysis (MOVIE=longplay|demos):"
	@echo "  make reference MOVIE=longplay  Capture reference screenshots and dumps"
	@echo "  make find-unanalyzed           List procedures still to analyze"
	@echo "  make analyze MOVIE=longplay    Stub procedures and diff against reference"
	@echo "  make report MOVIE=longplay     Build the analysis report"
	@echo ""
	@echo "Documentation workflow:"
	@echo "  make set-movie MOVIE=longplay  Select the movie for this session"
	@echo "  make prepare-batch COUNT=40    Prepare a batch of procedures to name"
	@echo "  make rename                    Apply workflow/rename_batch.csv"
	@echo ""
	@echo "Emulator:"
	@echo "  make build-gens                Build the manifest-pinned Gens revision in Docker"
	@echo "  make build-ymfm-renderer       Rebuild the standalone VGM-to-WAV helper"
	@echo "  make stop                      Kill running emulator processes"
	@echo ""
	@echo "Toolchain: $(TOOLS_DIR)  (override with PLATFORM=<subfolder>)"

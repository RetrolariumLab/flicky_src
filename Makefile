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
DATA_FORMAT_MANIFEST ?= config/data_formats.json
DATA_FORMAT_SUMMARY ?= build/data_formats.json
DEBUG_BREAKPOINTS ?= config/debugger_breakpoints.json
DEBUG_WATCHES ?= config/debugger_watches.json
SYMBOL_FILE ?= build/main.sym
DEBUG_SUMMARY ?= build/debug_symbols.json
RUNTIME_SCENARIOS ?= scenarios/runtime_scenarios.json
RUNTIME_DIR ?= build/runtime
RUNTIME_SUMMARY ?= build/runtime_scenarios.json
RELEASE_CONTRACT ?= config/source_reconstruction_1_0.json
SOURCE_2_MANIFEST ?= config/source_reconstruction_2_0.json
TOOLCHAIN_MANIFEST ?= config/toolchain.json
ROM_LAYOUT ?= config/rom_layout.json
SOURCE_STRUCTURE ?= config/source_structure.json
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
CONTENT_MANIFEST ?= config/content_studios.json
CONTENT_WORKSPACE ?= content/workspace
CONTENT_ROM ?= build/content/flicky.bin

# Emulator: a sibling checkout, like fceux_automation in the NES projects.
GENS_DIR ?= ../gens_automation
GENS_EXE ?= $(GENS_DIR)/Output/Gens.exe
GENS_REPO ?= https://github.com/oranguthang/gens_automation.git
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

.DEFAULT_GOAL := build

.PHONY: all build verify z80-check z80-data-check verify-toolchain verify-layout verify-relocation check-source-structure init split check-assets \
        compare lint format tools unpack-data \
        roundtrip-formats symbols trace trace-runtime validate-runtime \
        init-content inspect-content validate-content build-content check-content-zero-edit level-studio graphics-studio sound-studio check-studios \
        test release-audit release-check source-2-audit source-2-release-audit source-2-check clean \
        reference analyze find-unanalyzed report set-movie show-movie \
        prepare-batch rename build-gens stop help \
        _require-assets _require-movie _require-toolchain

all: build

# ---------------------------------------------------------------------------
# Build and verification
# ---------------------------------------------------------------------------

# Assemble and report byte identity as a warning.
build: $(Z80_BIN) $(Z80_DATA_BIN) _require-assets _require-toolchain
	@$(PYTHON) $(SCRIPTS_DIR)/build_rom.py \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--manifest $(ASSET_MANIFEST) --original-rom "$(ORIGINAL_ROM)" \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# The permanent gate: any difference from the reference ROM fails the build.
verify: $(Z80_BIN) $(Z80_DATA_BIN) _require-assets _require-toolchain
	@$(PYTHON) $(SCRIPTS_DIR)/build_rom.py \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--manifest $(ASSET_MANIFEST) --original-rom "$(ORIGINAL_ROM)" \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)" \
		--verify

$(Z80_BIN): $(Z80_SOURCE) $(Z80_DRIVER_MODULES) $(SCRIPTS_DIR)/build_z80_driver.py $(Z80_REFERENCE)
	@$(PYTHON) $(SCRIPTS_DIR)/build_z80_driver.py \
		--source $(Z80_SOURCE) --obj $(Z80_OBJ) --output $(Z80_BIN) \
		--reference $(Z80_REFERENCE) --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)"

z80-check: $(Z80_BIN)

$(Z80_DATA_BIN): $(Z80_DATA_SOURCE) $(SCRIPTS_DIR)/build_z80_driver.py $(Z80_DATA_REFERENCE)
	@$(PYTHON) $(SCRIPTS_DIR)/build_z80_driver.py \
		--source $(Z80_DATA_SOURCE) --obj $(Z80_DATA_OBJ) --output $(Z80_DATA_BIN) \
		--reference $(Z80_DATA_REFERENCE) --reference-offset 12 \
		--description "Z80 sound-data banks" --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)"

z80-data-check: $(Z80_DATA_BIN)

# ---------------------------------------------------------------------------
# Isolated content authoring
# ---------------------------------------------------------------------------

# Initialize only missing workspace files. Existing edits are never replaced;
# use FORCE=true only when intentionally resetting them to tracked baselines.
init-content:
	@$(PYTHON) $(SCRIPTS_DIR)/content_workspace.py init \
		--manifest $(CONTENT_MANIFEST) $(if $(filter true,$(FORCE)),--force,)

inspect-content:
	@$(PYTHON) $(SCRIPTS_DIR)/content_workspace.py inspect \
		--manifest $(CONTENT_MANIFEST)

validate-content:
	@$(PYTHON) $(SCRIPTS_DIR)/content_workspace.py validate \
		--manifest $(CONTENT_MANIFEST)

# Editable builds have their own generated source tree and ROM. The strict
# preservation artifacts used by make verify are neither read nor overwritten.
build-content: init-content _require-assets _require-toolchain
	@$(PYTHON) $(SCRIPTS_DIR)/build_content.py \
		--manifest $(CONTENT_MANIFEST) --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)" --original-rom "$(ORIGINAL_ROM)" \
		--asset-manifest $(ASSET_MANIFEST)

# The release gate builds directly from tracked baselines, so a developer's
# current workspace may remain edited while preservation compatibility runs.
check-content-zero-edit: _require-assets _require-toolchain
	@$(PYTHON) $(SCRIPTS_DIR)/build_content.py --zero-edit \
		--manifest $(CONTENT_MANIFEST) --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)" --original-rom "$(ORIGINAL_ROM)" \
		--asset-manifest $(ASSET_MANIFEST)

level-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/level_studio.py

graphics-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/graphics_studio.py

sound-studio: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/sound_studio.py

check-studios: init-content
	@$(PYTHON) $(SCRIPTS_DIR)/level_studio.py --check
	@$(PYTHON) $(SCRIPTS_DIR)/graphics_studio.py --check
	@$(PYTHON) $(SCRIPTS_DIR)/sound_studio.py --check

# Validate the reference ROM, extract data, then build and verify.
init:
	@$(PYTHON) $(SCRIPTS_DIR)/init_project.py \
		--orig-rom "$(ORIGINAL_ROM)" --manifest $(ASSET_MANIFEST) \
		--data-dir $(DATA_DIR) --data-addrs $(DATA_ADDRS) \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# Extract binary segments from the reference ROM. This is the only command
# that overwrites data/; ordinary builds never touch it.
split:
	@$(PYTHON) $(SCRIPTS_DIR)/split_data_from_rom.py \
		--rom-file "$(ORIGINAL_ROM)" --output $(DATA_DIR) --addrs $(DATA_ADDRS)

check-assets:
	@$(PYTHON) $(SCRIPTS_DIR)/check_assets.py \
		--manifest $(ASSET_MANIFEST) --asset-dir $(DATA_DIR)

_require-assets:
	@$(PYTHON) $(SCRIPTS_DIR)/check_assets.py \
		--manifest $(ASSET_MANIFEST) --asset-dir $(DATA_DIR)

# The assembler is checked before it is used, not after the ROM disagrees.
verify-toolchain:
	@$(PYTHON) $(SCRIPTS_DIR)/verify_toolchain.py --config $(TOOLCHAIN_MANIFEST)

_require-toolchain:
	@$(PYTHON) $(SCRIPTS_DIR)/verify_toolchain.py --config $(TOOLCHAIN_MANIFEST)

# AS has no linker, so the include order in src/main.s is the ROM layout itself.
# This makes that layout a declaration the build has to agree with. It reads the
# listing for the module addresses, so it has to depend on one being there.
verify-layout: $(LISTING)
	@$(PYTHON) $(SCRIPTS_DIR)/verify_layout.py \
		--layout $(ROM_LAYOUT) --listing $(LISTING) --rom $(ROM)

verify-relocation: $(Z80_BIN) $(Z80_DATA_BIN) _require-assets _require-toolchain
	@$(PYTHON) $(SCRIPTS_DIR)/verify_relocation.py \
		--source $(SRC) --sound-data $(Z80_DATA_BIN) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# Compare an existing build without reassembling.
compare:
	@$(PYTHON) $(SCRIPTS_DIR)/compare_roms.py \
		--built $(ROM) --original "$(ORIGINAL_ROM)" --manifest $(ASSET_MANIFEST)

# Listing file, used by extract_data_addrs.py and the debugger workflow.
# -i lets modules under src/ resolve their binclude paths from the project root.
$(LISTING): $(M68K_SOURCE_FILES) $(Z80_BIN) $(Z80_DATA_BIN)
	@$(PYTHON) -c "from pathlib import Path; Path('$(dir $@)').mkdir(parents=True, exist_ok=True)"
	@$(AS_BIN) -i . -L -olist $@ -o $(OBJ) $(AS_ARGS) $(SRC)

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

# Style, semantic source invariants, and repository-wide checks. None of these
# substitute for "make verify": a green lint says nothing about byte identity.
lint:
	@$(PYTHON) $(SCRIPTS_DIR)/asm_style.py src
	@$(PYTHON) $(SCRIPTS_DIR)/lint_source.py $(STRICT_NAMING)
	@$(PYTHON) $(SCRIPTS_DIR)/check_source_structure.py --config $(SOURCE_STRUCTURE)
	@$(PYTHON) $(SCRIPTS_DIR)/lint_project.py

check-source-structure:
	@$(PYTHON) $(SCRIPTS_DIR)/check_source_structure.py --config $(SOURCE_STRUCTURE)

# Focused unit tests for the Python tooling, so a bug in a check cannot
# quietly pass everything it is supposed to catch.
test:
	@$(PYTHON) -m unittest discover -s tests -p "test_*.py"

# Check the repository against the machine-readable release contract.
release-audit:
	@$(PYTHON) $(SCRIPTS_DIR)/release_audit.py --contract $(RELEASE_CONTRACT)

# The complete acceptance gate, in increasing cost. Recursive $(MAKE) calls
# keep the order explicit even under a parallel build.
release-check:
	$(MAKE) verify-toolchain
	$(MAKE) check-assets
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) roundtrip-formats
	$(MAKE) verify
	$(MAKE) verify-layout
	$(MAKE) symbols
	$(MAKE) trace
	$(MAKE) release-audit

source-2-audit:
	@$(PYTHON) $(SCRIPTS_DIR)/source_2_audit.py --manifest $(SOURCE_2_MANIFEST)

source-2-release-audit:
	@$(PYTHON) $(SCRIPTS_DIR)/source_2_audit.py --manifest $(SOURCE_2_MANIFEST) --require-ready

source-2-check:
	$(MAKE) release-check
	$(MAKE) verify-relocation
	$(MAKE) check-content-zero-edit
	$(MAKE) validate-content
	$(MAKE) check-studios
	$(MAKE) source-2-release-audit

# Deterministic whitespace, label-layout and case normalization, then re-check.
# Formatting must never move a byte, so verify afterwards.
format:
	@$(PYTHON) $(SCRIPTS_DIR)/asm_style.py src --fix
	@$(MAKE) lint

# ---------------------------------------------------------------------------
# Data tools
# ---------------------------------------------------------------------------

tools:
	@$(MAKE) -C tools all

unpack-data:
	@$(PYTHON) $(SCRIPTS_DIR)/unpack_data.py --data-dir $(DATA_DIR) -v

# Decode every authored segment and check it round-trips as declared.
roundtrip-formats: _require-assets
	@$(PYTHON) $(SCRIPTS_DIR)/data_formats.py 		--manifest $(DATA_FORMAT_MANIFEST) --data-dir $(DATA_DIR) 		--summary $(DATA_FORMAT_SUMMARY)

clean:
	@$(PYTHON) $(SCRIPTS_DIR)/clean_project.py

# Export the symbol map and resolve the debugger configs against it.
symbols: $(LISTING)
	@$(PYTHON) $(SCRIPTS_DIR)/debug_symbols.py 		--listing $(LISTING) 		--breakpoints $(DEBUG_BREAKPOINTS) --watches $(DEBUG_WATCHES) 		--sym $(SYMBOL_FILE) --summary $(DEBUG_SUMMARY)

# ---------------------------------------------------------------------------
# Emulator analysis (requires MOVIE=longplay|demos)
# ---------------------------------------------------------------------------

_require-movie:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required. Use MOVIE=longplay or MOVIE=demos."
	@exit 1
endif

# Generate reference screenshots and memory dumps from a known-good ROM.
reference: _require-movie
	@$(PYTHON) -c "import os; os.makedirs('reference/$(MOVIE)', exist_ok=True)"
	"$(GENS_EXE)" \
		-rom $(ROM) \
		-play $(MOVIE_FILE_$(MOVIE)) \
		-screenshot-interval $(ANALYSIS_INTERVAL) \
		-screenshot-dir reference/$(MOVIE) \
		$(if $(MAX_FRAMES_$(MOVIE)),-max-frames $(MAX_FRAMES_$(MOVIE)),) \
		-save-state-dumps -turbo -frameskip 0 -nosound

# Stub each procedure with an early RTS and diff the result against the
# reference capture. MEMORY=true also records memory diffs.
analyze: _require-movie
	@$(PYTHON) $(SCRIPTS_DIR)/analyze_procedures.py \
		--project-dir . --source $(SRC) --rom $(ROM) \
		--movie $(MOVIE_FILE_$(MOVIE)) \
		--reference reference/$(MOVIE) --diffs diffs/$(MOVIE) \
		--procedures-file $(PROCEDURES_FILE) \
		--workers $(ANALYSIS_WORKERS) --grid-cols $(ANALYSIS_GRID_COLS) \
		--frameskip $(ANALYSIS_FRAMESKIP) --interval $(ANALYSIS_INTERVAL) \
		$(if $(MAX_FRAMES_$(MOVIE)),--max-frames $(MAX_FRAMES_$(MOVIE)),) \
		--max-diffs $(ANALYSIS_MAX_DIFFS) --diff-color $(ANALYSIS_DIFF_COLOR) \
		$(if $(filter true,$(MEMORY)),--memory-diffs,)

# Capture the declared scenarios, then validate them. Needs the instrumented
# Gens build; without it the runner stops rather than producing nothing quietly.
trace-runtime: verify symbols
	@$(PYTHON) $(SCRIPTS_DIR)/run_runtime_scenarios.py 		--scenarios $(RUNTIME_SCENARIOS) --gens "$(GENS_EXE)" 		--rom $(ROM) --output-dir $(RUNTIME_DIR)
	@$(MAKE) validate-runtime

validate-runtime:
	@$(PYTHON) $(SCRIPTS_DIR)/validate_runtime_scenarios.py 		--scenarios $(RUNTIME_SCENARIOS) --capture-dir $(RUNTIME_DIR) 		--summary $(RUNTIME_SUMMARY)

trace: symbols trace-runtime

find-unanalyzed:
	@$(PYTHON) -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@$(PYTHON) $(SCRIPTS_DIR)/find_unnamed_procedures.py \
		--list --exclude-analyzed analysis_results.csv --output $(PROCEDURES_FILE)

report: _require-movie
	@$(PYTHON) -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@$(PYTHON) $(SCRIPTS_DIR)/generate_analysis_report.py \
		--project-dir . --movie $(MOVIE) --output-dir $(WORKFLOW_DIR)

# ---------------------------------------------------------------------------
# Documentation workflow
# ---------------------------------------------------------------------------

set-movie: _require-movie
	@$(PYTHON) -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@echo $(MOVIE) > $(WORKFLOW_DIR)/.movie
	@echo "Movie type set to: $(MOVIE)"

show-movie:
	@if [ -f $(WORKFLOW_DIR)/.movie ]; then \
		echo "Current movie: $$(cat $(WORKFLOW_DIR)/.movie)"; \
	else \
		echo "No movie set. Use: make set-movie MOVIE=longplay"; \
	fi

prepare-batch:
	@if [ ! -f $(WORKFLOW_DIR)/.movie ]; then \
		echo "ERROR: no movie set. Run: make set-movie MOVIE=longplay"; exit 1; \
	fi
	@$(PYTHON) $(SCRIPTS_DIR)/prepare_batch.py \
		--report $(WORKFLOW_DIR)/analysis_report_$$(cat $(WORKFLOW_DIR)/.movie).csv \
		--count $(BATCH_COUNT) \
		--output $(WORKFLOW_DIR)/batch_procedures.txt --source $(SRC)

rename:
	@if [ ! -f $(WORKFLOW_DIR)/rename_batch.csv ]; then \
		echo "ERROR: $(WORKFLOW_DIR)/rename_batch.csv not found."; \
		echo "Create it with columns: old_name,new_name,description"; exit 1; \
	fi
	@$(PYTHON) $(SCRIPTS_DIR)/rename_procedures.py \
		--source $(SRC) --database $(WORKFLOW_DIR)/rename_batch.csv \
		--report $(WORKFLOW_DIR)/analysis_report_$$(cat $(WORKFLOW_DIR)/.movie).csv
	@echo "Renames applied. A new name can change a shared label column,"
	@echo "so run: make format && make verify"

# ---------------------------------------------------------------------------
# Emulator checkout
# ---------------------------------------------------------------------------

build-gens:
	@$(PYTHON) -c "import os, subprocess; d = '$(GENS_DIR)'; os.path.isdir(d) or subprocess.run(['git', 'clone', '$(GENS_REPO)', d], check=True)"
	@$(MAKE) -C $(GENS_DIR) -f $(GENS_MAKEFILE) $(GENS_TARGET)

stop:
	-@taskkill //F //IM Gens.exe 2>/dev/null || true
	@echo "Stopped running emulators."

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
	@echo "  make graphics-studio           Open the visual graphics editor"
	@echo "  make sound-studio              Open the music and SFX editor"
	@echo "  make check-studios             Load Studio models without opening a GUI"
	@echo ""
	@echo "Validation:"
	@echo "  make verify-toolchain          Hash-check the vendored assembler"
	@echo "  make verify-layout             Check the ROM layout contract"
	@echo "  make verify-relocation         Pack the ROM and check relocatable sound loads"
	@echo "  make lint                      Style, naming and repository checks"
	@echo "  make format                    Apply the deterministic fixes, then lint"
	@echo "  make test                      Unit tests for the Python tooling"
	@echo "  make release-audit             Check the 1.0 release contract"
	@echo "  make release-check             The complete acceptance gate"
	@echo "  make source-2-audit            Check the Source 2.0 manifest"
	@echo "  make source-2-check            Run 1.0 plus every Source 2.0 gate"
	@echo ""
	@echo "Data tools:"
	@echo "  make tools                     Build the C decompressors"
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
	@echo "  make build-gens                Clone and cross-build Gens in Docker ($(GENS_DIR))"
	@echo "  make stop                      Kill running emulator processes"
	@echo ""
	@echo "Toolchain: $(TOOLS_DIR)  (override with PLATFORM=<subfolder>)"

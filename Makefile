# Flicky (Genesis) Makefile
# Build configuration for AS assembler

# Tools
AS_BIN = bin/asw.exe
P2BIN = bin/p2bin.exe
AS_ARGS = -maxerrors 2

# Set message path for AS assembler (needed for as.msg, cmdarg.msg, etc.)
export AS_MSGPATH = bin

# Files
SRC = flicky.s
OBJ = flicky.p
ROM = fbuilt.bin
ORIG_ROM = flicky.bin

# Directories
DATA_DIR = data
SRC_DIR = src
SCRIPTS_DIR = scripts
BIN_DIR = bin

# Data addresses file (for binclude segments)
DATA_ADDRS = $(DATA_DIR)/data_addrs.txt

# Default target
.PHONY: all
all: build

# Build ROM from assembly source
.PHONY: build
build:
	@echo "Building ROM..."
	python $(SCRIPTS_DIR)/build_rom.py \
		--source $(SRC) \
		--output $(ROM) \
		--as-bin $(AS_BIN) \
		--p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)"
	@echo ""
	@echo "Build complete: $(ROM)"

# Split original ROM into data files
.PHONY: split
split:
	@echo "Splitting ROM data..."
	@python $(SCRIPTS_DIR)/split_data_from_rom.py \
		--rom-file $(ORIG_ROM) \
		--output $(DATA_DIR) \
		--addrs $(DATA_ADDRS)
	@echo ""
	@echo "Split complete!"

# Clean build artifacts and temp files
.PHONY: clean
clean:
	@python $(SCRIPTS_DIR)/clean_project.py

# Analysis configuration
# Workflow directory (for reports, procedure lists, etc.)
WORKFLOW_DIR = workflow

# Movie files for each analysis type
MOVIE_FILE_longplay = movies/flicky_longplay.gmv
MOVIE_FILE_demos = movies/flicky_demos.gmv

# Max frames per movie type (0 = play until end)
MAX_FRAMES_longplay = 67000
MAX_FRAMES_demos = 0
ANALYSIS_WORKERS = 24
ANALYSIS_GRID_COLS = 6
ANALYSIS_FRAMESKIP = 8
ANALYSIS_INTERVAL = 20
ANALYSIS_MAX_FRAMES = 90000
ANALYSIS_MAX_DIFFS = 10
ANALYSIS_DIFF_COLOR = pink
PROCEDURES_FILE = $(WORKFLOW_DIR)/unanalyzed_procedures.txt

# Generate reference screenshots + memory dumps
# Usage: make reference MOVIE=tas|longplay
.PHONY: reference
reference:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make reference MOVIE=<type>"
	@echo ""
	@echo "Examples:"
	@echo "  make reference MOVIE=tas      - TAS speedrun reference"
	@echo "  make reference MOVIE=longplay - Longplay reference"
	@exit 1
else
	@echo "Generating reference screenshots and memory dumps from $(MOVIE)..."
	python -c "import os; os.makedirs('reference/$(MOVIE)', exist_ok=True)"
	"$(GENS_EXE)" \
		-rom $(ROM) \
		-play $(MOVIE_FILE_$(MOVIE)) \
		-screenshot-interval $(ANALYSIS_INTERVAL) \
		-screenshot-dir reference/$(MOVIE) \
		$(if $(MAX_FRAMES_$(MOVIE)),-max-frames $(MAX_FRAMES_$(MOVIE)),) \
		-save-state-dumps \
		-turbo \
		-frameskip 0 \
		-nosound
	@echo "Reference saved to reference/$(MOVIE)/"
endif

# Analyze procedures for visual/memory impact
# Usage: make analyze MOVIE=tas|longplay [MEMORY=true]
# MEMORY=true - also save memory diffs and stop when max-memory-diffs reached
# MEMORY=false (default) - visual-only mode, no memory diff files saved
.PHONY: analyze
analyze:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make analyze MOVIE=<type> [MEMORY=true]"
	@echo ""
	@echo "Examples:"
	@echo "  make analyze MOVIE=tas              - Visual-only analysis"
	@echo "  make analyze MOVIE=longplay         - Visual-only analysis"
	@echo "  make analyze MOVIE=tas MEMORY=true  - Visual + memory analysis"
	@exit 1
else
	@echo "Analyzing procedures with $(MOVIE) ($(ANALYSIS_WORKERS) workers)..."
	@echo "  Memory diffs: $(if $(filter true,$(MEMORY)),ENABLED,DISABLED)"
	python $(SCRIPTS_DIR)/analyze_procedures.py \
		--project-dir . \
		--source $(SRC) \
		--rom $(ROM) \
		--movie $(MOVIE_FILE_$(MOVIE)) \
		--reference reference/$(MOVIE) \
		--diffs diffs/$(MOVIE) \
		--procedures-file $(PROCEDURES_FILE) \
		--workers $(ANALYSIS_WORKERS) \
		--grid-cols $(ANALYSIS_GRID_COLS) \
		--frameskip $(ANALYSIS_FRAMESKIP) \
		--interval $(ANALYSIS_INTERVAL) \
		$(if $(MAX_FRAMES_$(MOVIE)),--max-frames $(MAX_FRAMES_$(MOVIE)),) \
		--max-diffs $(ANALYSIS_MAX_DIFFS) \
		--diff-color $(ANALYSIS_DIFF_COLOR) \
		$(if $(filter true,$(MEMORY)),--memory-diffs,)
endif

# Find which procedures are not yet analyzed and save to file
.PHONY: find-unanalyzed
find-unanalyzed:
	@echo "Finding unanalyzed procedures..."
	@python -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@python $(SCRIPTS_DIR)/find_unnamed_procedures.py \
		--list \
		--exclude-analyzed analysis_results.csv \
		--output $(PROCEDURES_FILE)
	@echo "Saved to $(PROCEDURES_FILE)"

# Generate analysis report
# Usage: make report MOVIE=tas|longplay
.PHONY: report
report:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make report MOVIE=<type>"
	@echo ""
	@echo "Examples:"
	@echo "  make report MOVIE=tas      - Generate TAS report"
	@echo "  make report MOVIE=longplay - Generate longplay report"
	@exit 1
else
	@echo "Generating $(MOVIE) analysis report..."
	@python -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	python $(SCRIPTS_DIR)/generate_analysis_report.py --project-dir . --movie $(MOVIE) --output-dir $(WORKFLOW_DIR)
	@echo "Report saved: $(WORKFLOW_DIR)/analysis_report_$(MOVIE).txt / .csv"
endif

# Compare built ROM with original
.PHONY: compare
compare:
	@python $(SCRIPTS_DIR)/compare_roms.py \
		--built $(ROM) \
		--original $(ORIG_ROM) \
		--project-dir .

# ============================================================================
# DOCUMENTATION WORKFLOW
# ============================================================================
# 1. make set-movie MOVIE=tas     - Set current movie type for workflow
# 2. make prepare-batch COUNT=40  - Prepare batch of procedures to document
# 3. [Claude creates workflow/rename_batch.csv with new names]
# 4. make rename                  - Apply renames and mark as processed
# ============================================================================

# Set movie type for documentation workflow
# Usage: make set-movie MOVIE=tas|longplay
.PHONY: set-movie
set-movie:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required!"
	@echo ""
	@echo "Usage: make set-movie MOVIE=<type>"
	@echo ""
	@echo "Examples:"
	@echo "  make set-movie MOVIE=tas"
	@exit 1
else
	@python -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@echo $(MOVIE) > $(WORKFLOW_DIR)/.movie
	@echo "Movie type set to: $(MOVIE)"
	@echo "Saved to $(WORKFLOW_DIR)/.movie"
endif

# Show current movie setting
.PHONY: show-movie
show-movie:
	@if [ -f $(WORKFLOW_DIR)/.movie ]; then \
		echo "Current movie: $$(cat $(WORKFLOW_DIR)/.movie)"; \
	else \
		echo "No movie set. Use: make set-movie MOVIE=tas"; \
	fi

# Prepare batch of procedures for documentation
# Usage: make prepare-batch COUNT=40
BATCH_COUNT ?= 40
.PHONY: prepare-batch
prepare-batch:
	@if [ ! -f $(WORKFLOW_DIR)/.movie ]; then \
		echo "ERROR: No movie set!"; \
		echo "First run: make set-movie MOVIE=tas"; \
		exit 1; \
	fi
	@echo "Preparing batch of $(BATCH_COUNT) procedures..."
	python $(SCRIPTS_DIR)/prepare_batch.py \
		--report $(WORKFLOW_DIR)/analysis_report_$$(cat $(WORKFLOW_DIR)/.movie).csv \
		--count $(BATCH_COUNT) \
		--output $(WORKFLOW_DIR)/batch_procedures.txt \
		--source $(SRC)
	@echo ""
	@echo "Batch prepared: $(WORKFLOW_DIR)/batch_procedures.txt"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Claude reads $(WORKFLOW_DIR)/batch_procedures.txt"
	@echo "  2. Claude creates $(WORKFLOW_DIR)/rename_batch.csv with columns:"
	@echo "     old_name,new_name,description"
	@echo "  3. Run: make rename"

# Apply renames from rename_batch.csv and mark as processed
.PHONY: rename
rename:
	@if [ ! -f $(WORKFLOW_DIR)/.movie ]; then \
		echo "ERROR: No movie set!"; \
		exit 1; \
	fi
	@if [ ! -f $(WORKFLOW_DIR)/rename_batch.csv ]; then \
		echo "ERROR: $(WORKFLOW_DIR)/rename_batch.csv not found!"; \
		echo "Create it with columns: old_name,new_name,description"; \
		exit 1; \
	fi
	@echo "Applying renames from $(WORKFLOW_DIR)/rename_batch.csv..."
	python $(SCRIPTS_DIR)/rename_procedures.py \
		--source $(SRC) \
		--database $(WORKFLOW_DIR)/rename_batch.csv \
		--report $(WORKFLOW_DIR)/analysis_report_$$(cat $(WORKFLOW_DIR)/.movie).csv
	@echo ""
	@echo "Renames applied! Next steps:"
	@echo "  1. Review changes: git diff $(SRC)"
	@echo "  2. Build and test: make build"
	@echo "  3. Commit: git add $(SRC) && git commit"

# Stop all running emulators and analysis
.PHONY: stop
stop:
	@echo "Stopping analysis and emulators..."
	-taskkill /F /IM Gens.exe 2>nul
	-taskkill /F /IM python.exe 2>nul
	@echo "Done"

# Build Gens emulator
.PHONY: build-gens
build-gens:
	@echo "Building Gens emulator..."
	"$(MSBUILD)" "$(GENS_SLN)" -p:Configuration=Release -p:Platform=Win32 -p:PlatformToolset=v143 -t:Build -v:minimal
	@echo "Build complete: $(GENS_EXE)"

# Default symbol file
SYMBOLS_FILE = logs/symbols.txt

# Generate symbol file from assembly listing
# Usage: make symbols [SYMBOLS=<output.txt>]
.PHONY: symbols
symbols: flicky.lst
	@python -c "import os; os.makedirs('logs', exist_ok=True)"
	@echo "Extracting symbols from flicky.lst..."
	python $(SCRIPTS_DIR)/extract_symbols.py flicky.lst \
		--stats --rom-only -o $(if $(SYMBOLS),$(SYMBOLS),$(SYMBOLS_FILE))

# Generate listing file (prerequisite for symbols)
flicky.lst: flicky.s src/macros.inc src/ports.inc src/equals.inc src/ram_addrs.inc
	@echo "Building listing file..."
	$(AS_BIN) -L $(AS_ARGS) flicky.s

# Help
.PHONY: help
help:
	@echo "Flicky (Genesis) Build System"
	@echo ""
	@echo "Basic commands:"
	@echo "  make build              - Assemble and build ROM (default)"
	@echo "  make compare            - Compare built ROM with original"
	@echo "  make split              - Extract data from original ROM"
	@echo "  make clean              - Remove all build artifacts"
	@echo ""
	@echo "Analysis workflow (requires MOVIE=tas|longplay):"
	@echo "  1. make find-unanalyzed        - Generate list of unanalyzed procedures"
	@echo "  2. make reference MOVIE=tas    - Generate reference screenshots"
	@echo "  3. make analyze MOVIE=tas      - Analyze procedures"
	@echo "  4. make report MOVIE=tas       - Generate analysis report"
	@echo ""
	@echo "Documentation workflow (Claude + human):"
	@echo "  1. make set-movie MOVIE=tas    - Set movie type for workflow"
	@echo "  2. make prepare-batch COUNT=40 - Prepare batch of procedures"
	@echo "     -> Claude reads workflow/batch_procedures.txt"
	@echo "     -> Claude creates workflow/rename_batch.csv"
	@echo "  3. make rename                 - Apply renames and mark processed"
	@echo "  4. make build && make compare"
	@echo "  5. git commit"
	@echo ""
	@echo "Debugging (visual + memory):"
	@echo "  1. make reference MOVIE=tas    - Generate reference"
	@echo "  2. [modify ROM and rebuild]"
	@echo "  3. make debug MOVIE=tas        - Collect 10 visual differences"
	@echo ""
	@echo "CPU tracing (binary format):"
	@echo "  make trace-frames MOVIE=tas START=100 END=110"
	@echo "  make trace-story LOG=logs/trace_100_110.btrc"
	@echo "  make trace-graph LOG=logs/trace_100_110.btrc"
	@echo "  make trace-stats LOG=logs/trace_100_110.btrc"
	@echo ""
	@echo "Utilities:"
	@echo "  make show-movie         - Show current movie setting"
	@echo "  make stop               - Stop all running Gens emulators"
	@echo "  make build-gens         - Build Gens emulator (VS2022)"
	@echo ""
	@echo "MOVIE types: tas, longplay"
	@echo "Workflow dir: $(WORKFLOW_DIR)/"

# Extract local ROM payloads before tools inspect or assemble the source.
.PHONY: _rom_assets
_rom_assets:
	$(PYTHON) scripts/rom_assets.py ensure
build lint split init build-profile build-revision build-fixed-layout init-content build-content check-content-zero-edit check-studios: _rom_assets

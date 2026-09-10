# ---------------------------------------------------------------------------
# Emulator analysis (requires MOVIE=longplay|demos)
# ---------------------------------------------------------------------------

_require-movie:
ifndef MOVIE
	@echo "ERROR: MOVIE parameter required. Use MOVIE=longplay or MOVIE=demos."
	@exit 1
endif

# Generate reference screenshots and memory dumps from a known-good ROM.
reference: _require-movie | _require-emulator
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
analyze: _require-movie | _require-emulator
	@$(PYTHON) $(RUN_SCRIPT) workflow.analyze_procedures \
		--project-dir . --source $(SRC) --rom $(ROM) \
		--gens "$(GENS_EXE)" \
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
trace-runtime: verify symbols | _require-emulator
	@$(PYTHON) $(RUN_SCRIPT) runtime.run_runtime_scenarios 		--scenarios $(RUNTIME_SCENARIOS) --gens "$(GENS_EXE)" 		--rom $(ROM) --output-dir $(RUNTIME_DIR)
	@$(MAKE) validate-runtime

validate-runtime:
	@$(PYTHON) $(RUN_SCRIPT) runtime.validate_runtime_scenarios 		--scenarios $(RUNTIME_SCENARIOS) --capture-dir $(RUNTIME_DIR) 		--summary $(RUNTIME_SUMMARY)

trace: symbols trace-runtime

find-unanalyzed:
	@$(PYTHON) -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@$(PYTHON) $(RUN_SCRIPT) workflow.find_unnamed_procedures \
		--list --exclude-analyzed analysis_results.csv --output $(PROCEDURES_FILE)

report: _require-movie
	@$(PYTHON) -c "import os; os.makedirs('$(WORKFLOW_DIR)', exist_ok=True)"
	@$(PYTHON) $(RUN_SCRIPT) workflow.generate_analysis_report \
		--project-dir . --movie $(MOVIE) --output-dir $(WORKFLOW_DIR)


# ---------------------------------------------------------------------------
# Emulator checkout
# ---------------------------------------------------------------------------

build-gens:
	@$(PYTHON) $(RUN_SCRIPT) build.prepare_gens_checkout \
		--config $(TOOLCHAIN_MANIFEST) --checkout "$(GENS_DIR)"
	@$(MAKE) -C $(GENS_DIR) -f $(GENS_MAKEFILE) $(GENS_TARGET)
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_toolchain \
		--config $(TOOLCHAIN_MANIFEST) --only emulator --require-emulator \
		--require-executable "emulator=$(GENS_DIR)/Output/Gens.exe"

build-ymfm-renderer:
	@$(PYTHON) $(RUN_SCRIPT) authoring.build_ymfm_renderer \
		--output-dir bin/windows_i386

stop:
	-@taskkill //F //IM Gens.exe 2>/dev/null || true
	@echo "Stopped running emulators."

# AS has no linker, so the include order in src/main.s is the ROM layout itself.
# This makes that layout a declaration the build has to agree with. It reads the
# listing for the module addresses, so it has to depend on one being there.
verify-layout: $(LISTING)
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_layout \
		--layout $(ROM_LAYOUT) --listing $(LISTING) --rom $(ROM)

verify-relocation: $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN) _require-assets _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_relocation \
		--source $(SRC) --sound-data $(Z80_DATA_BIN) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# Compare an existing build without reassembling.
compare:
	@$(PYTHON) $(RUN_SCRIPT) validation.compare_roms \
		--built $(ROM) --original "$(ORIGINAL_ROM)" --manifest $(ASSET_MANIFEST)

# Listing file, used by extract_data_addrs.py and the debugger workflow.
# -i lets modules under src/ resolve their binclude paths from the project root.
$(LISTING): $(M68K_SOURCE_FILES) $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN) | _require-toolchain
	@$(PYTHON) -c "from pathlib import Path; Path('$(dir $@)').mkdir(parents=True, exist_ok=True)"
	@$(AS_BIN) -i . -L -olist $@ -o $(OBJ) $(AS_ARGS) $(SRC)

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

verify-emulator:
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_toolchain \
		--config $(TOOLCHAIN_MANIFEST) --only emulator --require-emulator \
		$(EMULATOR_EXECUTABLE)

_require-emulator: verify-emulator

# Style, semantic source invariants, and repository-wide checks. None of these
# substitute for "make verify": a green lint says nothing about byte identity.
lint:
	@$(PYTHON) $(RUN_SCRIPT) validation.asm_style src
	@$(PYTHON) $(RUN_SCRIPT) validation.lint_source $(STRICT_NAMING)
	@$(PYTHON) $(RUN_SCRIPT) validation.check_source_structure --config $(SOURCE_STRUCTURE)
	@$(PYTHON) $(RUN_SCRIPT) validation.lint_project

check-source-structure:
	@$(PYTHON) $(RUN_SCRIPT) validation.check_source_structure --config $(SOURCE_STRUCTURE)

# Read-only formatting check. The formatter uses the same normalization and
# reports any file that a second pass would change.
format-check:
	@$(PYTHON) $(RUN_SCRIPT) validation.asm_style src

# Focused unit tests for the Python tooling, so a bug in a check cannot
# quietly pass everything it is supposed to catch.
test:
	@$(PYTHON) -m unittest discover -s tests -t . -p "test_*.py"

# Check the repository against the machine-readable release contract.
release-audit:
	@$(PYTHON) $(RUN_SCRIPT) validation.release_audit --contract $(RELEASE_CONTRACT)

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

# The 2.0 manifest describes the tree tagged source-reconstruction-2.0 (with
# the editors 3.0 retired), so its audits run there, by the tag's own targets
# and tools, in a disposable clone.
SOURCE_2_TAG ?= source-reconstruction-2.0
SOURCE_2_AT_TAG = $(PYTHON) $(RUN_SCRIPT) validation.tag_audit --tag "$(SOURCE_2_TAG)" --

source-2-audit:
	@$(SOURCE_2_AT_TAG) "$(MAKE)" source-2-audit

source-2-release-audit:
	@$(SOURCE_2_AT_TAG) "$(MAKE)" source-2-release-audit

source-2-check:
	$(MAKE) release-check
	$(MAKE) verify-relocation
	$(MAKE) source-2-audit

source-2-pre-tag-check:
	$(MAKE) source-2-check
	@$(SOURCE_2_AT_TAG) scripts/run.py validation.source_2_audit \
		--manifest $(SOURCE_2_MANIFEST) --pre-tag

source-2-tag-check:
	$(MAKE) source-2-check
	@$(SOURCE_2_AT_TAG) scripts/run.py validation.source_2_audit \
		--manifest $(SOURCE_2_MANIFEST) --require-tag

# Retrolarium: flicky.rlj opens in the kit and builds back to the ROM, in a
# throwaway copy of the repository. The kit needs the studio's Flicky level
# writer (RETROLARIUM_FLICKY_LEVEL_WRITER or on PATH).
RLTOOL ?= rltool

studio-check:
	$(RLTOOL) studio check flicky.rlj

# Source Reconstruction 3.0, in development until Retrolarium is tagged: the
# source-2-check gate, then studio-check with the manifest's Retrolarium
# section checked against the descriptor and the running kit.
SOURCE_3_MANIFEST ?= config/source_reconstruction_3_0.json

source-3-audit:
	$(RLTOOL) studio check flicky.rlj --release $(SOURCE_3_MANIFEST)

source-3-check:
	$(MAKE) source-2-check
	$(MAKE) source-3-audit

# Clone-level structural confidence without a private ROM or extracted data.
# Codec cases use synthetic inputs; both audits validate real public commands.
scaffold-check: lint release-audit source-2-audit
	@$(PYTHON) -m unittest \
		tests.formats.test_enigma_encoder \
		tests.validation.test_make_interface \
		tests.validation.test_release_audit \
		tests.validation.test_repository_layout \
		tests.validation.test_source_2_audit

# Deterministic whitespace, label-layout and case normalization, then re-check.
# Formatting must never move a byte, so verify afterwards.
format:
	@$(PYTHON) $(RUN_SCRIPT) validation.asm_style src --fix
	@$(MAKE) lint


# Export the symbol map and resolve the debugger configs against it.
symbols: $(LISTING)
	@$(PYTHON) $(RUN_SCRIPT) validation.debug_symbols 		--listing $(LISTING) 		--breakpoints $(DEBUG_BREAKPOINTS) --watches $(DEBUG_WATCHES) 		--sym $(SYMBOL_FILE) --summary $(DEBUG_SUMMARY)

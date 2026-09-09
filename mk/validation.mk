# AS has no linker, so the include order in src/main.s is the ROM layout itself.
# This makes that layout a declaration the build has to agree with. It reads the
# listing for the module addresses, so it has to depend on one being there.
verify-layout: $(LISTING)
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_layout \
		--layout $(ROM_LAYOUT) --listing $(LISTING) --rom $(ROM)

verify-relocation: $(Z80_BIN) $(Z80_DATA_BIN) _require-assets _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_relocation \
		--source $(SRC) --sound-data $(Z80_DATA_BIN) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# Compare an existing build without reassembling.
compare:
	@$(PYTHON) $(RUN_SCRIPT) validation.compare_roms \
		--built $(ROM) --original "$(ORIGINAL_ROM)" --manifest $(ASSET_MANIFEST)

# Listing file, used by extract_data_addrs.py and the debugger workflow.
# -i lets modules under src/ resolve their binclude paths from the project root.
$(LISTING): $(M68K_SOURCE_FILES) $(Z80_BIN) $(Z80_DATA_BIN) | _require-toolchain
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

source-2-audit:
	@$(PYTHON) $(RUN_SCRIPT) validation.source_2_audit --manifest $(SOURCE_2_MANIFEST)

source-2-release-audit:
	@$(PYTHON) $(RUN_SCRIPT) validation.source_2_audit --manifest $(SOURCE_2_MANIFEST) --require-ready

source-2-check:
	$(MAKE) release-check
	$(MAKE) verify-relocation
	$(MAKE) check-content-zero-edit
	$(MAKE) validate-content
	$(MAKE) check-studios
	$(MAKE) smoke-studios-workstation
	$(MAKE) smoke-level-playtest
	$(MAKE) verify-sound-sequencer
	$(MAKE) source-2-audit

source-2-pre-tag-check:
	$(MAKE) source-2-check
	@$(PYTHON) $(RUN_SCRIPT) validation.source_2_audit \
		--manifest $(SOURCE_2_MANIFEST) --pre-tag

source-2-tag-check:
	$(MAKE) source-2-check
	@$(PYTHON) $(RUN_SCRIPT) validation.source_2_audit \
		--manifest $(SOURCE_2_MANIFEST) --require-tag

# Clone-level structural confidence without a private ROM or extracted data.
# Codec cases use synthetic inputs; both audits validate real public commands.
scaffold-check: lint release-audit source-2-audit
	@$(PYTHON) -m unittest \
		tests.authoring.test_enigma_encoder \
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

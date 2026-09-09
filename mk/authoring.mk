# ---------------------------------------------------------------------------
# Isolated content authoring
# ---------------------------------------------------------------------------

# Initialize only missing workspace files. Existing edits are never replaced;
# use FORCE=true only when intentionally resetting them to tracked baselines.
init-content:
	@$(PYTHON) $(RUN_SCRIPT) authoring.content_workspace init \
		--manifest $(CONTENT_MANIFEST) $(if $(filter true,$(FORCE)),--force,)

inspect-content:
	@$(PYTHON) $(RUN_SCRIPT) authoring.content_workspace inspect \
		--manifest $(CONTENT_MANIFEST)

validate-content:
	@$(PYTHON) $(RUN_SCRIPT) authoring.content_workspace validate \
		--manifest $(CONTENT_MANIFEST)

# Editable builds have their own generated source tree and ROM. The strict
# preservation artifacts used by make verify are neither read nor overwritten.
build-content: init-content _require-assets _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) authoring.build_content \
		--manifest $(CONTENT_MANIFEST) --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)" --original-rom "$(ORIGINAL_ROM)" \
		--asset-manifest $(ASSET_MANIFEST) \
		--level-workspace "$(CONTENT_LEVEL_WORKSPACE)" \
		--graphics-workspace "$(CONTENT_GRAPHICS_WORKSPACE)" \
		--semantics-workspace "$(CONTENT_SEMANTICS_WORKSPACE)" \
		--sequences-workspace "$(CONTENT_SEQUENCES_WORKSPACE)" \
		--sound-workspace "$(CONTENT_SOUND_WORKSPACE)"

# The release gate builds directly from tracked baselines, so a developer's
# current workspace may remain edited while preservation compatibility runs.
check-content-zero-edit: _require-assets _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) authoring.build_content --zero-edit \
		--manifest $(CONTENT_MANIFEST) --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)" --original-rom "$(ORIGINAL_ROM)" \
		--asset-manifest $(ASSET_MANIFEST)

level-studio: init-content
	@$(PYTHON) $(RUN_SCRIPT) authoring.level_studio

playtest-level: build-content | _require-emulator
	@$(PYTHON) $(RUN_SCRIPT) runtime.level_playtest --gens "$(GENS_EXE)" \
		--rom "$(CONTENT_ROM)" --round "$(or $(ROUND),1)"

smoke-level-playtest: build-content | _require-emulator
	@$(PYTHON) $(RUN_SCRIPT) runtime.level_playtest --gens "$(GENS_EXE)" \
		--rom "$(CONTENT_ROM)" --round "$(or $(ROUND),26)" --check

graphics-studio: init-content
	@$(PYTHON) $(RUN_SCRIPT) authoring.graphics_studio

sound-studio: init-content
	@$(PYTHON) $(RUN_SCRIPT) authoring.sound_studio

preview-sound: init-content
	@$(PYTHON) $(RUN_SCRIPT) authoring.sound_preview $(SOUND) \
		--seconds $(SOUND_SECONDS) --renderer "$(YMFM_RENDERER)"

trace-sound: verify | _require-emulator
	@$(PYTHON) $(RUN_SCRIPT) runtime.capture_sound_trace --gens "$(GENS_EXE)" \
		--rom "$(ROM)" --config "$(SOUND_TRACE_CONFIG)" \
		--trace "$(SOUND_TRACE_FILE)" --frames "$(SOUND_TRACE_FRAMES)"

verify-sound-sequencer: trace-sound
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_sound_trace \
		--trace "$(SOUND_TRACE_FILE)"

check-studios: init-content
	@$(PYTHON) $(RUN_SCRIPT) authoring.level_studio --check
	@$(PYTHON) $(RUN_SCRIPT) authoring.graphics_studio --check
	@$(PYTHON) $(RUN_SCRIPT) authoring.sound_studio --check

smoke-studios-workstation: init-content
	@$(PYTHON) $(RUN_SCRIPT) authoring.studio_workstation_smoke

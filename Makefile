# Flicky (Sega Mega Drive): build the source back into the original ROM and
# check it. `make help` lists the targets; the logic lives in scripts/.

PYTHON ?= python
PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

# AS and p2bin from Retrolarium Kit (RLTOOL, default rltool), asked once per
# run; the recipes' shell needs forward slashes. AS reads its message
# catalogs from beside the assembler (AS_MSGPATH).
RLTOOL ?= rltool
export RLTOOL
AS_BIN ?= $(eval AS_BIN := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path megadrive asl)))$(AS_BIN)
P2BIN ?= $(eval P2BIN := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path megadrive p2bin)))$(P2BIN)
AS_ARGS ?= -maxerrors 2
# MAME for `make test-full` and `make golden`.
MAME ?= $(RETROLARIUM_MAME)

SRC ?= src/main.s
OBJ ?= build/main.p
ROM ?= fbuilt.bin
ORIGINAL_ROM ?= Flicky (UE) [!].bin
ASSET_MANIFEST ?= assets/manifest.json
DATA_DIR ?= data
DATA_ADDRS ?= $(DATA_DIR)/data_addrs.txt
RUN_SCRIPT ?= scripts/run.py
TOOLCHAIN_MANIFEST ?= config/toolchain.json
TOOLCHAIN_EXECUTABLES = --require-executable "assembler=$(AS_BIN)" --require-executable "binary_converter=$(P2BIN)"
ROM_LAYOUT ?= config/linker/rom_layout.json
LISTING ?= build/main.lst
RELOCATED_ROM ?= build/relocation/flicky_packed.bin
MOVIE_CHECKS ?= movies/flicky_longplay.check.json movies/flicky_demos.check.json
M68K_SOURCE_FILES := $(shell $(PYTHON) -c "from pathlib import Path; print(' '.join(p.as_posix() for p in Path('src').rglob('*') if p.suffix in {'.s', '.inc'}))")
Z80_SOURCE ?= src/sound/z80/driver.asm
Z80_DRIVER_MODULES := $(wildcard src/sound/z80/driver/*.asm)
Z80_OBJ ?= build/z80_driver.p
Z80_BIN ?= build/z80_driver.bin
Z80_REFERENCE ?= data/sound/data_z80_part1.bin
Z80_DATA_SOURCE ?= src/sound/z80/data.asm
Z80_DATA_OBJ ?= build/z80_sound_data.p
Z80_DATA_BIN ?= build/z80_sound_data.bin
Z80_DATA_SFX_BIN ?= $(basename $(Z80_DATA_BIN))_sfx.bin
Z80_DATA_MUSIC_BIN ?= $(basename $(Z80_DATA_BIN))_music.bin
Z80_DATA_REFERENCE ?= data/sound/data_z80_part2.bin

.DEFAULT_GOAL := build

.PHONY: all build verify z80-check z80-data-check init split check-assets verify-toolchain \
	verify-layout verify-relocation studio-check lint format format-check test test-full \
	golden hooks clean help _require-assets _require-toolchain

all: build

# Assemble and report byte identity as a warning.
build: _require-toolchain _require-assets $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN)
	@$(PYTHON) $(RUN_SCRIPT) build.build_rom \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--manifest $(ASSET_MANIFEST) --original-rom "$(ORIGINAL_ROM)" \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# The permanent gate: any difference from the reference ROM fails the build.
verify: _require-toolchain _require-assets $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN)
	@$(PYTHON) $(RUN_SCRIPT) build.build_rom \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--manifest $(ASSET_MANIFEST) --original-rom "$(ORIGINAL_ROM)" \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)" \
		--verify

$(Z80_BIN): $(Z80_SOURCE) $(Z80_DRIVER_MODULES) $(RUN_SCRIPT) scripts/build/build_z80_driver.py $(Z80_REFERENCE) | _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) build.build_z80_driver \
		--source $(Z80_SOURCE) --obj $(Z80_OBJ) --output $(Z80_BIN) \
		--reference $(Z80_REFERENCE) --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)"

z80-check: $(Z80_BIN)

$(Z80_DATA_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN) &: $(Z80_DATA_SOURCE) $(RUN_SCRIPT) scripts/build/build_z80_driver.py $(Z80_DATA_REFERENCE) | _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) build.build_z80_driver \
		--source $(Z80_DATA_SOURCE) --obj $(Z80_DATA_OBJ) --output $(Z80_DATA_BIN) \
		--reference $(Z80_DATA_REFERENCE) --reference-offset 12 \
		--description "Z80 sound-data banks" --split-label zMusicBank --as-bin $(AS_BIN) --p2bin $(P2BIN) \
		--as-args "$(AS_ARGS)"

z80-data-check: $(Z80_DATA_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN)

# Validate the reference ROM, extract data, then build and verify.
init: _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) build.init_project \
		--orig-rom "$(ORIGINAL_ROM)" --manifest $(ASSET_MANIFEST) \
		--data-dir $(DATA_DIR) --data-addrs $(DATA_ADDRS) \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--z80-source $(Z80_SOURCE) --z80-obj $(Z80_OBJ) \
		--z80-output $(Z80_BIN) --z80-reference $(Z80_REFERENCE) \
		--z80-data-source $(Z80_DATA_SOURCE) --z80-data-obj $(Z80_DATA_OBJ) \
		--z80-data-output $(Z80_DATA_BIN) --z80-data-reference $(Z80_DATA_REFERENCE) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# Extract binary segments from the reference ROM. This is the only command
# that overwrites data/; ordinary builds never touch it.
split:
	@$(PYTHON) $(RUN_SCRIPT) build.split_data_from_rom \
		--rom-file "$(ORIGINAL_ROM)" --output $(DATA_DIR) --addrs $(DATA_ADDRS)

check-assets _require-assets:
	@$(PYTHON) $(RUN_SCRIPT) build.check_assets \
		--manifest $(ASSET_MANIFEST) --asset-dir $(DATA_DIR)

# The assembler is checked before it is used, not after the ROM disagrees.
verify-toolchain _require-toolchain:
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_toolchain --config $(TOOLCHAIN_MANIFEST) $(TOOLCHAIN_EXECUTABLES)

# AS has no linker, so the include order in src/main.s is the ROM layout itself.
# This makes that layout a declaration the build has to agree with.
verify-layout: $(LISTING)
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_layout \
		--layout $(ROM_LAYOUT) --listing $(LISTING) --rom $(ROM)

# -i lets modules under src/ resolve their binclude paths from the project root.
$(LISTING): export AS_MSGPATH = $(dir $(AS_BIN))
$(LISTING): $(M68K_SOURCE_FILES) $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN) | _require-toolchain
	@$(PYTHON) -c "from pathlib import Path; Path('$(dir $@)').mkdir(parents=True, exist_ok=True)"
	@$(AS_BIN) -i . -L -olist $@ -o $(OBJ) $(AS_ARGS) $(SRC)

# The ROM packed without its two layout gaps, so the code after them moves
# (build/relocation/flicky_packed.bin), and the sound loads checked.
verify-relocation: $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN) _require-assets _require-toolchain
	@$(PYTHON) $(RUN_SCRIPT) validation.verify_relocation \
		--source $(SRC) --sound-data $(Z80_DATA_BIN) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# Open flicky.rlj in a throwaway copy of the repository the way Retrolarium
# Studio does, and rebuild it without edits.
studio-check:
	$(RLTOOL) studio check flicky.rlj

lint:
	@$(RLTOOL) lint

format:
	@$(RLTOOL) lint --fix

format-check:
	@$(RLTOOL) lint --only assembly

# The quick suite: the unit tests, the byte-identical ROM, its layout, the
# relocated ROM and the studio check.
test:
	@$(PYTHON) -m unittest discover -s tests -t . -p "test_*.py"
	@$(MAKE) --no-print-directory verify verify-layout verify-relocation studio-check

# The full suite: the quick one, then both movies in MAME on the packed ROM,
# compared with what the original ROM gives (movies/*.check.json, written by
# `make golden`).
test-full: test
	$(foreach check,$(MOVIE_CHECKS),$(RLTOOL) movie check $(check) --rom $(RELOCATED_ROM) --mame "$(MAME)" &&) true

golden:
	$(foreach check,$(MOVIE_CHECKS),$(RLTOOL) movie golden $(check) --rom "$(ORIGINAL_ROM)" --mame "$(MAME)" &&) true

# `make hooks`, once per clone, makes Git check every commit and push for stop
# words and run `make lint` and `make format-check` first (Retrolarium Kit's
# rltool hooks; the stop-word list lives outside the repositories).
hooks:
	$(RLTOOL) hooks install --project .

clean:
	@$(PYTHON) $(RUN_SCRIPT) build.clean_project

help:
	@echo "Flicky source reconstruction"
	@echo "  make init                     check the ROM, extract data/, build and verify (once)"
	@echo "  make split                    extract data/ again from the ROM"
	@echo "  make build / verify           the ROM / and byte for byte"
	@echo "  make verify-layout            the module layout against the listing"
	@echo "  make verify-relocation        the ROM packed without its layout gaps"
	@echo "  make studio-check             open and rebuild flicky.rlj"
	@echo "  make test                     the quick suite"
	@echo "  make test-full                test, then both movies in MAME (MAME=<path>)"
	@echo "  make golden                   record the movies' checkpoints from the original"
	@echo "  make lint / format / format-check   the house style (Retrolarium Kit)"
	@echo "  make hooks                    install the Git hooks (stop words, lint before commits)"
	@echo "  make verify-toolchain         check the kit's assembler and converter"
	@echo "  make clean                    remove the build output"

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
# The private assets: assets/manifest.json names the ROM and the segments
# `make split` cuts out of it into data/; `rltool assets` (Retrolarium Kit)
# splits, checks and verifies.
ASSETS = $(RLTOOL) assets $(1)
BASE_IMAGE := ue
RUN_SCRIPT ?= scripts/run.py
TOOLCHAIN_MANIFEST ?= config/toolchain.json
TOOLCHAIN_EXECUTABLES = --require-executable "assembler=$(AS_BIN)" --require-executable "binary_converter=$(P2BIN)"
ROM_LAYOUT ?= config/linker/rom_layout.json
LISTING ?= build/main.lst
RELOCATED_ROM ?= build/relocated/flicky.bin
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

.PHONY: all build verify z80-check z80-data-check split verify-toolchain \
	verify-layout build-relocated studio-check lint format format-check test test-full \
	golden hooks clean help _require-assets _require-toolchain

all: build

build: _require-toolchain _require-assets $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN)
	@$(PYTHON) $(RUN_SCRIPT) build.build_rom \
		--source $(SRC) --output $(ROM) --obj $(OBJ) \
		--as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"

# The permanent gate: any difference from the reference ROM fails.
verify: build
	$(call ASSETS,verify) --image $(BASE_IMAGE) --built "$(ROM)"

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

# Cut the segments out of the ROM into data/. This is the only command that
# writes data/; ordinary builds only read it.
split:
	$(call ASSETS,split)

_require-assets:
	@$(call ASSETS,check) --image $(BASE_IMAGE)

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

# The ROM with its code and data moved (scripts/build/relocate.py).
build-relocated: $(Z80_BIN) $(Z80_DATA_SFX_BIN) $(Z80_DATA_MUSIC_BIN) _require-assets _require-toolchain
	@$(PYTHON) scripts/build/relocate.py --source $(SRC) --output-dir build/relocated \
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
	@$(MAKE) --no-print-directory verify verify-layout build-relocated studio-check

# The full suite: the quick one, then the movies in MAME on the relocated
# build in turn (the longplay, then the demos; the first that differs stops
# it), compared with what the original ROM gives (movies/*.check.json, written
# by `make golden`).
test-full: test
	$(RLTOOL) movie check $(MOVIE_CHECKS) --rom $(RELOCATED_ROM) --mame "$(MAME)"

golden:
	$(RLTOOL) movie golden $(MOVIE_CHECKS) --rom "$(ORIGINAL_ROM)" --mame "$(MAME)"

# `make hooks`, once per clone, makes Git check every commit and push for stop
# words and run `make lint` and `make format-check` first (Retrolarium Kit's
# rltool hooks; the stop-word list lives outside the repositories).
hooks:
	$(RLTOOL) hooks install --project .

clean:
	@$(PYTHON) $(RUN_SCRIPT) build.clean_project

help:
	@echo "Flicky source reconstruction"
	@echo "  make split                    cut data/ out of the ROM (once)"
	@echo "  make build / verify           the ROM / and byte for byte"
	@echo "  make verify-layout            the module layout against the listing"
	@echo "  make build-relocated          the ROM with its code and data moved"
	@echo "  make studio-check             open and rebuild flicky.rlj"
	@echo "  make test                     the quick suite"
	@echo "  make test-full                test, then both movies in MAME (MAME=<path>)"
	@echo "  make golden                   record the movies' checkpoints from the original"
	@echo "  make lint / format / format-check   the house style (Retrolarium Kit)"
	@echo "  make hooks                    install the Git hooks (stop words, lint before commits)"
	@echo "  make verify-toolchain         check the kit's assembler and converter"
	@echo "  make clean                    remove the build output"

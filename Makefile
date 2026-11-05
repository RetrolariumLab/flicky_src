# Flicky (Sega Mega Drive): build the source back into the original ROM and
# check it. `make` alone lists the targets. The ROM is yours: copy it next to
# this file under the name assets/manifest.json gives, then run `make split`
# once.
PYTHON ?= python
RLTOOL ?= rltool
export RLTOOL
# AS and p2bin from Retrolarium Kit, which verifies them; asked once, when a
# recipe first needs them (the recipes' shell wants forward slashes). The
# scripts point AS at its message catalogs beside the assembler.
AS_BIN ?= $(eval AS_BIN := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path megadrive asl)))$(AS_BIN)
P2BIN ?= $(eval P2BIN := $$(subst \,/,$$(shell $$(RLTOOL) build-tools path megadrive p2bin)))$(P2BIN)
AS_ARGS := -maxerrors 2
TOOLS = --as-bin $(AS_BIN) --p2bin $(P2BIN) --as-args "$(AS_ARGS)"
# scripts/run.py runs the build scripts; Retrolarium Kit's Studio build calls
# them the same way.
RUN := $(PYTHON) scripts/run.py

BASE_IMAGE := ue
ROM := build/flicky.bin
RELOCATED_ROM := build/relocated/flicky.bin
# The Z80 sound driver and the sound-data banks, assembled on their own; the
# 68000 source includes them from build/.
Z80_DRIVER := build/z80_driver.bin
Z80_DATA := build/z80_sound_data.bin
Z80_PARTS := $(Z80_DRIVER) $(basename $(Z80_DATA))_sfx.bin $(basename $(Z80_DATA))_music.bin
# The movies the relocated build plays in `make test-full`, by name
# (movies/<name>.check.json, written by `make golden`).
MOVIES := longplay attract
MOVIE_CHECKS = $(foreach movie,$(MOVIES),movies/$(movie).check.json)
MAME_OPTION = $(if $(MAME),--mame "$(MAME)")

.PHONY: help split build verify verify-revisions build-relocated studio-check lint format \
	test test-full golden play hooks clean _assets _z80
.DEFAULT_GOAL := help

split:
	$(RLTOOL) assets split

_assets:
	$(RLTOOL) assets check --image $(BASE_IMAGE)

# Every build assembles anew: the Z80 parts, then the 68000 source that
# includes them.
_z80:
	$(RUN) build.build_z80_driver --source src/sound/z80/driver.asm --obj build/z80_driver.p \
		--output $(Z80_DRIVER) $(TOOLS)
	$(RUN) build.build_z80_driver --source src/sound/z80/data.asm --obj build/z80_sound_data.p \
		--output $(Z80_DATA) --description "Z80 sound-data banks" --split-label zMusicBank $(TOOLS)

build: _assets _z80
	$(RUN) build.build_rom --source src/main.s --obj build/main.p --output $(ROM) $(TOOLS)

verify: build
	$(RLTOOL) assets verify --image $(BASE_IMAGE) --built "$(ROM)"

# Flicky has one revision.
verify-revisions: verify

# The source with its code and data moved (scripts/build/relocate.py), built
# the same way and given a valid header.
build-relocated: _assets _z80
	$(PYTHON) scripts/build/relocate.py --source src/main.s --output-dir build/relocated
	$(RUN) build.build_rom --source build/relocated/main.s --obj build/relocated/main.p \
		--output $(RELOCATED_ROM) $(TOOLS)
	$(PYTHON) scripts/build/relocate.py --finish $(RELOCATED_ROM)

# Open flicky.rlj in a throwaway copy of the repository the way Retrolarium
# Studio does, and rebuild it without edits.
studio-check:
	$(RLTOOL) studio check flicky.rlj --present

lint:
	$(RLTOOL) lint

format:
	$(RLTOOL) lint --fix

# The quick suite: the unit tests, the ROM byte for byte, the relocated build
# and the studio check.
test:
	$(PYTHON) -m unittest discover -s tests -t .
	$(MAKE) --no-print-directory verify build-relocated studio-check

# The full suite: the quick one, then the movies in MAME on the relocated
# build in turn (the longplay, then the attract demos; the first that differs
# stops it), compared with what the original ROM gives (`make golden`).
test-full: test
	$(RLTOOL) movie check $(MOVIE_CHECKS) --rom "$(RELOCATED_ROM)" $(MAME_OPTION)

golden:
	$(RLTOOL) movie golden $(MOVIE_CHECKS) --rom "$(shell $(RLTOOL) assets path --image $(BASE_IMAGE))" $(MAME_OPTION)

# Watch a movie in a MAME window at the game's speed, on the relocated build
# or on ROM=<image>; once the window is closed, its cells are compared with
# the original's. In MAME, F10 lifts the speed limit and Insert fast-forwards.
#   make play [MOVIE=<name>] [ROM=<image>] [FRAMES=<frame>] [CLOSE=1]
# FRAMES closes MAME at that frame (only the start of the movie), CLOSE=1 when
# the movie ends (else it stays open to play on, the credits say).
MOVIE ?= $(firstword $(MOVIES))
PLAY_ROM = $(if $(filter command line,$(origin ROM)),$(ROM),$(RELOCATED_ROM))

play: $(if $(filter command line,$(origin ROM)),,build-relocated)
	$(if $(wildcard movies/$(MOVIE).check.json),,$(error unknown MOVIE "$(MOVIE)": movies/ has \
		$(basename $(basename $(notdir $(wildcard movies/*.check.json))))))
	$(RLTOOL) movie play movies/$(MOVIE).check.json --rom "$(PLAY_ROM)" $(MAME_OPTION) \
		$(if $(FRAMES),--stop-at $(FRAMES)) $(if $(CLOSE),--close)

# `make hooks`, once per clone, makes Git check every commit and push for stop
# words and run `make lint` first (Retrolarium Kit's rltool hooks; the
# stop-word list lives outside the repositories).
hooks:
	$(RLTOOL) hooks install --project .

clean:
	$(PYTHON) -c "import shutil; shutil.rmtree('build', ignore_errors=True)"

help:
	$(info Flicky source reconstruction)
	$(info   make split                  cut the assets out of the ROM, once)
	$(info   make build                  build the ROM into build/flicky.bin)
	$(info   make verify                 build it and compare it with the ROM byte for byte)
	$(info   make build-relocated        the ROM with its code and data moved)
	$(info   make test                   the quick suite)
	$(info   make test-full              test, then the movies in MAME: MAME=path or the kit's)
	$(info   make golden                 record the movies' checkpoints from the original ROM)
	$(info   make play [MOVIE=name]      watch a movie in MAME; ROM=image for another build)
	$(info   make studio-check / lint / format / hooks / clean)
	@exit 0

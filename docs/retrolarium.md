# Editing in Retrolarium

Flicky is edited in Retrolarium Studio, not by tools in this repository. Open
`flicky.rlj` at the repository root in the studio. It checks the ROM
(`Flicky (UE) [!].bin`, copied next to `flicky.rlj` and never committed), copies
this repository into `.retrolarium/ue/flicky-source` and keeps the edits there:
Flicky is rebuilt from its assembly source with the edited data, so the studio
works on its own copy rather than on `hack/`. Neither folder is tracked.

## What is edited

The kit's Flicky profile defines every view; this repository only names the
revision. The studio offers:

- the 48 rounds and the bonus rounds (seesaws, tigers, chick spawns), with
  playtest from any round;
- the graphics, palettes, animations and screens, including the movable title
  sprites;
- the text;
- the music and sound effects: FM voices, envelopes and the streams, with a
  piano roll and a YM2612 preview;
- the attract demos.

The kit's sequencer plays the Z80 driver's streams for the preview. Its test
compares it with the real driver: `make trace-sound` records the chip writes
Gens sees during title song `$85` into `build/sound_trace/gens.csv`, and the kit
requires the same ordered writes within 2.1 frames.

## Checking the repository

`make studio-check` runs `rltool studio check flicky.rlj`. In a throwaway copy
of the repository it prepares the revision, validates each document and rebuilds
the ROM with no edits, requiring it byte for byte. It needs the ROM, the
Retrolarium kit (`rltool` on `PATH`, or `RLTOOL=...`) and the studio's Flicky
level writer (`RETROLARIUM_FLICKY_LEVEL_WRITER`, or on `PATH`), and never reads
or writes `.retrolarium/`.

## Source Reconstruction 3.0

`config/source_reconstruction_3_0.json` is the 3.0 release manifest. It names
the descriptor, the profile and the revisions, the kit and studio versions the
release is checked with, and every removed editor with the view that replaced
it. `make source-3-audit` runs studio-check with `--release`, which also checks
that section against the descriptor and the running kit; `make source-3-check`
runs the Source 2.0 gate first. The manifest stays in `development` with the kit unpinned
until Retrolarium publishes its first tags.

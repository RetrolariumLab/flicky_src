# Content Authoring

Source Reconstruction 2.0 adds an editable build beside the preservation
build. The two outputs deliberately do not share generated objects:

| Pipeline | Input | Output | Identity rule |
| --- | --- | --- | --- |
| Preservation | tracked source | `fbuilt.bin` | must equal the cartridge dump |
| Content | `content/workspace/` | `build/content/flicky.bin` | may contain authored changes |
| Zero edit | tracked content baselines | `build/content/zero-edit/flicky.bin` | must equal the cartridge dump |

The workspace is ignored because it contains a local editable representation
of data derived from the user-supplied ROM. Editors must save atomically and
must never modify `src/`, `data/`, or the preservation build outputs.

## Commands

```bash
make init-content              # create only missing workspace artifacts
make inspect-content           # report unchanged, edited, or missing artifacts
make validate-content          # check the workspace without building
make build-content             # build build/content/flicky.bin
make check-content-zero-edit   # prove tracked baselines reproduce the ROM
```

`make init-content FORCE=true` intentionally resets workspace artifacts to
their tracked baselines. Ordinary initialization never overwrites an edit.

The first editable artifact is the Z80 sound-data translation unit. Its
editable build may differ from the reference bytes, but it must remain exactly
2,804 bytes so the following ROM regions do not move. The resident driver is
still assembled from tracked source and checked byte for byte in both build
pipelines.

## Studio contract

`config/content_studios.json` is the machine-readable inventory. A studio
moves from `planned` through `foundation` to `supported`; the status must never
claim more than its headless model can validate. The intended supported set is:

- Level Studio for layouts, collision classes, placements, and round settings;
- Graphics Studio for tiles, palettes, mappings, animations, screens, and text;
- Sound Studio for songs, effects, channel events, envelopes, and FM voices.

Each GUI is a thin client over the same decoder, validator, and encoder used by
the command line. A format is not supported merely because the GUI can display
it: headless load, validation, save, and zero-edit reproduction are all part of
the claim.

## Level Studio

`make level-studio` opens the current visual editor. It exposes all 48 round
slots while preserving their mapping onto 36 shared layouts. The editor can
change the 32-column collision grid, player and door positions, background
objects, six spawners, both chick groups, and the three special-collision
classes. Shared layouts are identified in the toolbar so an edit cannot appear
to affect only one of several linked rounds.

The headless model decodes the collision command stream and every variable-
length object group into `content/workspace/level/levels.json`. On build it
generates the two owning assembly sections. Their pointer tables refer to
`Level_DataN` and `Level_SpecialTilesN` labels, so AS recalculates every pointer
after a record changes length. The special-tile section retains its fixed
capacity; ordinary level data may consume the original `$465F`-byte ROM padding
before the end marker.

Unedited streams retain their original representation. An edited collision
grid is encoded as forward skips and horizontal solid runs, and the validator
decodes the result again before the assembler sees it. `make check-studios`
loads and validates the model without creating a Tk window.

The editable build stages a disposable copy of the source tree under
`build/content/` and redirects generated payload includes there. This makes an
edited ROM possible without copying a workspace payload over
`build/z80_sound_data.bin`, which belongs to the strict preservation pipeline.

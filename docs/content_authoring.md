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

## Graphics Studio

`make graphics-studio` opens the current raster-asset editor. Its tile canvas
can edit all six Nemesis-compressed 4bpp banks (843 tiles total) and both 1bpp
font banks. Separate tabs expose the ten-entry compact Sega palette and the
12-by-4 word tilemap used by the Sega screen. The ignored editable document is
`content/workspace/graphics/graphics.json`.

Unedited assets pass through their original bytes. Edited Nemesis banks are
recompressed with an optimizing encoder and decoded again during validation;
the result must fit the bank's original fixed ROM slot. The Sega tilemap has
an exact Enigma encoder and the same ten-byte capacity check. Fonts and the
compact palette retain their exact fixed sizes. Shorter compressed streams are
padded only inside their existing slots, so no following ROM address moves.

This is the raster foundation of Graphics Studio. Mappings, animations, level
palettes, in-game text, and additional screens remain separate semantic data.

The same GUI also loads `content/workspace/graphics/semantics.json`. It exposes
52 printable English strings and 28 palettes: twelve 16-colour level palettes,
fifteen four-colour accent palettes, and the eight-colour title-logo palette.
Strings may be replaced within their original byte capacity; shorter values
are padded with spaces in the staged source. Palette sizes are fixed and each
channel is validated against the Mega Drive's even `$0EEE` colour bits. These
rules keep every edited record in its original ROM footprint. The Japanese
guide strings use a separate raw glyph encoding and are not yet exposed.

`content/workspace/graphics/sequences.json` covers the sprite layer: 224 used
mapping records and 50 animation sequences. A mapping piece is decoded into
signed X/Y coordinates, its separate mirrored-X coordinate, a one-to-four tile
width and height, tile index, palette, priority, and flip flags. The GUI draws
the pieces around their object origin. Animation records expose their delay and
every fixed frame slot, for both object-sprite and tilemap animation formats.
Piece and frame counts remain fixed so generated records retain their original
byte capacities; labels in the staged assembly make all references compiler-
resolved.

The Japanese guide strings and additional non-animated screen layouts remain
outside the current machine-readable artifacts and are not yet claimed as
supported.

## Sound Studio

`make sound-studio` opens the semantic editor over the editable
`content/workspace/sound/z80_sound_data.asm` translation unit. It inventories
all 14 unique resident headers (six music and eight SFX), 52 channel event
streams, 34 25-byte YM2612 voices, and the 63-byte shared priority/envelope
area. Header tabs expose duration scale, tempo, channel sequence, transpose,
volume, SFX flags/channel, and PSG envelope selectors.

The event view names notes, rests, durations, and the `$E0-$FF` coordination
commands while retaining byte offsets and arguments. Stream lengths, track
counts, voice counts, and the total 2,804-byte bank capacity remain fixed in
this first editor; ASW recomputes every symbolic pointer. The two trailing
sentinel bytes at the SFX/music bank boundaries are preserved explicitly.

`Preview in Gens` saves the model, runs `make build-content`, and launches the
edited ROM with the sibling `gens_automation` build. This deliberately uses
the real Z80 driver, YM2612, PSG, and game interrupt timing instead of a
separate approximate WAV synthesizer. If Gens is absent the editor reports the
existing `make build-gens` prerequisite.

The editable build stages a disposable copy of the source tree under
`build/content/` and redirects generated payload includes there. This makes an
edited ROM possible without copying a workspace payload over
`build/z80_sound_data.bin`, which belongs to the strict preservation pipeline.

# Source Reconstruction 2.0

Source Reconstruction 2.0 turns the preserved Flicky program into an editable
game source while keeping Source Reconstruction 1.0 intact. The default input,
ROM layout, reference hashes, runtime scenarios, and `make release-check`
contract do not change. The tagged 1.0 commit remains an ancestor of this
release, and the canonical build still reproduces SHA-1
`83d8bbf0a9b38c42a0bf492d105cc3abe9644a96` byte for byte.

The current branch is a development candidate, not yet a release. Its public
manifest records the project-owned schema, release line, scope, evidence, and
gates without exposing review-system metadata. The status changes to
`tag-ready` only after the remaining history and clean-tree checks have been
reviewed and satisfied.

The release adds three capability groups:

1. The complete 4,070-byte resident Z80 driver and 2,804-byte resident sound
   banks are symbolic ASW translation units. Their ordinary preservation
   targets still reproduce the original bytes exactly, while the isolated
   content build permits checked sound edits.
2. A separate ignored authoring workspace and content build. Its zero-edit
   path is generated from tracked baselines rather than local editor files and
   independently reproduces the canonical 128 KiB image.
3. Three dependency-free Tkinter studios backed by the same headless parsers,
   validators, and generators used by the build.

## Supported editors

Level Studio exposes all 48 round slots and their 36 shared layouts: collision
cells, player and door positions, background objects, six hanging chicks, two
enemy groups, and special collision classes. Its game-scale preview composes
the editable tile banks, round palettes, background tilemaps, ground, Flicky,
chicks, and enemies through the same VRAM indices and sprite mappings as the
ROM. Generated labels let ASW recalculate level pointers when an ordinary
record changes length; the special section and ROM tail retain explicit
capacity checks. The selected round can be playtested directly in Gens: a Lua
bootstrap enters the original `Game_InitRound` path after normal title setup,
and an automated smoke target proves the requested round reaches gameplay.

Graphics Studio covers ten raster assets, 843 4bpp tiles, both 1bpp fonts, the
compact Sega palette and screen, 52 English strings, 28 game palettes, 224
used sprite mappings, and 50 sprite/tilemap animations. The Nemesis encoder
uses a bit-optimal split and must fit each original slot. Enigma has an exact
encoder for the Sega screen. Text, mapping, animation, and palette records keep
their fixed capacities.

Sound Studio covers 14 unique resident headers, 52 event streams, 34 YM2612
voices, and the 63-byte shared priority/envelope area. It names the Z80
coordination commands, presents notes on an editable piano roll, and exposes
semantic four-operator FM parameters while preserving stream, track, voice,
sentinel, and total bank sizes. Its Python reconstruction exports chip writes
as VGM, and a pinned local ymfm helper renders standalone WAV previews with
per-track channel selection. The Python interpreter's frequency folding,
modulation waves, pitch slides, voice loads, and update ordering are checked
against the actual Z80: 2,624 ordered YM2612 writes from title music `$85`
match a fresh instrumented-Gens trace exactly.

## Scope boundaries

This project claims one canonical JUE Mega Drive / Genesis cartridge image.
No additional revisions, platforms, or experimental behavior-changing builds
are declared, so those conditional 2.0 requirements are `not_applicable`.

Five registered code/RAM/data questions remain open. DATA-002 is the only
authoring-format limitation: all six Nemesis streams round-trip to identical
pixels and fit after edits, but the original compressor's non-optimal run
splitting heuristic is not reproduced byte for byte. The Japanese guide text
remains editable in semantic assembly but is not presented as printable text
because it uses raw glyph indexes. These boundaries are recorded in
`config/source_reconstruction_2_0.json` rather than hidden by the release
status.

## Acceptance gate

`make source-2-check` is the aggregate acceptance gate. It runs the complete
1.0 `make release-check` first, including the twelve emulator scenarios. It
then verifies relocation, constructs and compares the independent zero-edit
content ROM, validates every local workspace artifact, loads all Studio models
without a display server, enforces the source granularity and directory policy,
smoke-tests direct level entry in Gens, and audits the 2.0 manifest, documents,
Make targets, format strengths, supported Studio inventory, predecessor tag,
and ancestry. It also captures and compares the real Z80 sound-register stream
through `make verify-sound-sequencer`.

The annotated `source-reconstruction-2.0` tag is created only after that gate
passes on the release commit with a clean worktree. ROMs, extracted assets,
workspace JSON/ASM, generated content builds, and emulator captures remain
ignored local data.

The release sequence is explicit:

```bash
make source-2-audit          # valid while status is development
make source-2-check          # full 1.0 gate followed by all 2.0 checks
make source-2-pre-tag-check  # requires tag-ready status and a clean tree
# create the annotated tag only after human review
make source-2-tag-check      # verifies the tag type and exact target
```

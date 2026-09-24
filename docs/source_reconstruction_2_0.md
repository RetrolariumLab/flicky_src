# Source Reconstruction 2.0

Source Reconstruction 2.0 turns the preserved Flicky program into an editable
game source while keeping Source Reconstruction 1.0 intact. The default input,
ROM layout, reference hashes, runtime scenarios, and `make release-check`
contract do not change. The tagged 1.0 commit remains an ancestor of this
release, and the canonical build still reproduces SHA-1
`83d8bbf0a9b38c42a0bf492d105cc3abe9644a96` byte for byte.

The annotated `source-reconstruction-2.0` tag marks the release commit. The
current `main` branch includes subsequent source and tooling corrections. The
public manifest records the project-owned schema, release line, scope,
evidence, and gates; the tagged commit passed the aggregate, history, and
clean-tree checks.

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

## Draft-history reconstruction

The unpublished 2.0 draft was reconstructed on the owner-approved modernization
branch from immutable local `main` at
`3d9f56e5eae3a3d7edfa4186081918e3e522d7e2`. The rewrite preserves established
architectural boundaries while preventing changed files from creating new
historical copies of obsolete review metadata.

| Previous commit | Replacement commit | Scope | Reason |
| --- | --- | --- | --- |
| `0d7875881571dcf073acc7e2baad6c4f00f28a4c` | `b162e5e9e6a05d0d628828efebda7998d22d510c` | Correct the checksum-error documentation link. | Preserve the one-file change while recording the current co-author accurately. |
| `3bb9ca0ebbc492070ef4ce1eee7a92150bba18a8` | `9ef65d570ae7118cce74aa35d3ab983fd7a0202b` | Reconstruct the Z80 driver and sound data. | Replay the complete atomic subsystem change onto the approved base. |
| `e911d088d9c9af49cdeae0878552855921d568c0` | `9fcfcfc63de524a7b07c05a72a9a205105633796` | Isolate content authoring. | Preserve the build boundary and zero-edit identity evidence. |
| `fc9b3f856390571589d2d5d5f388d1967e335aee` | `c9f5e0eda5bfbca5d5933ac75fd93d7751068ec2` | Add level authoring and Level Studio. | Preserve one complete editor-model vertical slice. |
| `8227525f7b3635c1beb99330c843f7f4703188d2` | `8b012f6ad546c1d1ed3e19d3527c71252a4c84d2` | Add graphics authoring and adopt project-owned release metadata. | Keep the codec, model, GUI, and test boundary while removing obsolete provenance before changed files create new draft blobs. |
| `7d16bd7f68161d660f77d9ad2773ab850c9d0c15` | `d07b49bb0d4b354a47a2bc956d13f898ce58bbad` | Add music, SFX, and FM voice authoring. | Preserve the semantic sound-authoring boundary. |
| `d51297d3a15364ef6a2a649dd3b921cc9b31b5d1` | `b75e67b65a899a058afd5134b0c8062515240fe1` | Define the 2.0 project gate. | Preserve the first complete machine-readable acceptance boundary. |
| `ddf6a5c9537ee553e435db1588fc44c570c1df66` | `ee536136572abd99643913e23ca4e94f85d8aac3` | Organize assembly by semantic owner. | Preserve the address-safe source reorganization as one reviewable change. |
| `d838db42acc3855c1419a902ffdaf60c0304a048` | `0111bf7083a22e4802a1d465c37e5055b050950f` | Organize scripts by responsibility. | Keep moves, imports, subprocess paths, and tests atomic. |
| `6c153b1f5c2491b622540e0467d354532942c352` | `74ddc1cd6adf4b8b3565d4647895a04efcf547af` | Complete Level Studio rendering and playtesting. | Preserve the editor-to-runtime vertical slice. |
| `7ccca4955f2ae494081025083405ceec92cdd175` | `6d5e1ac513324bcb648543d1e589d5a0ed094da1` | Add standalone sound preview and trace comparison. | Preserve the sequencer, renderer, toolchain, and fidelity evidence together. |
| `696702e95e8f5871fe50ee14b982771ecd1c071c` | `ab75d93ec74ab156354d6ea45f6cb7973ddf3da0` | Match Level Studio to VDP presentation. | Preserve the focused visual-correctness fix and regressions. |
| `fc1d2bc33d4e7dc0e2e05cd9525e876fcfef7f6b` | `d0963008aa19c7b80e0acb778a93f50730a949db` | Modernize repository layout and the public release interface. | Combine the structural draft with project-owned manifest and audit policy so obsolete review provenance is absent from the candidate tree. |

Every replacement is nonempty. Author and committer dates are monotonic in
parent order: direct replays retain their timestamps, while combined cleanup
uses a timestamp within the interval represented by its source work.

Remote-tracked history remains unchanged. Historical release-policy metadata
at or before the base, together with old local branches and tags, is outside
this rewrite and deferred to explicit owner review. The candidate neither
rewrites published objects nor deletes recovery refs.

## Documentation corpus review

The release documentation was reviewed as one reader-facing corpus, starting
from `README.md` and `docs/index.md` and following every local Markdown link.
The task-oriented build, source-layout, subsystem, authoring, validation,
runtime, format, debugger, naming, RAM, unknowns, and provenance documents each
answer a distinct reader question. Assembler choice and converter consequences
are consolidated in `docs/build.md`; ROM-layout rationale is in
`docs/source_layout.md`; runtime evidence design is in
`docs/runtime_evidence.md`. The release history and rewrite map live in this
release-boundary document, and the human label/data account is the single
top-level `docs/provenance.md`.

The 1.0 and 2.0 release-boundary documents remain separate because 1.0 is an
immutable historical baseline. The shared `source_` filename prefix is an
explicit exception: source layout and versioned release boundaries have
different audiences, owners, and lifecycles. `make lint` inventories every
tracked Markdown file, rejects an orphan, flags documents beyond the review
size limit, and rejects unexplained flat clusters of three or more peer
documents with the same filename prefix.

Label provenance has one machine-readable owner:
`config/reconstruction/label_renames.json`. `docs/provenance.md` explains and
links that registry without duplicating it, and the 2.0 audit rejects another
registry path or shape.

## Tool ownership follow-up

The shared Nemesis and Enigma codecs now live in the importable
`scripts/formats` package, which is below both extraction and authoring in the
dependency graph. Their former C decoder copies and separate build entrypoint
were retired because the tested Python implementations cover the supported
decode and round-trip behavior. This leaves one implementation owner for each
format instead of two copies that could drift.

The YMFM renderer remains native C++: only its small project frontend and
container recipe moved under `scripts/authoring/ymfm_renderer`. The upstream
YMFM core stays under `third_party/ymfm`, and
`python scripts/run.py authoring.build_ymfm_renderer` exposes the native build
through the same Python command surface as the other project tooling.

## Acceptance gate

`make source-2-check` is the aggregate acceptance gate. It runs the complete
1.0 `make release-check` first, including the twelve emulator scenarios. It
then verifies relocation, constructs and compares the independent zero-edit
content ROM, validates every local workspace artifact, loads all Studio models
without a display server, creates real Tk windows to exercise every declared
Studio action, enforces the source granularity and directory policy, smoke-tests
direct level entry in Gens, and audits the 2.0 manifest, documents,
Make targets, format strengths, supported Studio inventory, predecessor tag,
and ancestry. It also captures and compares the real Z80 sound-register stream
through `make verify-sound-sequencer`. Cleanup is constrained to resolved
generated paths and is regression-tested against an ignored workspace `tmp`
directory. Studio build and playtest actions pass their exact selected inputs
into the content builder, including alternate workspace files.

The annotated `source-reconstruction-2.0` tag was created after that gate
passed on the release commit with a clean worktree. ROMs, extracted assets,
workspace JSON/ASM, generated content builds, and emulator captures remain
ignored local data.

The release sequence was:

```bash
make source-2-audit          # validate the project-owned release manifest
make source-2-check          # full 1.0 gate followed by all 2.0 checks
make source-2-pre-tag-check  # requires tag-ready status and a clean tree
# create the annotated tag after human review
make source-2-tag-check      # verifies the tag type and exact target
```

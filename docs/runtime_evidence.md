# Runtime Evidence

## Status: captured and checked

Twelve scenarios, 68 declared expectations about work RAM, all holding. The
capture is produced by the instrumented Gens build and validated against the
symbols in `src/memory/ram.inc`, so a scenario fails if the emulated game
diverges even where the picture would still look right.

This layer is the only one in [`validation.md`](validation.md) that observes
behaviour. `make verify` proves the bytes are right; only a replay proves the
bytes still *do* what they used to after a change to the tooling, the data
extraction or the build.

## Why state is the release evidence

The first runtime validator compared screenshots when a reference directory
was available. Because no reference capture is tracked, that path degraded to
counting frames and reporting that there was nothing to compare: useful as an
emulator liveness check, but not evidence about the game. Committing hundreds
of megabytes of PNGs would make the check sensitive to emulator rendering
changes and still report only that a frame differs.

The accepted evidence therefore asserts 68000 work-RAM fields by symbol. It
names the field, frame, expected value, and observed value on failure, remains
stable across irrelevant rendering changes, and keeps only each declared frame
window. The full capture fell from about 1.2 GB to roughly 113 MB. Optional
pixel comparison remains available for a user-supplied reference, while the
manifest explicitly excludes it from the release claim; a visual-only defect
that never changes an asserted field remains outside this layer.

## What a scenario declares

`scenarios/runtime_scenarios.json` pins the inputs, names the frame ranges
worth capturing, and states what must be true of memory inside them:

```json
{
  "id": "longplay-score-screen",
  "movie": "longplay",
  "method": "natural play",
  "first_frame": 1460,
  "last_frame": 1700,
  "expects": "Score screen",
  "expect_state": {
    "holds": {
      "Ram_GameState": "$8004",
      "Ram_Score": "$00022560"
    },
    "reaches": {}
  }
}
```

`holds` must be true at **every** captured frame in the window; `reaches` at
**at least one**. The distinction matters. A round number holds for the whole
round, so declaring it as `holds` also asserts the window's boundaries are
right. A game mode is entered partway through a scene, so `reaches` is the
honest claim -- `longplay-round-1` passes through `Game_PreRoundDelay` before
`Game_MainLoop`, and demanding the latter for all 34 frames would be false.

Symbols are resolved from `src/memory/ram.inc` at validation time, never
written as addresses. A rename that misses this file breaks the scenarios
loudly instead of silently checking the wrong memory.

Both the ROM and each movie are pinned by SHA-1, and `run_runtime_scenarios.py`
refuses to capture when either differs. A capture taken against a build that is
not the reference proves nothing, and the tooling would rather stop than
produce evidence nobody can trust.

`method` records how the scenario reaches its state. Every scenario here is
`natural play`: the movie is replayed untouched. If a scenario ever needs a
controlled RAM patch to reach a state the movie does not visit, it declares the
patch and its justification, and its results are never treated as
interchangeable with natural evidence.

## Reading the two fields the scenarios lean on

`Ram_NextGameMode` is an index into `Sys_GameModeTable`, whose entries are
`bra.w`, so the value is the entry number times four:

| Value | Handler |
| --- | --- |
| `$00` | `Title_Init` |
| `$04` | `Title_Update` |
| `$08` | `Guide_Init` |
| `$0C` | `Guide_Update` |
| `$10` | `RoundSelect_Init` |
| `$14` | `RoundSelect_Update` |
| `$18` | `Game_InitRound` |
| `$1C` | `Game_PreRoundDelay` |
| `$20` | `Game_StartRound` |
| `$24` | `Game_MainLoop` |
| `$28` | `Bonus_Init` |
| `$2C` | `Bonus_MainLoop` |
| `$30` | `Ending_Init` |
| `$34` | `Ending_MainLoop` |
| `$38` | `Demo_Init` |
| `$3C` | `Demo_Update` |
| `$40` | `Sys_ModeLoadSegaScreen` |
| `$44` | `Sys_ModeSegaScreen` |

`Ram_GameState` is the same shape one level down, an index into
`Game_StateTable` masked with `andi.w #$7FFC`: `$00` `Game_StatePlay`, `$04`
`Game_StateRoundComplete`, `$08` `Game_StateBonusCheck`, `$0C`
`Game_CheckSkipBonus`, `$10` `Game_StateNextRound`. Bit 15 is set by
`bset #7,(Ram_GameState).w` -- a byte operation on the high half -- and latches
that the state's entry code has already run, which is why the captures show
`$8004` rather than `$0004`.

`Ram_RoundNumber` is a word holding the round twice over: the high byte is the
BCD number the HUD prints, the low byte the plain index the code counts with.
At the credits it reads `$4931` -- BCD 49 and hex `$31`, both the same
round 49.

## The twelve scenarios and what was observed

Nine from the longplay and three from the attract-mode recording. Frame ranges
come from the tracked scene indexes in `movies/`, so they are documented facts
about the inputs rather than guesses.

| Scenario | Frames | Observed state |
| --- | --- | --- |
| `longplay-sega-screen` | 20-300 | reaches `Sys_ModeSegaScreen`, no lives yet |
| `longplay-title-screen` | 320-440 | holds `Title_Update`, reaches 3 lives |
| `longplay-guide-screen` | 460-680 | reaches `Guide_Update`, round 1, 3 lives |
| `longplay-round-1` | 700-1380 | reaches `Game_MainLoop` and 6 chicks |
| `longplay-chickens-counting` | 1400-1440 | chicks fall 6 to 3, score 60 to 660 |
| `longplay-score-screen` | 1460-1700 | holds `Game_StateRoundComplete`, score 22560 |
| `longplay-round-3-bonus` | 3180-4240 | holds round 3, reaches `Bonus_MainLoop`, 20 chicks |
| `longplay-girl-in-window-appeared` | 33260-33600 | holds round 26 and 8 lives, reaches `Game_StateBonusCheck` |
| `longplay-credits` | 62800-66980 | holds `Ending_MainLoop`, round 49, score 2862440 |
| `demos-sega-screen` | 20-300 | boot path again, from a different input |
| `demos-title-screen` | 320-1380 | holds `Title_Update` long enough to time out |
| `demos-demo-play-round-1` | 1400-3380 | reaches `Demo_Update`, score holds at zero |

Two of these earn their place beyond confirming a label.

The attract demo is the only path through `Demo_Init`, the four recorded input
streams and `Demo_ReadInput`: the longplay presses start before the demos
begin, so without this recording that whole subsystem has no runtime coverage
at all. Its `Ram_Score` holding `$00000000` across all 99 frames while chicks
are caught is direct evidence that the attract demo does not score.

`longplay-credits` pins the ending at round 49, which is what
`Score_UpdateDisplay` compares against with `cmpi.b #$49,d0` before switching
to the ending mode. The declared score, `$02862440`, makes the entire 67,000
frame replay a single exact assertion.

## How the state is read

The state dumps come from `state_dump.cpp` in the emulator: an eight byte
`GENSTATE` magic, a 64 byte header, then a table of section entries. Section
`0x01` is 64 KiB of 68000 work RAM.

That section is written with `fwrite(Ram_68k, ...)`, straight out of the
emulator's internal buffer, and **Starscream holds work RAM as host-endian
16 bit words**, so the two bytes of every word are swapped relative to the
68000's own big-endian view. `scripts/runtime/genstate.py` undoes that in `read`.

This is worth stating plainly because getting it wrong is not loud. Reading the
dump without the swap returns the neighbouring byte, which looks like plausible
game data rather than an error: `Ram_NextGameMode` reads as `$4400` instead of
`$0044`, and `Ram_Lives` returns the chick count. The check that settles it is
`Ram_InitFlag` at `$FFFFFC`, which the boot code writes as the ASCII `init`; it
only spells `init` after the swap.

## Running it

```bash
make build-gens        # Prepare the pinned revision and cross-build in Docker
make verify-emulator   # Verify the resolved GENS_EXE before a runtime launch
make trace-runtime     # Capture, then validate
make validate-runtime  # Re-validate an existing capture
```

Each capture records what produced it. `build/runtime/capture_info.json` holds
the emulator's path, size and SHA-256 alongside the ROM's SHA-1, and the
validation summary carries it. Before capture, the toolchain gate requires both
the pinned emulator checkout commit and the approved executable SHA-256. A
substituted or unreviewed rebuild is rejected rather than accepted as evidence.
`make build-gens` creates a detached checkout at the manifest revision when the
sibling directory is absent. It refuses to build an existing checkout with a
different origin, commit, or tracked source changes; it never updates from an
advancing default branch.
After Docker builds Gens, the command stamps the PE timestamp and checksum from
`config/toolchain.json` and accepts the result only if its complete SHA-256
matches the approved executable. This makes repeated builds byte-identical
despite the linker's build-time timestamp.

Captures are written under `build/runtime/`, which is ignored. Regenerating
them into an ignored directory is deliberate: a stale local capture must not be
able to mask a regression. `make release-check` runs `make trace`, so the gate
captures fresh rather than trusting whatever is on disk.

Each invocation writes every selected scenario and its provenance into a new
isolated staging directory. Only a complete run replaces the prior recognized
capture tree. A crash, nonzero exit, or successful emulator invocation that
produces no frames leaves the old tree unpublished and makes the capture command
fail, so validation can only observe files produced together by one run.

A movie can only be replayed from its start, so the emulator writes every frame
up to a scenario's last, and the runner deletes the ones outside the window as
soon as that scenario finishes. It reports how much it dropped. Without it a
full capture is well over a gigabyte, almost all of it frames no scenario looks
at -- `longplay-girl-in-window-appeared` asserts 17 frames and captures 1,679
to reach them.

To also compare screenshots against a known-good capture:

```bash
python scripts/run.py runtime.validate_runtime_scenarios \
    --capture-dir build/runtime --reference-dir reference/runtime
```

Without `--reference-dir` the state checks still run; only the frame-by-frame
image comparison is skipped. The two layers answer different questions, and the
state layer is the one that carries the evidence.

## What this layer can and cannot prove

It cannot prove a name is correct. A scenario that reaches `Bonus_MainLoop`
confirms the bonus round runs and that `Ram_NextGameMode` selects it; it says
nothing about whether `Ram_BonusCaughtCount` counts what its name claims. Every
expectation above is a claim about a value at an address, and the reasoning
from there to a name is the part [`unknowns.md`](unknowns.md) exists to track.

It can still settle a narrower question, and did on its first run. Working out
what `Ram_RoundNumber` holds showed that `Demo_Init`'s two round tables were
named the wrong way round: the one called `Demo_RoundHighTable` was written to
`Ram_RoundNumber+1`, the low byte. They are now `Demo_RoundIndexTable` and
`Demo_RoundDisplayTable`, after what each is observed to contain.

Nor does it prove the ROM is right -- `make verify` does that, and it runs
first. What this layer adds is that the ROM still behaves, which no hash can
show.

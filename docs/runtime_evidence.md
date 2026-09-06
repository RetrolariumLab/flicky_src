# Runtime Evidence

## Status: declared, not yet captured

The scenarios, the runner and the validator exist. **No capture has been
produced**, because the instrumented Gens build this layer depends on has not
been built on the machine this reconstruction was assembled on: it requires
Visual Studio 2022, and no MSBuild is installed there.

That is stated here rather than worked around. Milestone 7 in
[`roadmap.md`](roadmap.md) is not marked complete, and the release contract for
1.0 excludes runtime evidence rather than claiming it. Everything on this page
describes a layer that is ready to run, not results that have been observed.

## What a scenario declares

`scenarios/runtime_scenarios.json` pins the inputs and names the frame ranges
worth capturing:

```json
{
  "rom_sha1": "83d8bbf0a9b38c42a0bf492d105cc3abe9644a96",
  "movies": {
    "longplay": { "path": "movies/flicky_longplay.gmv", "sha1": "df655c49..." }
  },
  "scenarios": [
    { "id": "longplay-round-1", "movie": "longplay", "method": "natural play",
      "first_frame": 700, "last_frame": 1380, "expects": "Round 1" }
  ]
}
```

Both the ROM and each movie are pinned by SHA-1, and `run_runtime_scenarios.py`
refuses to capture when either differs. A capture taken against a build that is
not the reference proves nothing, and the tooling would rather stop than
produce evidence nobody can trust.

`method` records how the scenario reaches its state. Every scenario here is
`natural play`: the movie is replayed untouched. If a scenario ever needs a
controlled RAM patch to reach a state the movie does not visit, it declares the
patch and its justification, and its results are never treated as
interchangeable with natural evidence.

## The twelve scenarios

Nine from the longplay and three from the attract-mode recording. Frame ranges
come from the tracked scene indexes in `movies/`, so they are documented facts
about the inputs rather than guesses.

| Scenario | Frames | What it reaches |
| --- | --- | --- |
| `longplay-sega-screen` | 20-300 | The Sega logo, Enigma tilemap and Nemesis art |
| `longplay-title-screen` | 320-440 | Title screen, bird and cursor objects |
| `longplay-guide-screen` | 460-680 | Guide screen and its character objects |
| `longplay-round-1` | 700-1380 | Ordinary gameplay: player, cats, chicks, collision |
| `longplay-chickens-counting` | 1400-1440 | End-of-round chick tally |
| `longplay-score-screen` | 1460-1700 | Score breakdown and time bonus |
| `longplay-round-3-bonus` | 3180-4240 | The bonus round and its own object set |
| `longplay-girl-in-window-appeared` | 33260-33600 | The rare late-round event |
| `longplay-credits` | 62800-66980 | Ending sequence and scrolling credits |
| `demos-sega-screen` | 20-300 | Boot path again, from a different input |
| `demos-title-screen` | 320-1380 | Title idle long enough to time out |
| `demos-demo-play-round-1` | 1400-3380 | Attract mode, the only path through `Demo_Init` |

The last one matters more than its size suggests. The longplay presses start
before the attract demos begin, so it never executes `Demo_Init`, the four
recorded input streams or `Demo_ReadInput`. Without the demos recording, that
whole subsystem has no runtime coverage at all.

## Running it

```bash
make build-gens        # Clone and build the instrumented emulator (VS2022)
make trace-runtime     # Capture, then validate
```

Captures are written under `build/runtime/`, which is ignored. Regenerating
them into an ignored directory is deliberate: a stale local capture must not be
able to mask a regression.

To compare against a known-good capture:

```bash
python scripts/validate_runtime_scenarios.py \
    --capture-dir build/runtime --reference-dir reference/runtime
```

Without `--reference-dir` the validator only confirms that each scenario
produced frames. That is a liveness check, not evidence, and it says so in its
output.

## What this layer can and cannot prove

It observes behaviour, which no other check in
[`validation.md`](validation.md) does. `make verify` proves the bytes are
right; only a replay proves the bytes still do what they used to after a change
to the tooling, the data extraction or the build.

It cannot prove a name is correct. A scenario that reaches the bonus round
confirms the bonus round runs; it says nothing about whether
`Ram_BonusCaughtCount` counts what its name claims. That distinction is why
[`unknowns.md`](unknowns.md) exists.

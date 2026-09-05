# Input movies

Two Gens `.gmv` recordings, used as the deterministic inputs for the analysis
and runtime-evidence workflows.

## Content boundary

A `.gmv` file is recorded controller input plus a small header. It contains no
ROM data, no code, no graphics, no audio and no savestate. That is why these
files are tracked while everything derived from the cartridge is not.

## Files

| File | Bytes | SHA-1 |
| --- | ---: | --- |
| `flicky_longplay.gmv` | 188,908 | `df655c49ff072706dc4edc66fc01cb3b0f3ebf1c` |
| `flicky_demos.gmv` | 69,670 | `e490c5977ff3d2b55bd14fd3b09fc0507e075990` |

Both are recorded against the reference ROM,
SHA-1 `83d8bbf0a9b38c42a0bf492d105cc3abe9644a96`. Replaying them against any
other revision desynchronises immediately and proves nothing.

### `flicky_longplay.gmv`

A complete play-through. This is the input that exercises the most code: every
round type, the bonus round, the score screens and the ending. The analysis
workflow caps it at 67,000 frames.

### `flicky_demos.gmv`

Idles at the title screen so the attract-mode demos play out. This is the only
input that reaches `Demo_Init` and the four recorded demo streams, which the
longplay never touches because it presses start first.

## Scene indexes

`longplay_description.txt` and `demos_description.txt` map frame ranges to
scenes. They are how a screenshot diff at frame *n* gets turned into "the guide
screen broke" rather than "frame 512 differs".

## Regenerating

These are fixtures, not build outputs. Re-recording them invalidates every
frame number in the description files and in any runtime scenario that pins the
movie SHA-1, so replace them only deliberately and update the hashes here in
the same change.

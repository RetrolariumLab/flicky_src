# Input movies

Two recordings, the deterministic inputs that `make test-full` plays in MAME on
the relocated build (their checks: `longplay.check.json` and
`attract.check.json`, whose `title` and `description` Retrolarium shows). They
were recorded in Gens as `.gmv` against the reference ROM and converted to
Retrolarium's run-length `.rlmovie` (`rltool movie convert`); the frames and
inputs are unchanged. Replaying them against any other ROM desynchronises
immediately and proves nothing.

## Content boundary

A movie is recorded controller input. It contains no ROM data, no code, no
graphics, no audio and no savestate. That is why these files are tracked while
everything derived from the cartridge is not.

## `longplay.rlmovie`

A complete play-through. This is the input that exercises the most code: every
round type, the bonus round, the score screens and the ending.

## `attract.rlmovie`

The title idles so the four recorded attract demos play out (rounds 1, 10, 20
and 24), then the movie plays rounds 1-4 to a game over. This is the only input
that reaches `Demo_Init` and the demo streams, which the longplay never touches
because it presses start first.

## Scene indexes

`longplay.scenes.txt` and `attract.scenes.txt` map frame ranges to scenes, so
you can tell which scene a checkpoint frame falls in.

## Regenerating

These are fixtures, not build outputs. Re-recording one invalidates every frame
number in its scene list and the check's expected values, so replace it only
deliberately and run `make golden` in the same change.

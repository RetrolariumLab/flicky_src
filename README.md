# Flicky (Sega Mega Drive) Disassembly

An annotated reconstruction of Flicky for the Sega Mega Drive, built back byte
for byte into the original cartridge dump. The source assembles with the AS
Macro Assembler and `p2bin` that Retrolarium Kit ships.

## Status

Source Reconstruction 3.1. Editing happens in Retrolarium Studio: open
`flicky.rlj` to edit the rounds, graphics, palettes, text, music, sound effects
and the attract demos ([`docs/retrolarium.md`](docs/retrolarium.md)).

3.1 keeps only what builds and checks the source. The earlier releases' audits,
runtime scenarios, analysis and renaming workflow, data round trips and the Gens
tooling remain in the history (tags `source-reconstruction-1.0` to `3.0`).

## Quick start

You need Python 3, GNU Make and Retrolarium Kit (`rltool` on `PATH`, or
`RLTOOL=...`). Copy your `Flicky (UE) [!].bin` into the repository root, then:

```bash
make split     # cut data/ out of the ROM (once)
make verify    # build build/flicky.bin and compare it byte for byte
```

`make` alone lists the targets. `assets/manifest.json` names the ROM and the
segments cut out of it (`rltool assets`, Retrolarium Kit). The ROM, `data/` and
`build/` are ignored. See
[`docs/build.md`](docs/build.md) for the build in detail.

## Targets

```bash
make build / verify          # the ROM, and byte for byte
make build-relocated         # the ROM with its code and data moved
make studio-check            # open and rebuild flicky.rlj
make test / test-full        # the checks
make golden                  # the movies' reference values
make play [MOVIE=attract]    # watch a movie in MAME (longplay unless given)
make lint / format / hooks / clean
```

## Tests

`make test` (about a minute) runs the unit tests, `verify`, `build-relocated`
and the studio check. The studio check needs the studio's
Flicky level writer (`RETROLARIUM_FLICKY_LEVEL_WRITER`, or on `PATH`).

`make test-full` adds the two recordings of `movies/`, played in MAME on the
relocated build, in which a NOP follows every module from the startup code on
and both layout gaps are closed, so the game code moves from `$010000` to near
`$2900`: the longplay through the ending first, then the attract demos. At
their checkpoints the game's state must equal what the original ROM gives, as
`movies/*.check.json` record. Name MAME once with `rltool movie mame <path>`
(or `MAME=<path>`); `make golden` records the reference values again.

`make play MOVIE=longplay|attract` shows a movie in a MAME window at the game's
speed, on the relocated build (or on `ROM=<image>`), and compares its cells
with the original's once the window is closed; in MAME, F10 lifts the speed
limit and Insert fast-forwards. `FRAMES=<frame>` closes MAME at that frame, `CLOSE=1`
when the movie ends. `make play` alone plays `longplay`.

## Layout

```text
src/           the 68000 source (main.s is the ROM layout) and the Z80 driver
config/        lint and names
assets/        manifest.json (the extracted data/ is ignored)
scripts/       build and relocation scripts (scripts/run.py runs them, as
               Retrolarium Studio's Flicky build does)
tests/         their unit tests
movies/        the two recordings and their checks
docs/          how the game works and how the source is written
flicky.rlj     the Retrolarium project
```

## Game information

| | |
|---|---|
| **Title** | FLICKY |
| **Platform** | Sega Mega Drive / Genesis |
| **Release** | February 1991 |
| **Product code** | GM 00001022-00 |
| **ROM size** | 128 KB |
| **Regions** | Japan, USA, Europe |

Bit 7 of the version register selects the domestic revision, so the ROM carries
two sets of on-screen text: Japanese for Japan and English elsewhere. Symbols
for the Japanese variants carry a `JP` suffix.

## Known gaps

- **Nemesis does not re-encode byte for byte.** The six Nemesis streams
  round-trip semantically with smaller valid encodings. Tracked as DATA-002; see
  [`docs/data_formats.md`](docs/data_formats.md).
- Further open questions are listed in [`docs/unknowns.md`](docs/unknowns.md).

## Credits

- Approaches shared with [alien_soldier_src](https://github.com/oranguthang/alien_soldier_src)
- AS Macro Assembler by Alfred Arnold
- Original game by Sega

## Trademarks

This is an unofficial reconstruction, made for study and preservation. The game,
its title and its characters are trademarks of their owners, who have not made,
licensed or endorsed this project. It contains no part of the game: you need
your own copy of Flicky to build anything.

## License

Reverse engineering for educational and preservation purposes. No original ROM
data is distributed with this repository. The original game is copyright Sega.

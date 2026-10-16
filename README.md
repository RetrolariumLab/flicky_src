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
`RLTOOL=...`). Copy your `Flicky (UE) [!].bin` (SHA-1
`83d8bbf0a9b38c42a0bf492d105cc3abe9644a96`) into the repository root, then:

```bash
make split     # cut data/ out of the ROM (once)
make verify    # build and compare byte for byte
```

`assets/manifest.json` names the ROM and the segments cut out of it
(`rltool assets`, Retrolarium Kit). The ROM, `data/`, `fbuilt.bin` and `build/`
are ignored. See
[`docs/build.md`](docs/build.md) for the build in detail.

## Targets

```bash
make build / verify          # the ROM, and byte for byte
make verify-layout           # the module layout against the listing
make build-relocated         # the ROM with its code and data moved
make studio-check            # open and rebuild flicky.rlj
make test / test-full        # the checks
make golden                  # the movies' reference values
make lint / format / format-check / hooks / clean / help
```

## Tests

`make test` (about a minute) runs the unit tests, `verify`, `verify-layout`,
`build-relocated` and the studio check. The studio check needs the studio's
Flicky level writer (`RETROLARIUM_FLICKY_LEVEL_WRITER`, or on `PATH`).

`make test-full` adds the two Gens recordings of `movies/`, played in MAME on
the relocated
build, in which a NOP follows every module from the startup code on and both
layout gaps are closed, so the game code moves from `$010000` to near `$2900`: the longplay through the ending first, then the attract
demos. At their checkpoints the
game's state must equal what the original ROM gives, as `movies/*.check.json`
record. Name MAME with `MAME=<path>` or `RETROLARIUM_MAME`; `make golden` records
the reference values again.

## Layout

```text
src/           the 68000 source (main.s is the ROM layout) and the Z80 driver
config/        linker layout, toolchain, lint and names
assets/        manifest.json (the extracted data/ is ignored)
scripts/       build, layout and relocation scripts (scripts/run.py runs them)
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

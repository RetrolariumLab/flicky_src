# Building

```bash
make verify
```

That is the whole thing, once the inputs are in place. It assembles the source
into `build/flicky.bin` and requires that image to equal the cartridge byte for
byte; any difference fails with the first differing offset.

## What you have to supply

Two things are never in this repository, because both are the game.

**The cartridge**, `Flicky (UE) [!].bin`, in the project root.
`assets/manifest.json` gives its size and SHA-1.

**The extracted segments** under `data/`, which come out of it:

```bash
make split     # check the cartridge and cut the segments out of it
```

`make split` (`rltool assets split`, Retrolarium Kit) checks the cartridge and
every segment against the manifest; it is the only command that writes `data/`.
`build` first checks that every segment is there, so a missing one fails by name
rather than as a byte difference.

## The pipeline

```text
src/sound/z80/driver.asm --[asl, p2bin]--> build/z80_driver.bin
src/sound/z80/data.asm   --[asl, p2bin]--> build/z80_sound_data_sfx.bin, _music.bin
src/main.s --[asl]--> build/main.p --[p2bin -p=FF]--> build/flicky.bin --[rltool assets verify]--> the cartridge
```

**The Z80 parts.** The sound driver and the sound-data banks are separate
assembly units; `build_z80_driver.py` assembles each, and splits the data at
`zMusicBank` into the sound-effect and music banks. The 68000 source includes
the results with `binclude`.

**Assembling.** `src/main.s` includes 36 modules in ROM address order and AS
assembles all of it as one unit, so every label is global. Includes are written
relative to `src/main.s`; `-i <project root>` lets a module under `src/` reach
`data/` and `build/` with `binclude`.

**Converting.** `p2bin` flattens the object into the cartridge image with
`-p=FF`: the cartridge pads unused space with `$FF` and p2bin defaults to `$00`.
The converter writes a temporary file first and replaces the ROM only after it
succeeds.

**Comparing.** `rltool assets verify` compares the result with the cartridge
byte by byte.

## The toolchain

AS 1.42 Beta [Bld 212] and the Sonic-disassembly variant of Clownacy's `p2bin`,
as Retrolarium Kit builds, ships and verifies them
(`rltool build-tools path megadrive asl` and `p2bin`; `RLTOOL` names the kit
command). AS reads its message catalogs from beside the assembler
(`AS_MSGPATH`). The kit has builds for Windows and Linux x86-64; this repository
holds no executables. Releases 1.0 and 2.0 vendored the tools under `bin/`; they
stay at those tags.

Byte identity makes the assembler an architectural choice: it determines which
encodings are reachable and how data directives, alignment and padding behave.
ca65 cannot assemble 68000 code, and the established Mega Drive disassembly
syntax targets AS.

## What gets written

Everything under `build/`, which `make clean` removes: the object files, the Z80
parts, `flicky.bin` and the relocated build in `build/relocated/`.

## When the build disagrees

**A segment is missing.** Run `make split` against the correct cartridge;
`rltool assets check --exact` compares every segment with the manifest.

**The assembler reports an error.** The listing gives the file and line.

**`make verify` reports a differing offset.** The source now assembles to
something else; the address comments in `src/main.s` say which module owns that
offset.

## The checks

`make test` runs the unit tests, `verify`, `build-relocated` and the studio
check. `make test-full` then plays the longplay and the attract demos in MAME on
the relocated build, in which a NOP follows every module from the startup code
on and both layout gaps are closed, so the game code moves from `$010000` to
near `$2900`, and compares the game's state at their checkpoints with what the
original ROM gives (`movies/*.check.json`, recorded by `make golden`).

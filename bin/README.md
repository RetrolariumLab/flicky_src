# Vendored toolchain

This directory contains the AS Macro Assembler and its `p2bin` companion, plus
the standalone Sound Studio audio renderer. They are vendored so that a fresh
clone can reproduce the reference build and preview audio without hunting for
matching tool releases.

## Content boundary

These files are a general-purpose assembler and object converter. They contain
no Flicky code, data, or graphics, and no part of any Sega ROM.

## Upstream

- **AS Macro Assembler** by Alfred Arnold — <http://john.ccac.rwth-aachen.de:8000/as/>
- Version reported by the executables: `Macro Assembler 1.42 Beta [Bld 212]`
- `p2bin` is Clownacy's Sonic-disassembly converter from
  <https://github.com/Clownacy/p2bin>, pinned to commit
  `e26d8aa8c43e285bac5e3b7df3be1adae515994f`. It accepts the required `-p=`
  padding and `-z=` Z80 compression options.
- The Windows executable is the Microsoft Visual C++ 12.0 rebuild recorded by
  `sonicretro/s1disasm` commit `da7457dae9ad2b5dc2147b04c347d81b0dafca8d`.
  The Linux executable is the build recorded by commit
  `1ce386fc63bcef58d53f87d51a2e8620ff24de9a` in the same repository.

The same binaries are used by the sibling `alien_soldier_src` project; the
Windows files are byte-identical to the ones vendored there.

## Layout

The Makefile selects a subdirectory from the host OS and architecture, and
`AS_MSGPATH` is pointed at it so the assembler finds its message catalogs.
Override the choice with `make PLATFORM=<subdirectory>`.
`AS_BIN` and `P2BIN` may select another location only when the resolved files
match the approved executable identities for that platform. The build hashes
those selected paths before invoking either program.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `windows_i386/as.msg` | 26,005 | `92be47faed496e90ab5b1e1298325d9a4f0f1540e9fb69685baa291f117890ab` |
| `windows_i386/asw.exe` | 2,718,552 | `02bcdccc6a887aa94d382059e4f4a83a0d5bd87246aa586e1b6692c1c2e3c896` |
| `windows_i386/cmdarg.msg` | 307 | `83aabb22cdde0fd0579d5cf5f39af9ccae4639465286c1c109d8bbfa1ec6bc62` |
| `windows_i386/ioerrs.msg` | 2,862 | `1f5e97d35696caf34eef35923b8280cb1ff483772cec0d60c765d3af13c09097` |
| `windows_i386/p2bin.exe` | 28,672 | `1323430afdfa630ab56ce76f0286ccbb05a04566126411d4b7d673f2a08115eb` |
| `windows_i386/ymfm_renderer.exe` | 2,640,167 | `6815d01e7e0e5af7ead14947758001a433b73e871e486a421e230a91e48d7191` |
| `linux_x86_64/as.msg` | 26,005 | `18542d756467b567cf7713d4ee95081d784d8cf11575a7bb57516fc2c5c1c594` |
| `linux_x86_64/asl` | 2,372,248 | `be2ffab7be719e9c2b5452655be8ce40ad9888d04084e397687f23b6f8b85f1c` |
| `linux_x86_64/cmdarg.msg` | 307 | `aaa93507412473a546276128bd58a01ac9119979e80b1ef79b3671b602eade0e` |
| `linux_x86_64/ioerrs.msg` | 2,862 | `5da942aa76c3ed784d967ba795543d87d3a52b80d5812737e12f18f3b2c94fba` |
| `linux_x86_64/p2bin` | 31,040 | `969c1df15a15ef32bc25124093228dab3b81906d772f37fc873e00bb70a94459` |

The message catalogs differ between the two platforms only in line endings.

## Padding byte

`p2bin` must be invoked with `-p=FF`. The original cartridge pads unused ROM
space with `$FF`; p2bin's default of `$00` produces a ROM that differs from the
reference in every gap — 73,045 bytes of the 128 KiB image. The padding byte is
recorded in `assets/manifest.json` and applied by `scripts/build/build_rom.py`.

## License

AS is distributed under its own license; see the upstream site. It is included
here unmodified for reproducibility. `ymfm_renderer.exe` links the unmodified
BSD-3-Clause ymfm core vendored with its license under `third_party/ymfm`; its
project-specific native frontend is in `scripts/authoring/ymfm_renderer` and is
built through `python scripts/run.py authoring.build_ymfm_renderer`.

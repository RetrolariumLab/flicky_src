#!/usr/bin/env python3
"""Pack the ROM without its two layout gaps and validate relocatable sound loads."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

from debug_symbols import collect_from_listing


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def without_line(text: str, line: str, source: Path) -> str:
    if text.count(line) != 1:
        fail(f"expected exactly one {line.strip()!r} in {source}")
    return text.replace(line, "", 1)


def run(command: list[str], cwd: Path | None = None) -> None:
    print(f"[RUN] {' '.join(command)}")
    result = subprocess.run(command, cwd=str(cwd) if cwd else None)
    if result.returncode:
        fail(f"command failed with exit code {result.returncode}")


def words(data: bytes) -> tuple[int, ...]:
    return tuple(int.from_bytes(data[index:index + 2], "big") for index in range(0, len(data), 2))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default="src/main.s")
    parser.add_argument("--bank0", default="src/data/bank0.s")
    parser.add_argument("--tables", default="src/data/tables.s")
    parser.add_argument("--sound-data", default="build/z80_sound_data.bin")
    parser.add_argument("--output-dir", default="build/relocation")
    parser.add_argument("--as-bin", default="bin/windows_i386/asw.exe")
    parser.add_argument("--p2bin", default="bin/windows_i386/p2bin.exe")
    parser.add_argument("--as-args", default="-maxerrors 2")
    args = parser.parse_args()

    root = Path.cwd().resolve()
    source = Path(args.source)
    bank0 = Path(args.bank0)
    tables = Path(args.tables)
    sound_data = Path(args.sound_data)
    as_bin = Path(args.as_bin).resolve()
    p2bin = Path(args.p2bin).resolve()
    output_dir = Path(args.output_dir)
    for path in (source, bank0, tables, sound_data, as_bin, p2bin):
        if not path.is_file():
            fail(f"required file not found: {path}")

    output_dir.mkdir(parents=True, exist_ok=True)
    packed_main = output_dir / "main.s"
    packed_bank0 = output_dir / "bank0.s"
    packed_tables = output_dir / "tables.s"
    obj = output_dir / "main.p"
    listing = output_dir / "main.lst"
    rom_path = output_dir / "flicky_packed.bin"

    main_text = source.read_text(encoding="utf-8")
    # The temporary top-level file no longer lives beside src/main.s, so make
    # its include paths explicitly project-root-relative.
    main_text = main_text.replace('include "', 'include "src/')
    main_text = main_text.replace(
        'include "src/data/bank0.s"', 'include "build/relocation/bank0.s"', 1
    ).replace(
        'include "src/data/tables.s"', 'include "build/relocation/tables.s"', 1
    )
    packed_main.write_text(main_text, encoding="utf-8", newline="\n")
    packed_bank0.write_text(
        without_line(bank0.read_text(encoding="utf-8"), "                org     $10000\n", bank0),
        encoding="utf-8",
        newline="\n",
    )
    packed_tables.write_text(
        without_line(
            tables.read_text(encoding="utf-8"),
            "                org     $1FFFF\n",
            tables,
        ),
        encoding="utf-8",
        newline="\n",
    )

    command = [
        str(as_bin), "-i", str(root), "-L", "-olist", str(listing.resolve()),
        "-o", str(obj.resolve()), *args.as_args.split(),
        os.path.relpath(packed_main.resolve(), as_bin.parent),
    ]
    run(command, cwd=as_bin.parent)
    run([str(p2bin), str(obj.resolve()), str(rom_path.resolve()), "-p=FF"])

    symbols = collect_from_listing(listing)
    required = (
        "Sys_GameEntryPoint", "Data_Z80Driver2", "Data_Z80SFXBank",
        "Data_Z80Driver2_End", "Sound_LoadZ80Table",
    )
    missing = [name for name in required if name not in symbols]
    if missing:
        fail(f"packed listing is missing symbols: {', '.join(missing)}")

    game = symbols["Sys_GameEntryPoint"]
    descriptor = symbols["Data_Z80Driver2"]
    sfx = symbols["Data_Z80SFXBank"]
    music = sfx + 0x1C8
    end = symbols["Data_Z80Driver2_End"]
    if game == 0x10000:
        fail("packing did not move Sys_GameEntryPoint")

    rom = rom_path.read_bytes()
    actual = words(rom[descriptor:descriptor + 12])
    expected = (
        music - sfx, 0x1000, sfx - game,
        end - music, 0x1200, music - game,
    )
    if actual != expected:
        fail(
            "relocated sound descriptors disagree: "
            f"actual {actual!r}, expected {expected!r}"
        )

    load_routine = symbols["Sound_LoadZ80Table"]
    if b"\x91\xFC\x00\x01\x00\x00" not in rom[load_routine:load_routine + 16]:
        fail("Sound_LoadZ80Table no longer maps offsets through the 64 KiB RAM window")

    ram_base = 0xFF0000
    loaded_sources = (
        (actual[2] - 0x10000) & 0xFFFFFF,
        (actual[5] - 0x10000) & 0xFFFFFF,
    )
    expected_sources = (ram_base + sfx - game, ram_base + music - game)
    if loaded_sources != expected_sources:
        fail(
            f"relocated runtime sources {loaded_sources!r} do not map to "
            f"work-RAM data {expected_sources!r}"
        )

    authored = sound_data.read_bytes()
    if rom[sfx:sfx + len(authored)] != authored:
        fail("packed ROM does not contain the authored Z80 sound banks")

    print(
        f"[OK] packed relocation moves game entry ${0x10000:06X} -> ${game:06X}; "
        f"sound sources map to ${loaded_sources[0]:06X} and ${loaded_sources[1]:06X}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Assemble one Flicky Z80 sound component and verify its byte identity."""

from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def run(command: list[str], cwd: Path | None = None) -> None:
    print(f"[RUN] {' '.join(command)}")
    result = subprocess.run(command, cwd=str(cwd) if cwd else None)
    if result.returncode:
        fail(f"command failed with exit code {result.returncode}")


def sha1(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default="src/sound/z80_driver_z80.asm")
    parser.add_argument("--obj", default="build/z80_driver.p")
    parser.add_argument("--output", default="build/z80_driver.bin")
    parser.add_argument("--reference", default="data/sound/data_z80_part1.bin")
    parser.add_argument("--reference-offset", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--description", default="Z80 driver")
    parser.add_argument("--as-bin", default="bin/windows_i386/asw.exe")
    parser.add_argument("--p2bin", default="bin/windows_i386/p2bin.exe")
    parser.add_argument("--as-args", default="-maxerrors 2")
    args = parser.parse_args()

    source = Path(args.source).resolve()
    obj = Path(args.obj).resolve()
    output = Path(args.output).resolve()
    reference = Path(args.reference)
    as_bin = Path(args.as_bin).resolve()
    p2bin = Path(args.p2bin).resolve()

    for path, description in ((source, "source"), (reference, "reference image"),
                              (as_bin, "assembler"), (p2bin, "converter")):
        if not path.is_file():
            fail(f"Z80 {description} not found: {path}")

    obj.parent.mkdir(parents=True, exist_ok=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    obj.unlink(missing_ok=True)
    output.unlink(missing_ok=True)

    # AS finds its message catalog beside the executable. Source includes still
    # resolve from the project root through -i, just like the 68000 build.
    command = [
        str(as_bin), "-i", str(Path.cwd().resolve()), "-o", str(obj),
        *args.as_args.split(), os.path.relpath(source, as_bin.parent),
    ]
    run(command, cwd=as_bin.parent)
    run([str(p2bin), str(obj), str(output)])

    built = output.read_bytes()
    reference_data = reference.read_bytes()
    if args.reference_offset > len(reference_data):
        fail(
            f"reference offset {args.reference_offset} exceeds "
            f"{len(reference_data)}-byte reference image"
        )
    expected = reference_data[args.reference_offset:]
    if built != expected:
        offset = next(
            (index for index, pair in enumerate(zip(built, expected))
             if pair[0] != pair[1]),
            min(len(built), len(expected)),
        )
        fail(
            f"{args.description} differs at ${offset:04X}; "
            f"built {len(built)} bytes ({sha1(built)}), "
            f"expected {len(expected)} bytes ({sha1(expected)})"
        )

    print(
        f"[OK] Byte-identical {args.description} reproduced "
        f"({len(built)} bytes, SHA1 {sha1(built)})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

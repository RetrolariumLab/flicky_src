#!/usr/bin/env python3
"""Assemble one Flicky Z80 sound component and optionally verify byte identity."""

from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
import sys
from pathlib import Path

from validation.debug_symbols import collect_from_listing


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
    parser.add_argument("--source", default="src/sound/z80/driver.asm")
    parser.add_argument("--obj", default="build/z80_driver.p")
    parser.add_argument("--output", default="build/z80_driver.bin")
    parser.add_argument("--reference", default="data/sound/data_z80_part1.bin")
    parser.add_argument("--reference-offset", type=lambda value: int(value, 0), default=0)
    parser.add_argument("--description", default="Z80 driver")
    parser.add_argument("--as-bin", default="bin/windows_i386/asw.exe")
    parser.add_argument("--p2bin", default="bin/windows_i386/p2bin.exe")
    parser.add_argument("--as-args", default="-maxerrors 2")
    parser.add_argument(
        "--allow-different",
        action="store_true",
        help="allow authored content to differ from the reference image",
    )
    parser.add_argument(
        "--expected-size",
        type=lambda value: int(value, 0),
        help="require the assembled component to occupy this many bytes",
    )
    parser.add_argument("--split-label", help="emit separate binaries at this source label")
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
        *(["-L", "-olist", str(obj.with_suffix(".lst"))] if args.split_label else []),
        *args.as_args.split(), os.path.relpath(source, as_bin.parent),
    ]
    run(command, cwd=as_bin.parent)
    run([str(p2bin), str(obj), str(output)])

    built = output.read_bytes()
    if args.expected_size is not None and len(built) != args.expected_size:
        fail(
            f"{args.description} is {len(built)} bytes; "
            f"the fixed region requires {args.expected_size} bytes"
        )
    reference_data = reference.read_bytes()
    if args.reference_offset > len(reference_data):
        fail(
            f"reference offset {args.reference_offset} exceeds "
            f"{len(reference_data)}-byte reference image"
        )
    expected = reference_data[args.reference_offset:]
    if built != expected and not args.allow_different:
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

    if args.split_label:
        symbols = collect_from_listing(obj.with_suffix(".lst"))
        boundary = symbols.get(args.split_label)
        if boundary is None or not 0 < boundary < len(built):
            fail(f"split label {args.split_label} has no valid position in {source}")
        output.with_name(f"{output.stem}_sfx.bin").write_bytes(built[:boundary])
        output.with_name(f"{output.stem}_music.bin").write_bytes(built[boundary:])

    if built == expected:
        print(
            f"[OK] Byte-identical {args.description} reproduced "
            f"({len(built)} bytes, SHA1 {sha1(built)})"
        )
    else:
        print(
            f"[OK] Authored {args.description} assembled within its fixed region "
            f"({len(built)} bytes, SHA1 {sha1(built)})"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

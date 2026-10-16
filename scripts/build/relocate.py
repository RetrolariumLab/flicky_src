#!/usr/bin/env python3
"""Build Flicky with its code and data moved (build/relocated/flicky.bin).

A copy of src/main.s puts a never-reached NOP ($4E71, two bytes so every
address keeps its parity) after each module from the startup code on, so
each module moves a little further than the one before, and drops the two
layout gaps (`org $10000` in bank0.s, `org $1FFFF` in tables.s), so the
second half of the ROM moves back by most of a bank. The image is padded
with $FF to the original 128 KiB and gets a fresh ROM end and checksum, so the
game boots from it. The movies played on this build in MAME show that nothing
depends on the original addresses.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ROM_SIZE = 0x20000
INCLUDE_RE = re.compile(r'^(?P<indent>\s+)include\s+"(?P<path>[^"]+)"(?P<tail>.*)$')
NOP = "                dc.w    $4E71                   ; relocation probe"
GAPS = {
    "data/bank0.s": "                org     $10000\n",
    "data/tables.s": "                org     $1FFFF\n",
}
FIRST_MODULE = "system/startup.s"


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def runnable(rom: bytes) -> bytes:
    """The moved image as a cartridge the game boots from: padded with $FF to
    the original size, ROM end and checksum ($18E, the word sum of everything
    after the header) updated in the header."""
    if len(rom) > ROM_SIZE:
        fail(f"relocated ROM is {len(rom)} bytes, more than {ROM_SIZE}")
    image = bytearray(rom + b"\xff" * (ROM_SIZE - len(rom)))
    image[0x1A4:0x1A8] = (ROM_SIZE - 1).to_bytes(4, "big")
    checksum = sum(int.from_bytes(image[i:i + 2], "big") for i in range(0x200, ROM_SIZE, 2)) & 0xFFFF
    image[0x18E:0x190] = checksum.to_bytes(2, "big")
    return bytes(image)


def relocated_main(source: Path, output_dir: Path) -> tuple[str, int]:
    """The relocated main source (paths from the project root) and the number
    of probes; the gap-free copies of the two modules go to output_dir."""
    lines = []
    probes = 0
    moving = False
    modules = [m.group("path") for line in source.read_text(encoding="utf-8").splitlines()
               if (m := INCLUDE_RE.match(line)) and m.group("path").endswith(".s")]
    last = modules[-1]
    for line in source.read_text(encoding="utf-8").splitlines():
        match = INCLUDE_RE.match(line)
        if match is None:
            lines.append(line)
            continue
        name = match.group("path")
        path = f"src/{name}"
        if name in GAPS:
            copy = output_dir / Path(name).name
            text = (source.parent / name).read_text(encoding="utf-8")
            if text.count(GAPS[name]) != 1:
                fail(f"expected one {GAPS[name].strip()!r} in src/{name}")
            copy.write_text(text.replace(GAPS[name], "", 1), encoding="utf-8", newline="\n")
            path = copy.as_posix()
        lines.append(f'{match.group("indent")}include "{path}"{match.group("tail")}')
        moving = moving or name == FIRST_MODULE
        if moving and name.endswith(".s") and name != last:
            lines.append(NOP)
            probes += 1
    return "\n".join(lines) + "\n", probes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--source", default="src/main.s")
    parser.add_argument("--output-dir", default="build/relocated")
    parser.add_argument("--as-bin", required=True)
    parser.add_argument("--p2bin", required=True)
    parser.add_argument("--as-args", default="-maxerrors 2")
    args = parser.parse_args()

    root = Path.cwd().resolve()
    as_bin = Path(args.as_bin).resolve()
    p2bin = Path(args.p2bin).resolve()
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    text, probes = relocated_main(Path(args.source), output_dir)
    main_path = output_dir / "main.s"
    main_path.write_text(text, encoding="utf-8", newline="\n")
    obj = output_dir / "main.p"
    rom_path = output_dir / "flicky.bin"
    # AS finds its message catalogs through AS_MSGPATH (the assembler's folder).
    environment = dict(os.environ)
    environment.setdefault("AS_MSGPATH", str(as_bin.parent))
    for command in ([str(as_bin), "-i", str(root), "-o", str(obj.resolve()), *args.as_args.split(),
                     str(main_path.resolve())],
                    [str(p2bin), str(obj.resolve()), str(rom_path.resolve()), "-p=FF"]):
        result = subprocess.run(command, env=environment, capture_output=True, text=True)
        if result.returncode:
            fail(f"{Path(command[0]).name} failed:\n{result.stdout}{result.stderr}")
    rom_path.write_bytes(runnable(rom_path.read_bytes()))
    print(f"[OK] Relocated build ({probes} probes, both layout gaps closed): {rom_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

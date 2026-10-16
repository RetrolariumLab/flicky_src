#!/usr/bin/env python3
"""Assemble the Flicky source into the ROM image (`rltool assets verify`
compares it with the cartridge)."""

from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
import sys
import tempfile
from pathlib import Path


# The cartridge pads unused space with $FF; p2bin would pad with $00.
PADDING = "FF"


def info(message: str) -> None:
    print(f"[INFO] {message}")


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def sha1_of(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def as_environment(as_bin: Path) -> dict[str, str]:
    """AS reads its message catalogs from AS_MSGPATH, which is the
    assembler's own folder unless the caller names another."""
    environment = dict(os.environ)
    environment.setdefault("AS_MSGPATH", str(as_bin.resolve().parent))
    return environment


def run(command: list[str], env: dict[str, str] | None = None) -> int:
    print(f"[RUN] {' '.join(command)}")
    return subprocess.call(command, env=env)


def assemble(source: Path, as_bin: Path, as_args: list[str], include_root: Path,
             obj: Path) -> Path:
    """Run AS on the source. AS is invoked from its own directory so that it
    finds the message catalogs (as.msg, cmdarg.msg, ioerrs.msg) beside it.

    AS resolves include paths relative to the including file, so src/main.s
    reaches its modules by their path under src/. It resolves binclude the same
    way, which a module under src/ cannot use to reach data/; passing the
    project root as a search path is what lets it.

    The object file is named explicitly with -o. Left to itself AS writes it
    beside the source, which would drop a build artifact into src/.
    """
    obj.parent.mkdir(parents=True, exist_ok=True)
    if obj.exists():
        obj.unlink()
    command = [
        str(as_bin.resolve()),
        "-i", str(include_root.resolve()),
        "-o", str(obj.resolve()),
        *as_args,
        str(source.resolve()),
    ]
    if run(command, env=as_environment(as_bin)) != 0:
        fail("Assembly failed")
    if not obj.is_file():
        fail(f"Object file not produced: {obj}")
    return obj


def link(obj: Path, output: Path, p2bin: Path, padding: str) -> None:
    """Convert the AS object file into a flat ROM image.

    The padding byte matters for byte identity: the original cartridge pads
    unused space with $FF, so p2bin must be told to do the same. Its default
    of $00 silently produces a ROM that differs in every gap. Conversion uses
    a sibling temporary file so a failed process cannot damage a valid ROM.
    """
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        dir=output.parent,
        prefix=f".{output.name}.",
        suffix=".tmp",
    )
    os.close(descriptor)
    temporary = Path(temporary_name)
    temporary.unlink()
    try:
        if run(
            [str(p2bin.resolve()), str(obj), str(temporary), f"-p={padding}"]
        ) != 0:
            fail("p2bin conversion failed")
        if not temporary.is_file():
            fail(f"ROM not produced: {temporary}")
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default="src/main.s", help="Top-level assembly source")
    parser.add_argument("--obj", default="build/main.p", help="AS object file")
    parser.add_argument("--output", default="fbuilt.bin", help="Output ROM image")
    parser.add_argument("--as-bin", required=True, help="AS assembler executable")
    parser.add_argument("--p2bin", required=True, help="p2bin executable")
    parser.add_argument("--as-args", default="-maxerrors 2", help="Extra AS arguments")
    args = parser.parse_args()

    source = Path(args.source).resolve()
    as_bin = Path(args.as_bin)
    p2bin = Path(args.p2bin)
    for tool in (as_bin, p2bin):
        if not tool.is_file():
            fail(f"Toolchain executable not found: {tool}")

    obj = assemble(source, as_bin, args.as_args.split(), Path.cwd(), Path(args.obj))
    output = Path(args.output).resolve()
    link(obj, output, p2bin, PADDING)
    built = output.read_bytes()
    info(f"Built {output.name}: {len(built)} bytes, SHA1 {sha1_of(built)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

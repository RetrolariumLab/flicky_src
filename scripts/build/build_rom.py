#!/usr/bin/env python3
"""Assemble the Flicky source and optionally verify the ROM byte for byte."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def info(message: str) -> None:
    print(f"[INFO] {message}")


def ok(message: str) -> None:
    print(f"[OK] {message}")


def warn(message: str) -> None:
    print(f"[WARN] {message}")


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def sha1_of(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def load_manifest(path: Path) -> dict:
    if not path.is_file():
        fail(f"Asset manifest not found: {path}")
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1:
        fail(f"Unsupported manifest schema_version: {manifest.get('schema_version')}")
    return manifest


def run(command: list[str], cwd: Path | None = None) -> int:
    print(f"[RUN] {' '.join(command)}")
    return subprocess.call(command, cwd=str(cwd) if cwd else None)


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
    bin_dir = as_bin.parent
    obj.parent.mkdir(parents=True, exist_ok=True)
    if obj.exists():
        obj.unlink()
    command = [
        str(as_bin.resolve()),
        "-i", str(include_root.resolve()),
        "-o", str(obj.resolve()),
        *as_args,
        os.path.relpath(source, bin_dir),
    ]
    if run(command, cwd=bin_dir) != 0:
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


def first_difference(built: bytes, original: bytes) -> int | None:
    for index, (a, b) in enumerate(zip(built, original)):
        if a != b:
            return index
    if len(built) != len(original):
        return min(len(built), len(original))
    return None


def compare(built_path: Path, original_path: Path, manifest: dict, verify: bool) -> None:
    reference = manifest["reference_rom"]
    built = built_path.read_bytes()

    info(f"Built {built_path.name}: {len(built)} bytes, SHA1 {sha1_of(built)}")

    if not original_path.is_file():
        message = (
            f"Reference ROM not found: {original_path}. "
            "Byte identity was not verified."
        )
        fail(message) if verify else warn(message)
        return

    original = original_path.read_bytes()
    if sha1_of(original) != reference["sha1"]:
        fail(
            f"Reference ROM {original_path.name} does not match the manifest.\n"
            f"        expected SHA1 {reference['sha1']}\n"
            f"        actual   SHA1 {sha1_of(original)}"
        )

    if built == original:
        ok(f"Byte-identical ROM reproduced (SHA1 {sha1_of(built)})")
        return

    offset = first_difference(built, original)
    details = [f"Built ROM differs from {original_path.name}"]
    if len(built) != len(original):
        details.append(f"        size {len(built)} vs {len(original)}")
    if offset is not None and offset < min(len(built), len(original)):
        details.append(
            f"        first difference at 0x{offset:06X}: "
            f"built 0x{built[offset]:02X}, original 0x{original[offset]:02X}"
        )
    message = "\n".join(details)
    if verify:
        fail(message)
    warn(message)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default="src/main.s", help="Top-level assembly source")
    parser.add_argument("--obj", default="build/main.p", help="AS object file")
    parser.add_argument("--output", default="fbuilt.bin", help="Output ROM image")
    parser.add_argument("--manifest", default="assets/manifest.json", help="Asset manifest")
    parser.add_argument("--original-rom", default="Flicky (UE) [!].bin", help="Reference ROM")
    parser.add_argument("--as-bin", default="bin/asw.exe", help="AS assembler executable")
    parser.add_argument("--p2bin", default="bin/p2bin.exe", help="p2bin executable")
    parser.add_argument("--as-args", default="-maxerrors 2", help="Extra AS arguments")
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Treat any difference from the reference ROM as a hard failure",
    )
    args = parser.parse_args()

    manifest = load_manifest(Path(args.manifest))
    padding = manifest["reference_rom"].get("padding_byte", "0xFF")
    padding = padding[2:] if padding.lower().startswith("0x") else padding

    source = Path(args.source).resolve()
    as_bin = Path(args.as_bin)
    p2bin = Path(args.p2bin)
    for tool in (as_bin, p2bin):
        if not tool.is_file():
            fail(f"Toolchain executable not found: {tool}")

    obj = assemble(source, as_bin, args.as_args.split(), Path.cwd(), Path(args.obj))
    output = Path(args.output).resolve()
    link(obj, output, p2bin, padding)
    compare(output, Path(args.original_rom), manifest, args.verify)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

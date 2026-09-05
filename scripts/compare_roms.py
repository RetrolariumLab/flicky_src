#!/usr/bin/env python3
"""Compare an already built ROM with the reference cartridge dump."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def sha1_of(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def report_differences(built: bytes, original: bytes, limit: int = 5) -> None:
    if len(built) != len(original):
        print(f"[ERROR] Size mismatch: {len(built)} vs {len(original)} bytes", file=sys.stderr)

    shown = 0
    total = 0
    index = 0
    span = min(len(built), len(original))
    while index < span:
        if built[index] == original[index]:
            index += 1
            continue
        start = index
        while index < span and built[index] != original[index]:
            index += 1
        total += index - start
        if shown < limit:
            print(
                f"[ERROR] differs 0x{start:06X}-0x{index - 1:06X} ({index - start} bytes): "
                f"built {built[start:min(start + 8, index)].hex(' ')} | "
                f"original {original[start:min(start + 8, index)].hex(' ')}",
                file=sys.stderr,
            )
            shown += 1
    if shown == limit:
        print("[ERROR] ... further differing regions not listed", file=sys.stderr)
    print(f"[FAIL] {total} differing bytes of {span}", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--built", default="fbuilt.bin", help="Built ROM image")
    parser.add_argument("--original", default="Flicky (UE) [!].bin", help="Reference ROM")
    parser.add_argument("--manifest", default="assets/manifest.json", help="Asset manifest")
    args = parser.parse_args()

    built_path = Path(args.built)
    original_path = Path(args.original)

    if not built_path.is_file():
        fail(f"Built ROM not found: {built_path}. Run 'make build' first.")
    if not original_path.is_file():
        fail(
            f"Reference ROM not found: {original_path}. "
            "Place the original cartridge dump in the project root."
        )

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    expected = manifest["reference_rom"]["sha1"]

    original = original_path.read_bytes()
    actual = sha1_of(original)
    if actual != expected:
        fail(
            f"{original_path.name} is not the supported revision.\n"
            f"        expected SHA1 {expected}\n"
            f"        actual   SHA1 {actual}"
        )

    built = built_path.read_bytes()
    print(f"[INFO] built    {built_path.name}: {len(built)} bytes, SHA1 {sha1_of(built)}")
    print(f"[INFO] original {original_path.name}: {len(original)} bytes, SHA1 {actual}")

    if built == original:
        print("[OK] Byte-identical ROM reproduced from source")
        return 0

    report_differences(built, original)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

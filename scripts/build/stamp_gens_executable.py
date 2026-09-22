#!/usr/bin/env python3
"""Reproduce the approved Gens PE bytes after a Docker cross-build."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import struct
import tempfile
from pathlib import Path


class StampError(RuntimeError):
    """Report an executable that cannot match the approved build."""


def stamp_pe(data: bytes, timestamp: int) -> bytes:
    """Set the PE timestamp and recompute its image checksum."""
    if not isinstance(timestamp, int) or not 0 <= timestamp <= 0xFFFFFFFF:
        raise StampError("pe_timestamp must be a 32-bit unsigned integer")
    if len(data) < 64 or data[:2] != b"MZ":
        raise StampError("Gens executable has no DOS header")
    image = bytearray(data)
    pe_offset = struct.unpack_from("<I", image, 60)[0]
    timestamp_offset = pe_offset + 8
    checksum_offset = pe_offset + 88
    if checksum_offset + 4 > len(image) or image[pe_offset:pe_offset + 4] != b"PE\0\0":
        raise StampError("Gens executable has no valid PE header")

    struct.pack_into("<I", image, timestamp_offset, timestamp)
    struct.pack_into("<I", image, checksum_offset, 0)
    total = 0
    for index in range(0, len(image) - 1, 2):
        if index in (checksum_offset, checksum_offset + 2):
            continue
        total += image[index] + (image[index + 1] << 8)
        total = (total & 0xFFFF) + (total >> 16)
    if len(image) % 2:
        total += image[-1]
    total = (total & 0xFFFF) + (total >> 16)
    total = (total & 0xFFFF) + (total >> 16)
    struct.pack_into("<I", image, checksum_offset, total + len(image))
    return bytes(image)


def stamp_executable(config: Path, executable: Path) -> str:
    manifest = json.loads(config.read_text(encoding="utf-8"))
    emulator = next(
        (item for item in manifest["components"] if item.get("id") == "emulator"),
        None,
    )
    if emulator is None:
        raise StampError("emulator is absent from the toolchain manifest")
    timestamp = emulator.get("pe_timestamp")
    expected = emulator["files"]["any"][0]["sha256"]
    original = executable.read_bytes()
    stamped = stamp_pe(original, timestamp)
    digest = hashlib.sha256(stamped).hexdigest()
    if digest != expected:
        raise StampError(
            f"{executable}: stamped SHA-256 {digest} differs from approved {expected}"
        )
    if stamped != original:
        descriptor, temporary = tempfile.mkstemp(
            dir=executable.parent, prefix=f".{executable.name}.", suffix=".tmp"
        )
        try:
            with os.fdopen(descriptor, "wb") as output:
                output.write(stamped)
            os.chmod(temporary, stat.S_IMODE(executable.stat().st_mode))
            os.replace(temporary, executable)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
    return digest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=Path("config/toolchain.json"))
    parser.add_argument("--executable", type=Path, required=True)
    args = parser.parse_args()
    try:
        digest = stamp_executable(args.config, args.executable)
    except (StampError, OSError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"[ERROR] {error}")
        return 1
    print(f"[OK] Gens PE timestamp and checksum reproduce approved SHA-256 {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

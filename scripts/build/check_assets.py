#!/usr/bin/env python3
"""Validate the locally extracted ROM data segments without modifying them."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="assets/manifest.json", help="Asset manifest")
    parser.add_argument("--asset-dir", default="data", help="Directory holding the segments")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    if not manifest_path.is_file():
        fail(f"Asset manifest not found: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1:
        fail(f"Unsupported manifest schema_version: {manifest.get('schema_version')}")

    asset_dir = Path(args.asset_dir)
    problems: list[str] = []

    for asset in manifest["assets"]:
        path = asset_dir / asset["path"]
        if not path.is_file():
            problems.append(f"{asset['path']}: missing (run 'make split')")
            continue
        data = path.read_bytes()
        if len(data) != asset["size"]:
            problems.append(f"{asset['path']}: size {len(data)}, expected {asset['size']}")
            continue
        digest = hashlib.sha1(data).hexdigest()
        if digest != asset["sha1"]:
            problems.append(f"{asset['path']}: SHA1 {digest}, expected {asset['sha1']}")

    if problems:
        for problem in problems:
            print(f"[ERROR] {problem}", file=sys.stderr)
        print(
            f"[FAIL] {len(problems)} of {len(manifest['assets'])} extracted segments "
            "are missing or altered",
            file=sys.stderr,
        )
        return 1

    print(f"[OK] {len(manifest['assets'])} extracted segments match the manifest")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

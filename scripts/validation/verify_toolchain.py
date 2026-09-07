#!/usr/bin/env python3
"""Check the toolchain against the hashes config/toolchain.json records.

A byte-identical ROM is only evidence if the thing that produced it is known.
This runs before the build rather than after it, so a swapped assembler is
caught by name instead of showing up as a mysterious diff.

The emulator is pinned differently from the assembler. It is cross-built
locally rather than vendored, and a MinGW PE carries build-time fields, so its
identity is the upstream commit; the hash of the binary that actually ran is
recorded rather than required.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def platform_key(explicit: str | None) -> str:
    if explicit:
        return explicit
    return "windows_i386" if sys.platform == "win32" else "linux_x86_64"


def check_files(entries: list[dict], errors: list[str], notes: list[str]) -> int:
    checked = 0
    for entry in entries:
        path = Path(entry["path"])
        if not path.is_file():
            if entry.get("observed_only"):
                notes.append(f"{path} is not present; nothing to record")
                continue
            errors.append(f"{path} is missing")
            continue

        actual = sha256_of(path)
        size = path.stat().st_size
        if entry.get("observed_only"):
            if actual != entry["sha256"]:
                notes.append(
                    f"{path} is a different build than the one 1.0 captured with "
                    f"(sha256 {actual[:16]}...); the commit is what is pinned"
                )
            continue

        if size != entry["size"]:
            errors.append(f"{path} is {size} bytes, expected {entry['size']}")
        if actual != entry["sha256"]:
            errors.append(
                f"{path} does not match the recorded build\n"
                f"        expected sha256 {entry['sha256']}\n"
                f"        actual   sha256 {actual}"
            )
        checked += 1
    return checked


def check_commit(component: dict, errors: list[str], notes: list[str]) -> None:
    """For a source-built component, the pinned commit is the identity."""
    wanted = component.get("source_commit")
    if not wanted:
        return
    checkout = None
    for entries in component.get("files", {}).values():
        for entry in entries:
            checkout = Path(entry["path"]).parent.parent
            break
        break
    if checkout is None or not (checkout / ".git").exists():
        notes.append(f"{component['id']}: no checkout at {checkout}, commit not verified")
        return

    result = subprocess.run(
        ["git", "-C", str(checkout), "rev-parse", "HEAD"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        notes.append(f"{component['id']}: could not read the checkout's commit")
        return
    actual = result.stdout.strip()
    if actual != wanted:
        errors.append(
            f"{component['id']}: {checkout} is at {actual[:12]}, "
            f"but 1.0 pins {wanted[:12]}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config/toolchain.json")
    parser.add_argument("--platform", help="Toolchain subdirectory, else autodetected")
    parser.add_argument("--only", help="Check one component id")
    parser.add_argument(
        "--require-emulator", action="store_true",
        help="Fail when the emulator is absent instead of only noting it",
    )
    args = parser.parse_args()

    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    key = platform_key(args.platform)

    errors: list[str] = []
    notes: list[str] = []
    checked = 0

    for component in config["components"]:
        if args.only and component["id"] != args.only:
            continue
        files = component.get("files", {})
        entries = files.get(key, files.get("any", []))
        if not entries:
            notes.append(f"{component['id']}: nothing vendored for {key}")
            continue

        if component["id"] == "emulator":
            present = any(Path(entry["path"]).is_file() for entry in entries)
            if not present and not args.require_emulator:
                notes.append(
                    "emulator: not built; run 'make build-gens' before 'make trace'"
                )
                continue
            if not present:
                errors.append("emulator: not built; run 'make build-gens'")
                continue
            check_commit(component, errors, notes)

        checked += check_files(entries, errors, notes)

    for note in notes:
        print(f"[INFO] {note}")
    if errors:
        for message in errors:
            print(f"[ERROR] {message}", file=sys.stderr)
        print(f"[FAIL] toolchain does not match {args.config}", file=sys.stderr)
        return 1

    print(f"[OK] toolchain matches {args.config}: {checked} file(s) verified for {key}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

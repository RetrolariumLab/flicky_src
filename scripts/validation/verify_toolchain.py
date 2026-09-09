#!/usr/bin/env python3
"""Check the toolchain against the hashes config/toolchain.json records.

A byte-identical ROM is only evidence if the thing that produced it is known.
This runs before the build rather than after it, so a swapped assembler is
caught by name instead of showing up as a mysterious diff.

Source-built tools retain their upstream commit provenance, but the executable
that actually runs must also match an approved hash. This prevents a different
binary beside a correctly pinned checkout from producing accepted evidence.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


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
            errors.append(f"{path} is missing")
            continue

        actual = sha256_of(path)
        size = path.stat().st_size
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


def selected_executable_entry(
    component: dict[str, Any], key: str, errors: list[str]
) -> dict[str, Any] | None:
    """Return the one approved executable identity for a component and host."""
    files = component.get("files", {})
    entries = files.get(key, files.get("any", []))
    executable_entries = [entry for entry in entries if entry.get("executable")]
    if len(executable_entries) != 1:
        errors.append(
            f"{component.get('id', '<unknown>')}: expected exactly one approved "
            f"executable for {key}, found {len(executable_entries)}"
        )
        return None
    return executable_entries[0]


def check_selected_executables(
    components: list[dict[str, Any]],
    key: str,
    selections: dict[str, Path],
    errors: list[str],
    notes: list[str],
) -> int:
    """Hash the resolved executables that the caller is about to invoke."""
    by_id = {component.get("id"): component for component in components}
    checked = 0
    for identifier, selected in selections.items():
        component = by_id.get(identifier)
        if component is None:
            errors.append(f"selected executable names unknown component {identifier}")
            continue
        expected = selected_executable_entry(component, key, errors)
        if expected is None:
            continue
        selected_entry = dict(expected)
        selected_entry["path"] = str(selected.resolve())
        checked += check_files([selected_entry], errors, notes)
    return checked


def parse_selections(values: list[str], errors: list[str]) -> dict[str, Path]:
    selections: dict[str, Path] = {}
    for value in values:
        identifier, separator, path = value.partition("=")
        if not separator or not identifier or not path:
            errors.append(
                f"invalid executable selection {value!r}; expected COMPONENT=PATH"
            )
            continue
        if identifier in selections:
            errors.append(f"duplicate executable selection for {identifier}")
            continue
        selections[identifier] = Path(path)
    return selections


def check_commit(
    component: dict,
    errors: list[str],
    notes: list[str],
    executable: Path | None = None,
    required: bool = False,
) -> None:
    """For a source-built component, the pinned commit is the identity."""
    wanted = component.get("source_commit")
    if not wanted:
        return
    checkout = executable.resolve().parent.parent if executable is not None else None
    if checkout is None:
        for entries in component.get("files", {}).values():
            for entry in entries:
                checkout = Path(entry["path"]).parent.parent
                break
            break
    if checkout is None or not (checkout / ".git").exists():
        message = f"{component['id']}: no checkout at {checkout}, commit not verified"
        (errors if required else notes).append(message)
        return

    result = subprocess.run(
        ["git", "-C", str(checkout), "rev-parse", "HEAD"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        message = f"{component['id']}: could not read the checkout's commit"
        (errors if required else notes).append(message)
        return
    actual = result.stdout.strip()
    if actual != wanted:
        errors.append(
            f"{component['id']}: {checkout} is at {actual[:12]}, "
            f"but the manifest pins {wanted[:12]}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config/toolchain.json")
    parser.add_argument("--platform", help="Toolchain subdirectory, else autodetected")
    parser.add_argument("--only", help="Check one component id")
    parser.add_argument(
        "--require-executable",
        action="append",
        default=[],
        metavar="COMPONENT=PATH",
        help="Hash the resolved executable path that the caller will invoke",
    )
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
    selections = parse_selections(args.require_executable, errors)

    for component in config["components"]:
        if args.only and component["id"] != args.only:
            continue
        files = component.get("files", {})
        entries = files.get(key, files.get("any", []))
        if not entries:
            notes.append(f"{component['id']}: nothing vendored for {key}")
            continue

        if component["id"] == "emulator":
            selected = selections.get("emulator")
            present = (
                selected.is_file()
                if selected is not None
                else any(Path(entry["path"]).is_file() for entry in entries)
            )
            if not present and not args.require_emulator:
                notes.append(
                    "emulator: not built; run 'make build-gens' before 'make trace'"
                )
                continue
            if not present:
                errors.append("emulator: not built; run 'make build-gens'")
                continue
            check_commit(
                component,
                errors,
                notes,
                selected,
                required=args.require_emulator,
            )

            # A selected emulator is hashed below using the executable path the
            # caller will actually launch. Do not also require the manifest's
            # default checkout when an approved binary is selected elsewhere.
            if selected is not None:
                continue

        checked += check_files(entries, errors, notes)

    selected_checked = check_selected_executables(
        config["components"], key, selections, errors, notes
    )

    for note in notes:
        print(f"[INFO] {note}")
    if errors:
        for message in errors:
            print(f"[ERROR] {message}", file=sys.stderr)
        print(f"[FAIL] toolchain does not match {args.config}", file=sys.stderr)
        return 1

    selected_note = (
        f", {selected_checked} selected executable(s) verified"
        if selections
        else ""
    )
    print(
        f"[OK] toolchain matches {args.config}: {checked} manifest file(s) "
        f"verified for {key}{selected_note}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Check the ROM layout contract against the assembled image.

AS builds one translation unit and there is no linker, so `config/linker/` has
nothing to hold: the include order in `flicky.s` *is* the layout. This makes
that layout a declaration the build has to agree with, rather than a comment
that can drift.

Three things are checked, and each catches a different kind of mistake:

* the module ranges, against the addresses the assembler recorded for every
  `include` in its listing -- a reordered or resized module shows up here with
  a name, before `make verify` reports it as an offset;
* the landmark symbols, against the symbol table -- so the header, the vectors
  and the entry point are asserted rather than assumed;
* the padding gap, against the built image -- the gap is filled by
  `p2bin -p=FF` and is not the tail of the file, because `RomEndData` emits the
  last byte, which is exactly why a default of `$00` corrupts 18,015 bytes in
  the middle rather than truncating the end.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import debug_symbols  # noqa: E402

INCLUDE_ROW = re.compile(r'^\s*\d+/\s*([0-9A-F]+) :\s+include "([^"]+)"')


def parse_number(text: str) -> int:
    return int(text, 16) if text.lower().startswith("0x") else int(text, 0)


def includes_from_listing(listing: Path) -> list[tuple[int, str]]:
    """Every include the assembler processed, with the address it started at."""
    found = []
    for line in listing.read_text(encoding="latin-1").splitlines():
        match = INCLUDE_ROW.match(line)
        if match:
            found.append((int(match.group(1), 16), match.group(2)))
    return found


def check_modules(layout: dict, listing: Path, errors: list[str]) -> int:
    rows = includes_from_listing(listing)
    actual = [row for row in rows if row[1].endswith(".s")]
    shared = [row[1] for row in rows if row[1].endswith(".inc")]
    declared = layout["modules"]

    if len(actual) != len(declared):
        errors.append(
            f"the build has {len(actual)} modules, the layout declares {len(declared)}"
        )
        return 0

    rom_size = layout["rom_image"]["size"]
    for index, (entry, (address, path)) in enumerate(zip(declared, actual)):
        if entry["file"] != path:
            errors.append(
                f"module {index}: the build includes {path}, "
                f"the layout declares {entry['file']}"
            )
            continue
        end = (actual[index + 1][0] if index + 1 < len(actual) else rom_size) - 1
        if parse_number(entry["start"]) != address:
            errors.append(
                f"{path} starts at 0x{address:06X}, "
                f"the layout declares {entry['start']}"
            )
        if parse_number(entry["end"]) != end:
            errors.append(
                f"{path} ends at 0x{end:06X}, the layout declares {entry['end']}"
            )

    expected_shared = [entry["file"] for entry in layout["shared_definitions"]]
    if shared != expected_shared:
        errors.append(
            f"shared definitions are {shared}, the layout declares {expected_shared}"
        )
    return len(declared)


def check_landmarks(layout: dict, listing: Path, errors: list[str]) -> int:
    resolved = debug_symbols.collect_from_listing(listing)
    landmarks = layout["rom_image"].get("landmarks", [])
    for landmark in landmarks:
        name = landmark["symbol"]
        if name not in resolved:
            errors.append(f"landmark {name} is not defined in the build")
            continue
        declared = parse_number(landmark["address"])
        if resolved[name] != declared:
            errors.append(
                f"landmark {name} is at 0x{resolved[name]:06X}, "
                f"the layout declares {landmark['address']}"
            )
    return len(landmarks)


def check_image(layout: dict, rom: Path, errors: list[str]) -> None:
    if not rom.is_file():
        errors.append(f"{rom} not found; run 'make build' first")
        return

    data = rom.read_bytes()
    image = layout["rom_image"]
    if len(data) != image["size"]:
        errors.append(f"{rom} is {len(data)} bytes, the layout declares {image['size']}")
        return

    padding = parse_number(image["padding_byte"])
    for gap in image.get("gaps", []):
        start, end = parse_number(gap["start"]), parse_number(gap["end"])
        if end - start + 1 != gap["size"]:
            errors.append(
                f"gap {gap['start']}-{gap['end']} is declared as {gap['size']} bytes "
                f"but spans {end - start + 1}"
            )
        wrong = [offset for offset in range(start, end + 1) if data[offset] != padding]
        if wrong:
            errors.append(
                f"gap {gap['start']}-{gap['end']} is not all "
                f"{image['padding_byte']}: {len(wrong)} byte(s) differ, "
                f"first at 0x{wrong[0]:06X}"
            )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", default="config/rom_layout.json")
    parser.add_argument("--listing", default="flicky.lst")
    parser.add_argument("--rom", default="fbuilt.bin")
    args = parser.parse_args()

    layout_path = Path(args.layout)
    layout = json.loads(layout_path.read_text(encoding="utf-8"))
    listing = Path(args.listing)
    if not listing.is_file():
        print(f"[ERROR] {listing} not found; run 'make build' first", file=sys.stderr)
        return 1

    errors: list[str] = []
    modules = check_modules(layout, listing, errors)
    landmarks = check_landmarks(layout, listing, errors)
    check_image(layout, Path(args.rom), errors)

    if errors:
        for message in errors:
            print(f"[ERROR] {message}", file=sys.stderr)
        print(f"[FAIL] the build does not match {layout_path}", file=sys.stderr)
        return 1

    gap_bytes = sum(gap["size"] for gap in layout["rom_image"].get("gaps", []))
    print(
        f"[OK] layout matches the build: {modules} modules, {landmarks} landmarks, "
        f"{gap_bytes} padding byte(s)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

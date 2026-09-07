#!/usr/bin/env python3
"""Editable game text and palette model for Flicky Graphics Studio."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


TEXT_SOURCES = (
    "game/bonus.s",
    "game/bonus_objects.s",
    "game/ending.s",
    "game/guide.s",
    "game/round_select.s",
    "game/title.s",
    "rendering/hud.s",
)
PALETTE_SOURCES = (
    "game/round_setup.s",
    "game/title.s",
)
TEXT_RE = re.compile(
    r'^(?P<label>[A-Za-z_][A-Za-z0-9_]*):(?P<prefix>\s+dc\.b\s+[^"\r\n]*)'
    r'"(?P<value>[^"\r\n]*)"(?P<suffix>[^\r\n]*)$',
    re.MULTILINE,
)
PALETTE_LABEL_RE = re.compile(
    r"^(?:Level_Palette\d+|Level_AccentPalette\d+|Title_LogoPalette)$"
)
PALETTE_RE = re.compile(
    r"^(?P<label>[A-Za-z_][A-Za-z0-9_]*):(?P<spacing>\s+)dc\.w\s+(?P<values>[^;\r\n]+)$",
    re.MULTILINE,
)


def parse_number(value: str) -> int:
    value = value.strip()
    return int(value[1:], 16) if value.startswith("$") else int(value, 10)


def format_colour(value: int) -> str:
    return "0" if value == 0 else f"${value:X}"


def export_document(root: Path) -> dict[str, Any]:
    source_root = root / "src"
    texts: list[dict[str, Any]] = []
    for relative in TEXT_SOURCES:
        source = (source_root / relative).read_text(encoding="utf-8")
        for match in TEXT_RE.finditer(source):
            value = match.group("value")
            texts.append({
                "id": match.group("label"),
                "source": relative,
                "value": value,
                "capacity": len(value),
            })

    palettes: list[dict[str, Any]] = []
    for relative in PALETTE_SOURCES:
        source = (source_root / relative).read_text(encoding="utf-8")
        for match in PALETTE_RE.finditer(source):
            label = match.group("label")
            if not PALETTE_LABEL_RE.fullmatch(label):
                continue
            palettes.append({
                "id": label,
                "source": relative,
                "colours": [parse_number(item) for item in match.group("values").split(",")],
            })
    return {
        "schema_version": 1,
        "profile": "canonical",
        "texts": texts,
        "palettes": palettes,
    }


def _unique_records(document: dict[str, Any], key: str) -> dict[str, dict[str, Any]]:
    records = document.get(key)
    if not isinstance(records, list):
        raise ValueError(f"graphics semantics document has no {key} list")
    result: dict[str, dict[str, Any]] = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("id"), str):
            raise ValueError(f"graphics semantics {key} contains an invalid record")
        if record["id"] in result:
            raise ValueError(f"duplicate {key} record: {record['id']}")
        result[record["id"]] = record
    return result


def validate_document(document: dict[str, Any], root: Path) -> None:
    if document.get("schema_version") != 1 or document.get("profile") != "canonical":
        raise ValueError("unsupported graphics semantics schema or profile")
    baseline = export_document(root)
    expected_texts = _unique_records(baseline, "texts")
    texts = _unique_records(document, "texts")
    if set(texts) != set(expected_texts):
        raise ValueError("text identity differs from the source inventory")
    for identifier, record in texts.items():
        expected = expected_texts[identifier]
        value = record.get("value")
        if record.get("source") != expected["source"] or record.get("capacity") != expected["capacity"]:
            raise ValueError(f"{identifier}: source or capacity differs")
        if (
            not isinstance(value, str)
            or len(value) > record["capacity"]
            or any(not 0x20 <= ord(character) <= 0x7E or character in {'"', '\\'} for character in value)
        ):
            raise ValueError(f"{identifier}: text must be printable ASCII within its capacity")

    expected_palettes = _unique_records(baseline, "palettes")
    palettes = _unique_records(document, "palettes")
    if set(palettes) != set(expected_palettes):
        raise ValueError("palette identity differs from the source inventory")
    for identifier, record in palettes.items():
        expected = expected_palettes[identifier]
        colours = record.get("colours")
        if record.get("source") != expected["source"]:
            raise ValueError(f"{identifier}: source differs")
        if not isinstance(colours, list) or len(colours) != len(expected["colours"]):
            raise ValueError(f"{identifier}: palette size differs")
        if any(not isinstance(colour, int) or colour < 0 or colour > 0xEEE or colour & 0x111 for colour in colours):
            raise ValueError(f"{identifier}: Mega Drive colours use only even $0EEE channels")


def load_document(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8", newline="\n")
    temporary.replace(path)


def apply_document(document: dict[str, Any], root: Path, staged_source: Path) -> None:
    validate_document(document, root)
    baseline = export_document(root)
    baseline_texts = _unique_records(baseline, "texts")
    baseline_palettes = _unique_records(baseline, "palettes")

    by_source: dict[str, list[dict[str, Any]]] = {}
    for record in document["texts"] + document["palettes"]:
        by_source.setdefault(record["source"], []).append(record)

    for relative, records in by_source.items():
        path = staged_source / relative
        source = path.read_text(encoding="utf-8")
        for record in records:
            identifier = record["id"]
            if identifier in baseline_texts:
                original = baseline_texts[identifier]
                if record["value"] == original["value"]:
                    continue
                replacement = record["value"].ljust(record["capacity"])
                pattern = re.compile(
                    rf'^(?P<head>{re.escape(identifier)}:\s+dc\.b\s+[^"\r\n]*)'
                    rf'"{re.escape(original["value"])}"(?P<tail>[^\r\n]*)$',
                    re.MULTILINE,
                )
                source, count = pattern.subn(
                    lambda match: f'{match.group("head")}"{replacement}"{match.group("tail")}',
                    source,
                )
            else:
                original = baseline_palettes[identifier]
                if record["colours"] == original["colours"]:
                    continue
                pattern = re.compile(
                    rf'^(?P<head>{re.escape(identifier)}:\s+dc\.w\s+)[^;\r\n]+$',
                    re.MULTILINE,
                )
                values = ", ".join(format_colour(colour) for colour in record["colours"])
                source, count = pattern.subn(lambda match: match.group("head") + values, source)
            if count != 1:
                raise ValueError(f"{identifier}: expected exactly one owning source record")
        path.write_text(source, encoding="utf-8", newline="\n")

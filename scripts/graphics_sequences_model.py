#!/usr/bin/env python3
"""Semantic sprite mappings and animation sequences for Graphics Studio."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any


MAPPING_SOURCE = "data/tables.s"
ANIMATION_SOURCES = (
    "game/bonus_objects.s",
    "game/cat.s",
    "game/chick.s",
    "game/lizard.s",
    "game/player.s",
    "game/snake.s",
    "game/spawner.s",
    "rendering/hud.s",
)
LABEL_RE = re.compile(r"^(?P<label>[A-Za-z_][A-Za-z0-9_]*):", re.MULTILINE)
DIRECTIVE_RE = re.compile(r"^\s*dc\.(?P<size>[bw])\s+(?P<values>[^;]+?)\s*$")
NUMBER_RE = re.compile(r"^(?:\$[0-9A-Fa-f]+|[0-9]+)$")
SPRITE_ANIM_HEADER_RE = re.compile(
    r"^(?P<label>[A-Za-z_][A-Za-z0-9_]*Anim[A-Za-z0-9_]*):\s+dc\.b\s+"
    r"(?P<count>\$[0-9A-Fa-f]+|[0-9]+),\s*(?P<delay>\$[0-9A-Fa-f]+|[0-9]+)\s*$"
)
SPRITE_FRAME_RE = re.compile(
    r"^\s+dc\.w\s+(?P<label>[A-Za-z_][A-Za-z0-9_]*)-Sys_GameEntryPoint\s*$"
)
TILE_ANIM_HEADER_RE = re.compile(
    r"^(?P<label>[A-Za-z_][A-Za-z0-9_]*Anim[A-Za-z0-9_]*):\s+dc\.b\s+"
    r"(?P<count>\$[0-9A-Fa-f]+|[0-9]+)\s*$"
)
DELAY_RE = re.compile(r"^\s+dc\.b\s+(?P<delay>\$[0-9A-Fa-f]+|[0-9]+)\s*$")
TILE_FRAME_RE = re.compile(r"^\s+dc\.l\s+(?P<label>[A-Za-z_][A-Za-z0-9_]*)\s*$")


def parse_number(value: str) -> int:
    return int(value[1:], 16) if value.startswith("$") else int(value, 10)


def format_number(value: int) -> str:
    return str(value) if value < 10 else f"${value:X}"


def signed_byte(value: int) -> int:
    return value - 0x100 if value & 0x80 else value


def _block_bytes(block: str) -> bytes | None:
    result = bytearray()
    lines = block.splitlines()
    if not lines:
        return None
    first = lines[0].split(":", 1)[1]
    lines[0] = first
    for line in lines:
        if not line.strip() or line.lstrip().startswith(";"):
            continue
        match = DIRECTIVE_RE.fullmatch(line)
        if not match:
            return None
        values = [item.strip() for item in match.group("values").split(",")]
        if not values or any(not NUMBER_RE.fullmatch(item) for item in values):
            return None
        for item in values:
            value = parse_number(item)
            if match.group("size") == "b":
                if value > 0xFF:
                    return None
                result.append(value)
            else:
                if value > 0xFFFF:
                    return None
                result.extend(value.to_bytes(2, "big"))
    return bytes(result)


def _decode_mapping(label: str, data: bytes, source_text: str) -> dict[str, Any] | None:
    if len(data) < 8:
        return None
    count = data[0] + 1
    if count > 32 or len(data) != 2 + count * 6:
        return None
    if len(re.findall(rf"\b{re.escape(label)}\b", source_text)) < 2:
        return None
    pieces = []
    for index in range(count):
        offset = 2 + index * 6
        size = data[offset + 1]
        attributes = int.from_bytes(data[offset + 2:offset + 4], "big")
        pieces.append({
            "y": signed_byte(data[offset]),
            "width": (size & 3) + 1,
            "height": ((size >> 2) & 3) + 1,
            "tile": attributes & 0x7FF,
            "palette": (attributes >> 13) & 3,
            "priority": bool(attributes & 0x8000),
            "hflip": bool(attributes & 0x0800),
            "vflip": bool(attributes & 0x1000),
            "x": signed_byte(data[offset + 4]),
            "flipped_x": signed_byte(data[offset + 5]),
        })
    return {"id": label, "source": MAPPING_SOURCE, "render_flags": data[1], "pieces": pieces}


def parse_mappings(root: Path) -> list[dict[str, Any]]:
    path = root / "src" / MAPPING_SOURCE
    source = path.read_text(encoding="utf-8")
    all_source = "\n".join(
        item.read_text(encoding="utf-8") for item in (root / "src").rglob("*.s")
    )
    labels = list(LABEL_RE.finditer(source))
    mappings = []
    for index, match in enumerate(labels):
        end = labels[index + 1].start() if index + 1 < len(labels) else len(source)
        data = _block_bytes(source[match.start():end])
        if data is None:
            continue
        mapping = _decode_mapping(match.group("label"), data, all_source)
        if mapping is not None:
            mappings.append(mapping)
    return mappings


def parse_animations(root: Path) -> list[dict[str, Any]]:
    animations: list[dict[str, Any]] = []
    for relative in ANIMATION_SOURCES:
        lines = (root / "src" / relative).read_text(encoding="utf-8").splitlines()
        index = 0
        while index < len(lines):
            sprite = SPRITE_ANIM_HEADER_RE.fullmatch(lines[index])
            if sprite:
                count = parse_number(sprite.group("count"))
                frames = []
                if count:
                    for line in lines[index + 1:index + 1 + count]:
                        frame = SPRITE_FRAME_RE.fullmatch(line)
                        if not frame:
                            frames = []
                            break
                        frames.append(frame.group("label"))
                if count and len(frames) == count:
                    animations.append({
                        "id": sprite.group("label"),
                        "source": relative,
                        "kind": "sprite",
                        "delay": parse_number(sprite.group("delay")),
                        "frames": frames,
                    })
                    index += count + 1
                    continue
            tile = TILE_ANIM_HEADER_RE.fullmatch(lines[index])
            if tile and index + 1 < len(lines):
                count = parse_number(tile.group("count"))
                delay = DELAY_RE.fullmatch(lines[index + 1])
                frames = []
                if delay:
                    for line in lines[index + 2:index + 2 + count]:
                        frame = TILE_FRAME_RE.fullmatch(line)
                        if not frame:
                            frames = []
                            break
                        frames.append(frame.group("label"))
                if delay and len(frames) == count:
                    animations.append({
                        "id": tile.group("label"),
                        "source": relative,
                        "kind": "tilemap",
                        "delay": parse_number(delay.group("delay")),
                        "frames": frames,
                    })
                    index += count + 2
                    continue
            index += 1
    return animations


def export_document(root: Path) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "profile": "canonical",
        "mappings": parse_mappings(root),
        "animations": parse_animations(root),
    }


def _table(document: dict[str, Any], key: str) -> dict[str, dict[str, Any]]:
    records = document.get(key)
    if not isinstance(records, list):
        raise ValueError(f"graphics sequences document has no {key} list")
    result: dict[str, dict[str, Any]] = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("id"), str):
            raise ValueError(f"invalid {key} record")
        if record["id"] in result:
            raise ValueError(f"duplicate {key} record: {record['id']}")
        result[record["id"]] = record
    return result


def validate_document(document: dict[str, Any], root: Path) -> None:
    if document.get("schema_version") != 1 or document.get("profile") != "canonical":
        raise ValueError("unsupported graphics sequences schema or profile")
    baseline = export_document(root)
    expected_mappings = _table(baseline, "mappings")
    mappings = _table(document, "mappings")
    if set(mappings) != set(expected_mappings):
        raise ValueError("mapping identity differs from the source inventory")
    for identifier, mapping in mappings.items():
        expected = expected_mappings[identifier]
        if mapping.get("source") != MAPPING_SOURCE or not isinstance(mapping.get("render_flags"), int) or not 0 <= mapping["render_flags"] <= 0xFF:
            raise ValueError(f"{identifier}: invalid mapping header")
        pieces = mapping.get("pieces")
        if not isinstance(pieces, list) or len(pieces) != len(expected["pieces"]):
            raise ValueError(f"{identifier}: piece count differs")
        for piece in pieces:
            if (
                not isinstance(piece, dict)
                or any(not isinstance(piece.get(key), int) for key in ("x", "flipped_x", "y", "width", "height", "tile", "palette"))
                or not -128 <= piece["x"] <= 127
                or not -128 <= piece["flipped_x"] <= 127
                or not -128 <= piece["y"] <= 127
                or not 1 <= piece["width"] <= 4
                or not 1 <= piece["height"] <= 4
                or not 0 <= piece["tile"] <= 0x7FF
                or not 0 <= piece["palette"] <= 3
                or not isinstance(piece.get("priority"), bool)
                or not isinstance(piece.get("hflip"), bool)
                or not isinstance(piece.get("vflip"), bool)
            ):
                raise ValueError(f"{identifier}: invalid sprite piece")

    expected_animations = _table(baseline, "animations")
    animations = _table(document, "animations")
    if set(animations) != set(expected_animations):
        raise ValueError("animation identity differs from the source inventory")
    allowed = {
        kind: {frame for item in baseline["animations"] if item["kind"] == kind for frame in item["frames"]}
        for kind in ("sprite", "tilemap")
    }
    for identifier, animation in animations.items():
        expected = expected_animations[identifier]
        frames = animation.get("frames")
        if (
            animation.get("source") != expected["source"]
            or animation.get("kind") != expected["kind"]
            or not isinstance(animation.get("delay"), int)
            or not 0 <= animation["delay"] <= 0xFF
            or not isinstance(frames, list)
            or len(frames) != len(expected["frames"])
            or any(frame not in allowed[animation["kind"]] for frame in frames)
        ):
            raise ValueError(f"{identifier}: invalid animation sequence")


def load_document(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8", newline="\n")
    temporary.replace(path)


def _mapping_bytes(mapping: dict[str, Any]) -> bytes:
    output = bytearray((len(mapping["pieces"]) - 1, mapping["render_flags"]))
    for piece in mapping["pieces"]:
        size = (piece["width"] - 1) | ((piece["height"] - 1) << 2)
        attributes = piece["tile"] | (piece["palette"] << 13)
        attributes |= 0x8000 if piece["priority"] else 0
        attributes |= 0x0800 if piece["hflip"] else 0
        attributes |= 0x1000 if piece["vflip"] else 0
        output.extend(((piece["y"] & 0xFF), size))
        output.extend(attributes.to_bytes(2, "big"))
        output.extend(((piece["x"] & 0xFF), (piece["flipped_x"] & 0xFF)))
    return bytes(output)


def _render_mapping(mapping: dict[str, Any]) -> str:
    data = _mapping_bytes(mapping)
    lines = [f"{mapping['id']}:\tdc.b\t${data[0]:02X}, ${data[1]:02X}"]
    for offset in range(2, len(data), 6):
        attributes = int.from_bytes(data[offset + 2:offset + 4], "big")
        lines.append(
            f"\tdc.b\t${data[offset]:02X}, ${data[offset + 1]:02X}\n"
            f"\tdc.w\t${attributes:04X}\n"
            f"\tdc.b\t${data[offset + 4]:02X}, ${data[offset + 5]:02X}"
        )
    return "\n".join(lines)


def _mapping_spans(source: str) -> dict[str, tuple[int, int]]:
    labels = list(LABEL_RE.finditer(source))
    return {
        match.group("label"): (match.start(), labels[index + 1].start() if index + 1 < len(labels) else len(source))
        for index, match in enumerate(labels)
    }


def apply_document(document: dict[str, Any], root: Path, staged_source: Path) -> None:
    validate_document(document, root)
    baseline = export_document(root)
    baseline_mappings = _table(baseline, "mappings")
    mapping_path = staged_source / MAPPING_SOURCE
    source = mapping_path.read_text(encoding="utf-8")
    spans = _mapping_spans(source)
    changes = []
    for mapping in document["mappings"]:
        if mapping == baseline_mappings[mapping["id"]]:
            continue
        start, end = spans[mapping["id"]]
        trailing = "\n" if source[start:end].endswith("\n") else ""
        changes.append((start, end, _render_mapping(mapping) + trailing))
    for start, end, replacement in sorted(changes, reverse=True):
        source = source[:start] + replacement + source[end:]
    mapping_path.write_text(source, encoding="utf-8", newline="\n")

    baseline_animations = _table(baseline, "animations")
    by_source: dict[str, list[dict[str, Any]]] = {}
    for animation in document["animations"]:
        if animation != baseline_animations[animation["id"]]:
            by_source.setdefault(animation["source"], []).append(animation)
    for relative, animations in by_source.items():
        path = staged_source / relative
        lines = path.read_text(encoding="utf-8").splitlines()
        for animation in animations:
            baseline_animation = baseline_animations[animation["id"]]
            header = next(
                index for index, line in enumerate(lines)
                if line.startswith(animation["id"] + ":")
            )
            count = len(animation["frames"])
            if animation["kind"] == "sprite":
                lines[header] = f"{animation['id']}:\tdc.b\t{format_number(count)}, {format_number(animation['delay'])}"
                for offset, frame in enumerate(animation["frames"], 1):
                    lines[header + offset] = f"\tdc.w\t{frame}-Sys_GameEntryPoint"
            else:
                lines[header] = f"{animation['id']}:\tdc.b\t{format_number(count)}"
                lines[header + 1] = f"\tdc.b\t{format_number(animation['delay'])}"
                for offset, frame in enumerate(animation["frames"], 2):
                    lines[header + offset] = f"\tdc.l\t{frame}"
        path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

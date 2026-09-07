#!/usr/bin/env python3
"""Headless decode, validation, and assembly generation for Flicky levels."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


LEVEL_COUNT = 36
ROUND_COUNT = 48
MAP_WIDTH = 32
MAP_HEIGHT = 28
MAP_SIZE = MAP_WIDTH * MAP_HEIGHT
MAP_STREAM_START = 0x40

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$")
DIRECTIVE_RE = re.compile(r"^dc\.(b|w)\s+(.+)$", re.IGNORECASE)


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_integer(value: str) -> int:
    value = value.strip()
    if value.startswith("$"):
        return int(value[1:], 16)
    return int(value, 10)


def source_range(text: str, start: str, end: str) -> str:
    begin = text.find(start)
    finish = text.find(end, begin + len(start))
    if begin < 0 or finish < 0:
        raise ValueError(f"source range not found: {start} .. {end}")
    return text[begin:finish]


def directive_values(text: str, width: int) -> list[int]:
    values: list[int] = []
    wanted = "b" if width == 1 else "w"
    for raw_line in text.splitlines():
        code = raw_line.split(";", 1)[0].strip()
        label = LABEL_RE.match(code)
        if label:
            code = label.group(2).strip()
        directive = DIRECTIVE_RE.match(code)
        if not directive or directive.group(1).lower() != wanted:
            continue
        for token in directive.group(2).split(","):
            values.append(parse_integer(token) & (0xFF if width == 1 else 0xFFFF))
    return values


def named_blocks(text: str, prefix: str, end_marker: str, width: int) -> list[list[int]]:
    matches = list(re.finditer(rf"(?m)^{re.escape(prefix)}(\d+):", text))
    blocks: dict[int, list[int]] = {}
    for index, match in enumerate(matches):
        number = int(match.group(1))
        finish = matches[index + 1].start() if index + 1 < len(matches) else text.find(end_marker, match.end())
        if finish < 0:
            raise ValueError(f"end marker not found after {prefix}{number}: {end_marker}")
        blocks[number] = directive_values(text[match.start():finish], width)
    if set(blocks) != set(range(LEVEL_COUNT)):
        raise ValueError(f"{prefix} blocks differ from 0..{LEVEL_COUNT - 1}")
    return [blocks[index] for index in range(LEVEL_COUNT)]


def pointer_indices(text: str, table: str, next_label: str, prefix: str) -> list[int]:
    block = source_range(text, f"{table}:", f"{next_label}:")
    pointers = [int(value) for value in re.findall(rf"{re.escape(prefix)}(\d+)-", block)]
    if len(pointers) != ROUND_COUNT:
        raise ValueError(f"{table} has {len(pointers)} entries, expected {ROUND_COUNT}")
    if any(not 0 <= value < LEVEL_COUNT for value in pointers):
        raise ValueError(f"{table} contains an invalid level index")
    return pointers


def decode_collision(stream: list[int]) -> list[list[int]]:
    grid = [0] * MAP_SIZE
    cursor = MAP_STREAM_START
    for command in stream:
        if command == 0:
            return [grid[row * MAP_WIDTH:(row + 1) * MAP_WIDTH] for row in range(MAP_HEIGHT)]
        if command & 0x80:
            length = command & 0x3F
            if not length:
                raise ValueError("collision stream contains a zero-length run")
            if command & 0x40:
                positions = [cursor + step * MAP_WIDTH for step in range(length)]
                cursor += 1
            else:
                positions = list(range(cursor, cursor + length))
                cursor += length
            if any(position >= MAP_SIZE for position in positions):
                raise ValueError("collision run leaves the 32x28 map")
            for position in positions:
                grid[position] = 1
        else:
            cursor += command
            if cursor > MAP_SIZE:
                raise ValueError("collision skip leaves the 32x28 map")
    raise ValueError("collision stream has no terminator")


def encode_collision(grid_rows: list[list[int]]) -> list[int]:
    validate_grid(grid_rows)
    flat = [value for row in grid_rows for value in row]
    if any(flat[:MAP_STREAM_START]):
        raise ValueError("the first two collision rows are generated at runtime")
    output: list[int] = []
    cursor = MAP_STREAM_START
    for row in range(MAP_STREAM_START // MAP_WIDTH, MAP_HEIGHT):
        column = 0
        while column < MAP_WIDTH:
            position = row * MAP_WIDTH + column
            if not flat[position]:
                column += 1
                continue
            while cursor < position:
                distance = min(position - cursor, 0x7F)
                output.append(distance)
                cursor += distance
            length = 0
            while column + length < MAP_WIDTH and flat[position + length] and length < 0x3F:
                length += 1
            output.append(0x80 | length)
            cursor += length
            column += length
    output.append(0)
    return output


def take_pair(data: list[int], cursor: int, field: str) -> tuple[list[int], int]:
    if cursor + 2 > len(data):
        raise ValueError(f"level data ends inside {field}")
    pair = data[cursor:cursor + 2]
    if any(not 0 <= value < MAP_WIDTH for value in pair):
        raise ValueError(f"{field} coordinate is outside 0..31")
    return pair, cursor + 2


def take_group(data: list[int], cursor: int, field: str) -> tuple[list[list[int]], int]:
    if cursor >= len(data):
        raise ValueError(f"level data ends before {field} count")
    count = data[cursor]
    cursor += 1
    pairs = []
    for index in range(count):
        pair, cursor = take_pair(data, cursor, f"{field}[{index}]")
        pairs.append(pair)
    return pairs, cursor


def decode_level(data: list[int]) -> dict[str, Any]:
    try:
        terminator = data.index(0)
    except ValueError as error:
        raise ValueError("level collision stream has no terminator") from error
    collision_stream = data[:terminator + 1]
    cursor = terminator + 1
    fields: dict[str, Any] = {}
    for field in ("player", "entry_arrow", "cat_door", "exit_door"):
        fields[field], cursor = take_pair(data, cursor, field)
    for field in ("background_group_3", "background_group_4", "background_group_5"):
        fields[field], cursor = take_group(data, cursor, field)
    spawners = []
    for index in range(6):
        pair, cursor = take_pair(data, cursor, f"spawners[{index}]")
        spawners.append(pair)
    fields["spawners"] = spawners
    fields["chicks_a"], cursor = take_group(data, cursor, "chicks_a")
    fields["chicks_b"], cursor = take_group(data, cursor, "chicks_b")
    trailing = data[cursor:]
    if any(trailing) or len(trailing) > 2:
        raise ValueError(f"level data has {len(data) - cursor} unexpected trailing byte(s)")
    return {
        "collision": decode_collision(collision_stream),
        "baseline_collision_stream": collision_stream,
        "baseline_bytes": data,
        **fields,
    }


def decode_special(data: list[int]) -> dict[str, Any]:
    cursor = 0
    groups = {}
    for name in ("flag_7", "flag_7_6", "flag_5"):
        pairs, cursor = take_group(data, cursor, name)
        groups[name] = pairs
    trailing = data[cursor:]
    if any(trailing) or len(trailing) > 1:
        raise ValueError("special-tile data has unexpected trailing bytes")
    groups["baseline_bytes"] = data
    return groups


def validate_grid(grid: Any) -> None:
    if not isinstance(grid, list) or len(grid) != MAP_HEIGHT:
        raise ValueError(f"collision grid must have {MAP_HEIGHT} rows")
    for row in grid:
        if not isinstance(row, list) or len(row) != MAP_WIDTH:
            raise ValueError(f"collision grid rows must have {MAP_WIDTH} cells")
        if any(value not in (0, 1) for value in row):
            raise ValueError("collision cells must be 0 or 1")


def validate_pairs(value: Any, field: str, count: int | None = None) -> None:
    if not isinstance(value, list) or (count is not None and len(value) != count):
        raise ValueError(f"{field} has an invalid item count")
    for pair in value:
        if (
            not isinstance(pair, list)
            or len(pair) != 2
            or any(not isinstance(item, int) or not 0 <= item < MAP_WIDTH for item in pair)
        ):
            raise ValueError(f"{field} contains an invalid coordinate")


def encode_level(level: dict[str, Any]) -> list[int]:
    validate_grid(level.get("collision"))
    baseline = level.get("baseline_collision_stream", [])
    collision = baseline if decode_collision(baseline) == level["collision"] else encode_collision(level["collision"])
    output = list(collision)
    for field in ("player", "entry_arrow", "cat_door", "exit_door"):
        validate_pairs([level.get(field)], field, 1)
        output.extend(level[field])
    for field in ("background_group_3", "background_group_4", "background_group_5"):
        validate_pairs(level.get(field), field)
        if len(level[field]) > 0xFF:
            raise ValueError(f"{field} exceeds 255 entries")
        output.append(len(level[field]))
        for pair in level[field]:
            output.extend(pair)
    validate_pairs(level.get("spawners"), "spawners", 6)
    for pair in level["spawners"]:
        output.extend(pair)
    for field in ("chicks_a", "chicks_b"):
        validate_pairs(level.get(field), field)
        if len(level[field]) > 16:
            raise ValueError(f"{field} exceeds the sixteen chick object slots")
        output.append(len(level[field]))
        for pair in level[field]:
            output.extend(pair)
    baseline_bytes = level.get("baseline_bytes", [])
    if baseline_bytes:
        decoded = decode_level(baseline_bytes)
        compared_fields = (
            "collision", "player", "entry_arrow", "cat_door", "exit_door",
            "background_group_3", "background_group_4", "background_group_5",
            "spawners", "chicks_a", "chicks_b",
        )
        if all(decoded[field] == level[field] for field in compared_fields):
            return baseline_bytes
    if len(output) % 2:
        output.append(0)
    return output


def encode_special(level: dict[str, Any]) -> list[int]:
    groups = []
    for field in ("flag_7", "flag_7_6", "flag_5"):
        validate_pairs(level.get(field), field)
        if len(level[field]) > 0xFF:
            raise ValueError(f"{field} exceeds 255 entries")
        groups.append(level[field])
    baseline = level.get("baseline_special_bytes", [])
    if baseline:
        decoded = decode_special(baseline)
        if all(decoded[field] == level[field] for field in ("flag_7", "flag_7_6", "flag_5")):
            return baseline
    output: list[int] = []
    for pairs in groups:
        output.append(len(pairs))
        for pair in pairs:
            output.extend(pair)
    if len(output) % 2:
        output.append(0)
    return output


def export_document(root: Path) -> dict[str, Any]:
    tables_text = (root / "src/data/tables.s").read_text(encoding="utf-8")
    special_text = (root / "src/data/level_layout.s").read_text(encoding="utf-8")
    level_blocks = named_blocks(tables_text, "Level_Data", "Unused_Block2:", 1)
    special_words = named_blocks(special_text, "Level_SpecialTiles", "Lizard_JumpArcTable:", 2)
    special_blocks = [
        [byte for word in words for byte in (word >> 8, word & 0xFF)]
        for words in special_words
    ]
    layouts = []
    for identifier, (level_bytes, special_bytes) in enumerate(zip(level_blocks, special_blocks)):
        level = decode_level(level_bytes)
        special = decode_special(special_bytes)
        layouts.append({
            "id": identifier,
            **level,
            "flag_7": special["flag_7"],
            "flag_7_6": special["flag_7_6"],
            "flag_5": special["flag_5"],
            "baseline_special_bytes": special_bytes,
        })
    # The original leaves $465F bytes of $FF between the last level and the
    # fixed ROM-end marker. Edited layouts may consume that declared slack;
    # p2bin fills whatever remains with the canonical $FF byte.
    level_capacity = ROUND_COUNT * 2 + sum(len(block) for block in level_blocks) + 0x465F
    special_capacity = ROUND_COUNT * 2 + sum(len(block) for block in special_blocks)
    return {
        "schema_version": 1,
        "profile": "canonical",
        "map": {"width": MAP_WIDTH, "height": MAP_HEIGHT},
        "round_layouts": pointer_indices(tables_text, "Level_DataPointers", "Level_Data0", "Level_Data"),
        "round_special_layouts": pointer_indices(
            special_text,
            "Level_SpecialTilePointers",
            "Level_SpecialTiles0",
            "Level_SpecialTiles",
        ),
        "capacities": {
            "level_data_bytes": level_capacity,
            "special_tiles_bytes": special_capacity,
        },
        "layouts": layouts,
    }


def validate_document(document: dict[str, Any]) -> tuple[list[list[int]], list[list[int]]]:
    if document.get("schema_version") != 1 or document.get("profile") != "canonical":
        raise ValueError("unsupported level document schema or profile")
    if document.get("map") != {"width": MAP_WIDTH, "height": MAP_HEIGHT}:
        raise ValueError("level map geometry differs from 32x28")
    layouts = document.get("layouts")
    if not isinstance(layouts, list) or len(layouts) != LEVEL_COUNT:
        raise ValueError(f"level document must contain {LEVEL_COUNT} unique layouts")
    if [layout.get("id") for layout in layouts] != list(range(LEVEL_COUNT)):
        raise ValueError("level layout identifiers differ from 0..35")
    for field in ("round_layouts", "round_special_layouts"):
        values = document.get(field)
        if (
            not isinstance(values, list)
            or len(values) != ROUND_COUNT
            or any(not isinstance(value, int) or not 0 <= value < LEVEL_COUNT for value in values)
        ):
            raise ValueError(f"{field} must contain {ROUND_COUNT} valid layout indices")
    levels = [encode_level(layout) for layout in layouts]
    specials = [encode_special(layout) for layout in layouts]
    capacities = document.get("capacities", {})
    level_used = ROUND_COUNT * 2 + sum(len(block) for block in levels)
    special_used = ROUND_COUNT * 2 + sum(len(block) for block in specials)
    if level_used > capacities.get("level_data_bytes", 0):
        raise ValueError(f"level data uses {level_used} bytes, capacity is {capacities.get('level_data_bytes')}")
    if special_used > capacities.get("special_tiles_bytes", 0):
        raise ValueError(
            f"special-tile data uses {special_used} bytes, capacity is "
            f"{capacities.get('special_tiles_bytes')}"
        )
    return levels, specials


def hex_byte(value: int) -> str:
    return f"${value:02X}"


def render_values(label: str, directive: str, values: list[int], per_line: int) -> list[str]:
    lines = []
    for offset in range(0, len(values), per_line):
        chunk = values[offset:offset + per_line]
        prefix = f"{label}:".ljust(16) if offset == 0 else " " * 16
        if directive == "dc.b":
            operands = ", ".join(hex_byte(value) for value in chunk)
        else:
            words = [(chunk[index] << 8) | chunk[index + 1] for index in range(0, len(chunk), 2)]
            operands = ", ".join(f"${value:04X}" for value in words)
        lines.append(f"{prefix}{directive.ljust(7)} {operands}")
    return lines


def render_level_section(document: dict[str, Any], levels: list[list[int]]) -> str:
    lines = [
        "Level_DataPointers:".ljust(24)
        + f"dc.w    Level_Data{document['round_layouts'][0]}-Sys_GameEntryPoint"
    ]
    for index in document["round_layouts"][1:]:
        lines.append(" " * 16 + f"dc.w    Level_Data{index}-Sys_GameEntryPoint")
    for index, values in enumerate(levels):
        lines.extend(render_values(f"Level_Data{index}", "dc.b", values, 10))
    return "\n".join(lines) + "\n"


def render_special_section(document: dict[str, Any], specials: list[list[int]]) -> str:
    lines = [
        "Level_SpecialTilePointers:".ljust(32)
        + f"dc.w    Level_SpecialTiles{document['round_special_layouts'][0]}-Sys_GameEntryPoint"
    ]
    for index in document["round_special_layouts"][1:]:
        lines.append(" " * 16 + f"dc.w    Level_SpecialTiles{index}-Sys_GameEntryPoint")
    for index, values in enumerate(specials):
        lines.extend(render_values(f"Level_SpecialTiles{index}", "dc.w", values, 20))
    used = ROUND_COUNT * 2 + sum(len(block) for block in specials)
    padding = document["capacities"]["special_tiles_bytes"] - used
    if padding:
        if padding % 2:
            raise ValueError("special-tile padding must remain word aligned")
        lines.append(" " * 16 + f"dc.w    [{padding // 2}]$FFFF")
    return "\n".join(lines) + "\n"


def replace_source_range(path: Path, start: str, end: str, replacement: str) -> None:
    text = path.read_text(encoding="utf-8")
    begin = text.find(start)
    finish = text.find(end, begin + len(start))
    if begin < 0 or finish < 0:
        raise ValueError(f"source range not found in {path}: {start} .. {end}")
    path.write_text(text[:begin] + replacement + text[finish:], encoding="utf-8", newline="\n")


def apply_document(document: dict[str, Any], staged_source: Path) -> None:
    levels, specials = validate_document(document)
    replace_source_range(
        staged_source / "data/tables.s",
        "Level_DataPointers:",
        "Unused_Block2:",
        render_level_section(document, levels),
    )
    replace_source_range(
        staged_source / "data/level_layout.s",
        "Level_SpecialTilePointers:",
        "Lizard_JumpArcTable:",
        render_special_section(document, specials),
    )


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8", newline="\n")
    temporary.replace(path)


def load_document(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("export", "validate"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--workspace", default="content/workspace/level/levels.json")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    workspace = root / args.workspace
    try:
        if args.command == "export":
            if workspace.exists() and not args.force:
                print(f"[OK] Level workspace already exists: {workspace}")
                return 0
            document = export_document(root)
            validate_document(document)
            atomic_write_json(workspace, document)
            print(f"[OK] Exported {LEVEL_COUNT} unique layouts and {ROUND_COUNT} round slots")
        else:
            document = load_document(workspace)
            levels, specials = validate_document(document)
            print(
                f"[OK] Valid level document: {len(levels)} layouts, "
                f"{sum(len(value) for value in levels)} data bytes, "
                f"{sum(len(value) for value in specials)} special-tile bytes"
            )
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        fail(str(error))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Semantic model and source rewriter for Flicky's Z80 sound banks."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any


SOURCE = "src/sound/z80/data.asm"
LABEL_RE = re.compile(r"^(?P<label>[A-Za-z_][A-Za-z0-9_]*):", re.MULTILINE)
BYTE_LINE_RE = re.compile(r"^\s*dc\.b\s+(?P<values>[^;]+?)(?:\s*;.*)?$")
NUMBER_RE = re.compile(r"^(?:\$[0-9A-Fa-f]+|[0-9]+)$")
SFX_HEADER_RE = re.compile(
    r"^\s*sfxheader\s+(?P<voices>\w+),(?P<scale>[^,]+),(?P<count>[^\s]+)\s*$"
)
SFX_TRACK_RE = re.compile(
    r"^\s*sfxtrack\s+(?P<flags>[^,]+),(?P<channel>[^,]+),(?P<sequence>\w+),"
    r"(?P<transpose>[^,]+),(?P<volume>[^\s]+)\s*$"
)
MUSIC_HEADER_RE = re.compile(
    r"^\s*musicheader\s+(?P<voices>\w+),(?P<fmcount>[^,]+),(?P<psgcount>[^,]+),"
    r"(?P<scale>[^,]+),(?P<tempo>[^\s]+)\s*$"
)
MUSIC_FM_RE = re.compile(
    r"^\s*musicfm\s+(?P<sequence>\w+),(?P<transpose>[^,]+),(?P<volume>[^\s]+)\s*$"
)
MUSIC_PSG_RE = re.compile(
    r"^\s*musicpsg\s+(?P<sequence>\w+),(?P<transpose>[^,]+),(?P<volume>[^,]+),"
    r"(?P<pitchenv>[^,]+),(?P<volumeenv>[^\s]+)\s*$"
)

COMMANDS = {
    0xE0: ("set_ams_fms", 1), 0xE1: ("set_frequency_offset", 1),
    0xE2: ("set_coord_value", 1), 0xE3: ("stop_track_command", 0),
    0xE4: ("setup_modulation", 5), 0xE5: ("add_frequency", 2),
    0xE6: ("add_volume", 1), 0xE7: ("hold", 0),
    0xE8: ("set_note_fill", 1), 0xE9: ("set_lfo", 2),
    0xEA: ("set_rom_bank", 3), 0xEB: ("add_rom_bank", 3),
    0xEC: ("adjust_psg_volume", 1), 0xED: ("write_fm_channel", 2),
    0xEE: ("write_fm_port0", 2), 0xEF: ("set_voice", 1),
    0xF0: ("set_pitch_envelope", 4), 0xF1: ("set_pitch_slide", 2),
    0xF2: ("stop_track", 0), 0xF3: ("set_psg_noise", 1),
    0xF4: ("pitch_slide_value", 1), 0xF5: ("set_psg_volume_envelope", 1),
    0xF6: ("jump", 2), 0xF7: ("loop", 4),
    0xF8: ("call", 2), 0xF9: ("return", 0),
    0xFA: ("set_duration_multiplier", 1), 0xFB: ("add_transpose", 1),
    0xFC: ("set_raw_frequency_mode", 1), 0xFD: ("set_pitch_mode", 1),
    0xFE: ("set_fm3_special_mode", 4), 0xFF: ("fm_operator_command", 2),
}

VOICE_FIELDS = (
    "algorithm_feedback",
    "detune_multiple_op1", "detune_multiple_op2", "detune_multiple_op3", "detune_multiple_op4",
    "rate_scale_attack_op1", "rate_scale_attack_op2", "rate_scale_attack_op3", "rate_scale_attack_op4",
    "am_decay1_op1", "am_decay1_op2", "am_decay1_op3", "am_decay1_op4",
    "decay2_op1", "decay2_op2", "decay2_op3", "decay2_op4",
    "decay_level_release_op1", "decay_level_release_op2", "decay_level_release_op3", "decay_level_release_op4",
    "total_level_op1", "total_level_op2", "total_level_op3", "total_level_op4",
)

OPERATOR_FIELDS = (
    "detune", "multiple", "rate_scale", "attack", "amplitude_modulation",
    "decay_1", "decay_2", "sustain_level", "release", "total_level",
)


def decode_fm_voice(data: list[int]) -> dict[str, Any]:
    """Decode the driver's 25-byte FM voice into synthesizer parameters."""
    if len(data) != 25 or any(not _valid_byte(value) for value in data):
        raise ValueError("an FM voice must contain exactly 25 bytes")
    operators = []
    for operator in range(4):
        detune_multiple = data[1 + operator]
        rate_scale_attack = data[5 + operator]
        am_decay = data[9 + operator]
        sustain_release = data[17 + operator]
        operators.append({
            "detune": (detune_multiple >> 4) & 7,
            "multiple": detune_multiple & 15,
            "rate_scale": (rate_scale_attack >> 6) & 3,
            "attack": rate_scale_attack & 31,
            "amplitude_modulation": (am_decay >> 7) & 1,
            "decay_1": am_decay & 31,
            "decay_2": data[13 + operator] & 31,
            "sustain_level": sustain_release >> 4,
            "release": sustain_release & 15,
            "total_level": data[21 + operator] & 127,
        })
    return {
        "algorithm": data[0] & 7,
        "feedback": (data[0] >> 3) & 7,
        "operators": operators,
    }


def encode_fm_voice(parameters: dict[str, Any], original: list[int]) -> list[int]:
    """Encode semantic parameters while retaining the driver's unused bits."""
    if len(original) != 25:
        raise ValueError("an FM voice must contain exactly 25 bytes")
    result = list(original)
    algorithm = int(parameters["algorithm"])
    feedback = int(parameters["feedback"])
    if not 0 <= algorithm <= 7 or not 0 <= feedback <= 7:
        raise ValueError("algorithm and feedback must be in the range 0..7")
    result[0] = (result[0] & 0xC0) | feedback << 3 | algorithm
    operators = parameters["operators"]
    if len(operators) != 4:
        raise ValueError("an FM voice must have four operators")
    limits = (7, 15, 3, 31, 1, 31, 31, 15, 15, 127)
    for index, operator in enumerate(operators):
        values = [int(operator[name]) for name in OPERATOR_FIELDS]
        if any(not 0 <= value <= limit for value, limit in zip(values, limits)):
            raise ValueError(f"operator {index + 1} parameter is outside its YM2612 range")
        detune, multiple, rate_scale, attack, am, decay_1, decay_2, sustain, release, level = values
        result[1 + index] = (result[1 + index] & 0x80) | detune << 4 | multiple
        result[5 + index] = (result[5 + index] & 0x20) | rate_scale << 6 | attack
        result[9 + index] = (result[9 + index] & 0x60) | am << 7 | decay_1
        result[13 + index] = (result[13 + index] & 0xE0) | decay_2
        result[17 + index] = sustain << 4 | release
        result[21 + index] = (result[21 + index] & 0x80) | level
    return result


def parse_number(value: str) -> int:
    value = value.strip()
    return int(value[1:], 16) if value.startswith("$") else int(value, 10)


def format_number(value: int) -> str:
    return str(value) if value < 10 else f"${value:02X}"


def _blocks(source: str) -> dict[str, tuple[int, int, str]]:
    labels = list(LABEL_RE.finditer(source))
    result = {}
    for index, match in enumerate(labels):
        end = labels[index + 1].start() if index + 1 < len(labels) else len(source)
        result[match.group("label")] = (match.start(), end, source[match.start():end])
    return result


def _parse_headers(source: str) -> list[dict[str, Any]]:
    headers: list[dict[str, Any]] = []
    for label, (_start, _end, block) in _blocks(source).items():
        lines = block.splitlines()[1:]
        content = [line for line in lines if line.strip() and not line.lstrip().startswith(";")]
        if not content:
            continue
        sfx = SFX_HEADER_RE.fullmatch(content[0])
        music = MUSIC_HEADER_RE.fullmatch(content[0])
        if sfx:
            header = _parse_sfx_header(label, sfx, content[1:])
        elif music:
            header = _parse_music_header(label, music, content[1:])
        else:
            header = None
        if header is not None:
            headers.append(header)
    return headers


def _parse_sfx_header(label: str, match: re.Match[str], lines: list[str]) -> dict[str, Any] | None:
    count = parse_number(match.group("count"))
    tracks = []
    for line in lines:
        track = SFX_TRACK_RE.fullmatch(line)
        if not track:
            continue
        tracks.append({
            "type": "sfx",
            "flags": parse_number(track.group("flags")),
            "channel": parse_number(track.group("channel")),
            "sequence": track.group("sequence"),
            "transpose": parse_number(track.group("transpose")),
            "volume": parse_number(track.group("volume")),
        })
        if len(tracks) == count:
            break
    if len(tracks) != count:
        return None
    return {
        "id": label,
        "kind": "sfx",
        "voices": match.group("voices"),
        "scale": parse_number(match.group("scale")),
        "tracks": tracks,
    }


def export_document(path: Path) -> dict[str, Any]:
    source = path.read_text(encoding="utf-8")
    blocks = _blocks(source)
    headers = _parse_headers(source)
    sequence_ids = sorted({track["sequence"] for header in headers for track in header["tracks"]})
    voice_ids = sorted({header["voices"] for header in headers})
    sequences = []
    for identifier in sequence_ids:
        data = _byte_block(blocks[identifier][2])
        if data is None:
            raise ValueError(f"{identifier}: sequence is not a numeric byte block")
        sequences.append({"id": identifier, "bytes": data})
    voice_banks = []
    for identifier in voice_ids:
        data = _byte_block(blocks[identifier][2])
        if data is None:
            raise ValueError(f"{identifier}: voice bank is not a numeric byte block")
        count = len(data) // 25
        voice_banks.append({
            "id": identifier,
            "voices": [data[index * 25:(index + 1) * 25] for index in range(count)],
            "tail": data[count * 25:],
        })
    priority_envelopes = _byte_block(blocks["zPriorityAndEnvelopeData"][2])
    if priority_envelopes is None:
        raise ValueError("priority/envelope area is not a numeric byte block")
    return {
        "schema_version": 1,
        "profile": "canonical",
        "headers": headers,
        "sequences": sequences,
        "voice_banks": voice_banks,
        "priority_envelopes": priority_envelopes,
    }


def _table(document: dict[str, Any], key: str) -> dict[str, dict[str, Any]]:
    records = document.get(key)
    if not isinstance(records, list):
        raise ValueError(f"sound document has no {key} list")
    result: dict[str, dict[str, Any]] = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("id"), str):
            raise ValueError(f"sound document contains an invalid {key} record")
        if record["id"] in result:
            raise ValueError(f"sound document contains duplicate {key}: {record['id']}")
        result[record["id"]] = record
    return result


def _valid_byte(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and 0 <= value <= 0xFF


def validate_document(document: dict[str, Any], baseline_path: Path) -> None:
    if document.get("schema_version") != 1 or document.get("profile") != "canonical":
        raise ValueError("unsupported sound document schema or profile")
    baseline = export_document(baseline_path)
    for key in ("headers", "sequences", "voice_banks"):
        if set(_table(document, key)) != set(_table(baseline, key)):
            raise ValueError(f"sound {key} identity differs from the source inventory")
    expected_sequences = _table(baseline, "sequences")
    for sequence in document["sequences"]:
        data = sequence.get("bytes")
        expected = expected_sequences[sequence["id"]]["bytes"]
        if not isinstance(data, list) or len(data) != len(expected):
            raise ValueError(f"{sequence['id']}: sequence capacity differs")
        if any(not _valid_byte(value) for value in data):
            raise ValueError(f"{sequence['id']}: sequence contains an invalid byte")
    expected_voices = _table(baseline, "voice_banks")
    for bank in document["voice_banks"]:
        expected = expected_voices[bank["id"]]
        voices = bank.get("voices")
        tail = bank.get("tail")
        if not isinstance(voices, list) or len(voices) != len(expected["voices"]):
            raise ValueError(f"{bank['id']}: FM voice count differs")
        if any(not isinstance(voice, list) or len(voice) != 25 for voice in voices):
            raise ValueError(f"{bank['id']}: every FM voice must contain 25 bytes")
        if any(not _valid_byte(value) for voice in voices for value in voice):
            raise ValueError(f"{bank['id']}: FM voice contains an invalid byte")
        if not isinstance(tail, list) or len(tail) != len(expected["tail"]) or any(not _valid_byte(value) for value in tail):
            raise ValueError(f"{bank['id']}: voice-bank tail differs")
    priority = document.get("priority_envelopes")
    if (
        not isinstance(priority, list)
        or len(priority) != len(baseline["priority_envelopes"])
        or any(not _valid_byte(value) for value in priority)
    ):
        raise ValueError("priority/envelope area capacity or byte value differs")

    expected_headers = _table(baseline, "headers")
    voice_ids = set(expected_voices)
    sequence_ids = set(expected_sequences)
    for header in document["headers"]:
        expected = expected_headers[header["id"]]
        tracks = header.get("tracks")
        if (
            header.get("kind") != expected["kind"]
            or header.get("voices") not in voice_ids
            or not _valid_byte(header.get("scale"))
            or not isinstance(tracks, list)
            or len(tracks) != len(expected["tracks"])
        ):
            raise ValueError(f"{header['id']}: header shape differs")
        if header["kind"] == "music" and not _valid_byte(header.get("tempo")):
            raise ValueError(f"{header['id']}: invalid tempo")
        for track, expected_track in zip(tracks, expected["tracks"]):
            if track.get("type") != expected_track["type"] or track.get("sequence") not in sequence_ids:
                raise ValueError(f"{header['id']}: invalid track identity")
            fields = ["transpose", "volume"]
            if track["type"] == "sfx":
                fields += ["flags", "channel"]
            elif track["type"] == "psg":
                fields += ["pitch_envelope", "volume_envelope"]
            if any(not _valid_byte(track.get(field)) for field in fields):
                raise ValueError(f"{header['id']}: invalid track field")


def describe_sequence(data: list[int]) -> list[dict[str, Any]]:
    events = []
    offset = 0
    while offset < len(data):
        value = data[offset]
        if value < 0x80:
            name, count = "duration", 0
        elif value < 0xE0:
            name = "rest" if value == 0x80 else f"note_{value - 0x81:02X}"
            count = 0
        else:
            name, count = COMMANDS[value]
            if value == 0xEF and offset + 1 < len(data) and data[offset + 1] & 0x80:
                count = 2
            elif value == 0xFF and offset + 1 < len(data):
                subcommand = data[offset + 1] & 7
                count = 3 if subcommand == 7 else 2
        end = min(len(data), offset + 1 + count)
        events.append({
            "offset": offset,
            "size": end - offset,
            "name": name,
            "bytes": data[offset:end],
        })
        offset = end
    return events


def piano_roll_notes(data: list[int]) -> list[dict[str, Any]]:
    """Return the linear note/rest events in a sequence for semantic editing.

    Control-flow commands remain untouched.  A note without its own duration
    points at the earlier duration byte it inherits, matching the Z80 driver.
    """
    result = []
    offset = 0
    tick = 0
    saved_duration = 0
    duration_source = None
    while offset < len(data):
        value = data[offset]
        if value < 0x80:
            if value == 0:
                raise ValueError(f"zero duration at sequence offset ${offset:04X}")
            saved_duration = value
            duration_source = offset
            tick += value
            offset += 1
            continue
        if value < 0xE0:
            note_offset = offset
            offset += 1
            explicit = offset < len(data) and data[offset] < 0x80
            if explicit:
                if data[offset] == 0:
                    raise ValueError(f"zero duration at sequence offset ${offset:04X}")
                saved_duration = data[offset]
                duration_source = offset
                offset += 1
            duration = saved_duration or 1
            result.append({
                "offset": note_offset,
                "duration_offset": duration_source,
                "duration_is_shared": not explicit,
                "start": tick,
                "duration": duration,
                "note": None if value == 0x80 else value - 0x81,
                "rest": value == 0x80,
            })
            tick += duration
            continue
        _name, count = COMMANDS[value]
        if value == 0xEF and offset + 1 < len(data) and data[offset + 1] & 0x80:
            count = 2
        elif value == 0xFF and offset + 1 < len(data):
            count = 3 if data[offset + 1] & 7 == 7 else 2
        offset = min(len(data), offset + 1 + count)
    return result


def _render_byte_block(identifier: str, data: list[int]) -> str:
    chunks = [data[index:index + 16] for index in range(0, len(data), 16)] or [[]]
    lines = []
    for index, chunk in enumerate(chunks):
        prefix = f"{identifier}:" if index == 0 else ""
        padding = " " * max(1, 16 - len(prefix))
        values = ",".join(f"${value:02X}" for value in chunk)
        lines.append(f"{prefix}{padding}dc.b    {values}")
    return "\n".join(lines) + "\n"


def _flatten_voice_bank(bank: dict[str, Any]) -> list[int]:
    return [value for voice in bank["voices"] for value in voice] + bank["tail"]


def _rewrite_header(block: str, header: dict[str, Any]) -> str:
    lines = block.splitlines()
    track_index = 0
    for index, line in enumerate(lines):
        if SFX_HEADER_RE.fullmatch(line):
            lines[index] = (
                f"                sfxheader {header['voices']},"
                f"{format_number(header['scale'])},{len(header['tracks'])}"
            )
        elif MUSIC_HEADER_RE.fullmatch(line):
            fmcount = sum(track["type"] == "fm" for track in header["tracks"])
            psgcount = sum(track["type"] == "psg" for track in header["tracks"])
            lines[index] = (
                f"                musicheader {header['voices']},{fmcount},{psgcount},"
                f"{format_number(header['scale'])},{format_number(header['tempo'])}"
            )
        elif SFX_TRACK_RE.fullmatch(line):
            track = header["tracks"][track_index]
            lines[index] = (
                f"                sfxtrack  {format_number(track['flags'])},"
                f"{format_number(track['channel'])},{track['sequence']},"
                f"{format_number(track['transpose'])},{format_number(track['volume'])}"
            )
            track_index += 1
        elif MUSIC_FM_RE.fullmatch(line):
            track = header["tracks"][track_index]
            lines[index] = (
                f"                musicfm {track['sequence']},"
                f"{format_number(track['transpose'])},{format_number(track['volume'])}"
            )
            track_index += 1
        elif MUSIC_PSG_RE.fullmatch(line):
            track = header["tracks"][track_index]
            lines[index] = (
                f"                musicpsg {track['sequence']},"
                f"{format_number(track['transpose'])},{format_number(track['volume'])},"
                f"{format_number(track['pitch_envelope'])},{format_number(track['volume_envelope'])}"
            )
            track_index += 1
    return "\n".join(lines) + "\n"


def _parse_music_header(label: str, match: re.Match[str], lines: list[str]) -> dict[str, Any] | None:
    fmcount = parse_number(match.group("fmcount"))
    psgcount = parse_number(match.group("psgcount"))
    tracks = []
    for line in lines:
        fm = MUSIC_FM_RE.fullmatch(line)
        psg = MUSIC_PSG_RE.fullmatch(line)
        if fm:
            tracks.append({
                "type": "fm",
                "sequence": fm.group("sequence"),
                "transpose": parse_number(fm.group("transpose")),
                "volume": parse_number(fm.group("volume")),
            })
        elif psg:
            tracks.append({
                "type": "psg",
                "sequence": psg.group("sequence"),
                "transpose": parse_number(psg.group("transpose")),
                "volume": parse_number(psg.group("volume")),
                "pitch_envelope": parse_number(psg.group("pitchenv")),
                "volume_envelope": parse_number(psg.group("volumeenv")),
            })
        if len(tracks) == fmcount + psgcount:
            break
    if len(tracks) != fmcount + psgcount:
        return None
    return {
        "id": label,
        "kind": "music",
        "voices": match.group("voices"),
        "scale": parse_number(match.group("scale")),
        "tempo": parse_number(match.group("tempo")),
        "tracks": tracks,
    }


def _byte_block(block: str) -> list[int] | None:
    lines = block.splitlines()
    if not lines:
        return None
    lines[0] = lines[0].split(":", 1)[1]
    result: list[int] = []
    for line in lines:
        if not line.strip() or line.lstrip().startswith(";"):
            continue
        match = BYTE_LINE_RE.fullmatch(line)
        if not match:
            return None
        values = [item.strip() for item in match.group("values").split(",")]
        if any(not NUMBER_RE.fullmatch(item) for item in values):
            return None
        result.extend(parse_number(item) for item in values)
    return result


def apply_document(document: dict[str, Any], baseline_path: Path, workspace_path: Path) -> None:
    validate_document(document, baseline_path)
    baseline = export_document(baseline_path)
    source = workspace_path.read_text(encoding="utf-8")
    blocks = _blocks(source)
    replacements: list[tuple[int, int, str]] = []

    expected_headers = _table(baseline, "headers")
    for header in document["headers"]:
        if header != expected_headers[header["id"]]:
            start, end, block = blocks[header["id"]]
            replacements.append((start, end, _rewrite_header(block, header)))

    expected_sequences = _table(baseline, "sequences")
    for sequence in document["sequences"]:
        if sequence != expected_sequences[sequence["id"]]:
            start, end, _block = blocks[sequence["id"]]
            replacements.append((start, end, _render_byte_block(sequence["id"], sequence["bytes"])))

    expected_voices = _table(baseline, "voice_banks")
    for bank in document["voice_banks"]:
        if bank != expected_voices[bank["id"]]:
            start, end, _block = blocks[bank["id"]]
            replacements.append((start, end, _render_byte_block(bank["id"], _flatten_voice_bank(bank))))

    if document["priority_envelopes"] != baseline["priority_envelopes"]:
        start, end, _block = blocks["zPriorityAndEnvelopeData"]
        replacements.append((
            start,
            end,
            _render_byte_block("zPriorityAndEnvelopeData", document["priority_envelopes"]),
        ))

    for start, end, replacement in sorted(replacements, reverse=True):
        source = source[:start] + replacement + source[end:]
    temporary = workspace_path.with_suffix(workspace_path.suffix + ".tmp")
    temporary.write_text(source, encoding="utf-8", newline="\n")
    temporary.replace(workspace_path)
    if export_document(workspace_path) != document:
        raise ValueError("sound source regeneration did not reproduce the editor model")

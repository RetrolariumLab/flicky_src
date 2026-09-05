#!/usr/bin/env python3
"""Decode the authored data formats and check what each one round-trips to."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))

import enigma_dec  # noqa: E402
import nemesis_dec  # noqa: E402
import nemesis_enc  # noqa: E402


# --------------------------------------------------------------------------
# Codecs. Each decode returns structured data; each encode returns bytes.
# --------------------------------------------------------------------------

def decode_palette_compact(data: bytes) -> list[dict]:
    """Unpack the compact palette form read by Gfx_LoadPaletteCompact.

    One word per entry: the colour lives in bits $EEE, the CRAM index is
    assembled from bit 4, the top nibble and bit 8, and bit 0 terminates the
    list.
    """
    entries = []
    for offset in range(0, len(data), 2):
        word = int.from_bytes(data[offset:offset + 2], "big")
        index = (word & 0x10) | ((word >> 12) & 0xF) | ((word & 0x100) >> 3)
        entries.append({
            "index": index,
            "colour": word & 0xEEE,
            "last": bool(word & 1),
        })
        if word & 1:
            break
    return entries


def encode_palette_compact(entries: list[dict]) -> bytes:
    out = bytearray()
    for entry in entries:
        index = entry["index"]
        word = entry["colour"] & 0xEEE
        word |= (index & 0x10)
        word |= (index & 0xF) << 12
        word |= (index & 0x20) << 3
        word |= 1 if entry["last"] else 0
        out += word.to_bytes(2, "big")
    return bytes(out)


def decode_demo_input(data: bytes) -> list[dict]:
    """Pairs of controller byte and hold count, as Demo_ReadInput consumes them."""
    return [
        {"buttons": data[offset], "frames": data[offset + 1]}
        for offset in range(0, len(data) - 1, 2)
    ]


def encode_demo_input(entries: list[dict]) -> bytes:
    return bytes(byte for e in entries for byte in (e["buttons"], e["frames"]))


def decode_velocity_pairs(data: bytes) -> list[dict]:
    """Signed 16.16 velocity pairs, one per round, as Lizard_StateJump loads them."""
    def signed(value: int) -> int:
        return value - 0x100000000 if value & 0x80000000 else value

    return [
        {
            "x": signed(int.from_bytes(data[offset:offset + 4], "big")),
            "y": signed(int.from_bytes(data[offset + 4:offset + 8], "big")),
        }
        for offset in range(0, len(data) - 7, 8)
    ]


def encode_velocity_pairs(entries: list[dict]) -> bytes:
    out = bytearray()
    for entry in entries:
        for key in ("x", "y"):
            out += (entry[key] & 0xFFFFFFFF).to_bytes(4, "big")
    return bytes(out)


def decode_tilemap_words(data: bytes) -> list[int]:
    return [
        int.from_bytes(data[offset:offset + 2], "big")
        for offset in range(0, len(data) - 1, 2)
    ]


def encode_tilemap_words(words: list[int]) -> bytes:
    return b"".join(word.to_bytes(2, "big") for word in words)


def decode_font_1bpp(data: bytes) -> list[list[int]]:
    """One byte per 8-pixel row; expanded to 4bpp at load time."""
    return [
        [(byte >> shift) & 1 for shift in range(7, -1, -1)]
        for byte in data
    ]


def encode_font_1bpp(rows: list[list[int]]) -> bytes:
    out = bytearray()
    for row in rows:
        byte = 0
        for bit in row:
            byte = (byte << 1) | bit
        out.append(byte)
    return bytes(out)


CODECS = {
    "palette_compact": (decode_palette_compact, encode_palette_compact),
    "demo_input": (decode_demo_input, encode_demo_input),
    "velocity_pairs": (decode_velocity_pairs, encode_velocity_pairs),
    "tilemap_words": (decode_tilemap_words, encode_tilemap_words),
    "font_1bpp": (decode_font_1bpp, encode_font_1bpp),
}


# --------------------------------------------------------------------------
# Checks
# --------------------------------------------------------------------------

def check_exact(data: bytes, codec: str) -> tuple[bool, str]:
    decode, encode = CODECS[codec]
    decoded = decode(data)
    again = encode(decoded)
    if again == data:
        return True, f"{len(data)} bytes, {len(decoded)} entries, re-encoded exactly"
    span = min(len(again), len(data))
    first = next((i for i in range(span) if again[i] != data[i]), span)
    return False, f"re-encoded {len(again)} bytes vs {len(data)}, first difference at {first}"


def check_nemesis(data: bytes) -> tuple[bool, str]:
    """Semantic round trip: re-encode, decode again, require identical pixels.

    Byte-identical re-encoding is not achievable here; see DATA-002.
    """
    plain = nemesis_dec.decompress(data)
    again = nemesis_enc.compress(plain, data)
    replain = nemesis_dec.decompress(again)
    if replain != plain:
        return False, "re-encoded stream does not decode back to the same pixels"
    exact = " and byte-identical" if again == data else ""
    return True, (
        f"{len(data)} -> {len(plain)} bytes, re-encoded to {len(again)} bytes, "
        f"decodes identically{exact}"
    )


def check_enigma(data: bytes) -> tuple[bool, str]:
    plain = enigma_dec.decompress(data)
    if not plain:
        return False, "decoded to nothing"
    return True, f"{len(data)} -> {len(plain)} bytes, decode only (DATA-002)"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="config/data_formats.json")
    parser.add_argument("--data-dir", default="data")
    parser.add_argument("--summary", help="Write a JSON summary here")
    args = parser.parse_args()

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1:
        print(f"[ERROR] unsupported schema_version", file=sys.stderr)
        return 1

    results = []
    failures = 0
    counts = {"exact": 0, "semantic": 0, "decode_only": 0, "none": 0}

    for artifact in manifest["artifacts"]:
        path = Path(args.data_dir) / artifact["path"]
        kind = artifact["round_trip"]
        counts[kind] = counts.get(kind, 0) + 1

        if kind == "none":
            print(f"[INFO] {artifact['segment']}: opaque, no codec")
            results.append({**artifact, "ok": True, "detail": "opaque"})
            continue

        if not path.is_file():
            print(f"[ERROR] {artifact['segment']}: missing {path}", file=sys.stderr)
            failures += 1
            continue

        data = path.read_bytes()
        codec = artifact["codec"]
        if codec == "nemesis":
            ok, detail = check_nemesis(data)
        elif codec == "enigma":
            ok, detail = check_enigma(data)
        else:
            ok, detail = check_exact(data, codec)

        results.append({**artifact, "ok": ok, "detail": detail})
        if ok:
            print(f"[OK] {artifact['segment']}: {detail}")
        else:
            print(f"[ERROR] {artifact['segment']}: {detail}", file=sys.stderr)
            failures += 1

    if args.summary:
        summary_path = Path(args.summary)
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        summary_path.write_text(
            json.dumps({"results": results, "counts": counts}, indent=2) + "\n",
            encoding="utf-8",
            newline="",
        )

    if failures:
        print(f"[FAIL] {failures} artifact(s) did not round-trip as declared", file=sys.stderr)
        return 1

    print(
        f"[OK] {counts['exact']} exact, {counts['semantic']} semantic, "
        f"{counts['decode_only']} decode-only, {counts['none']} opaque"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

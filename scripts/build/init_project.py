#!/usr/bin/env python3
"""Initialize the project: validate the reference ROM, extract data, verify the build."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def step(number: int, total: int, title: str) -> None:
    print(f"\n[RUN] Step {number}/{total}: {title}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--orig-rom", default="Flicky (UE) [!].bin", help="Reference ROM")
    parser.add_argument("--manifest", default="assets/manifest.json", help="Asset manifest")
    parser.add_argument("--data-dir", default="data", help="Data directory")
    parser.add_argument("--data-addrs", default="data/data_addrs.txt", help="Segment addresses")
    parser.add_argument("--source", default="src/main.s", help="Assembly source")
    parser.add_argument("--obj", default="build/main.p", help="AS object file")
    parser.add_argument("--output", default="fbuilt.bin", help="Output ROM")
    parser.add_argument("--as-bin", default="bin/asw.exe", help="AS assembler")
    parser.add_argument("--p2bin", default="bin/p2bin.exe", help="p2bin converter")
    parser.add_argument("--as-args", default="-maxerrors 2", help="AS arguments")
    parser.add_argument("--z80-source", default="src/sound/z80/driver.asm")
    parser.add_argument("--z80-obj", default="build/z80_driver.p")
    parser.add_argument("--z80-output", default="build/z80_driver.bin")
    parser.add_argument("--z80-reference", default="data/sound/data_z80_part1.bin")
    parser.add_argument("--z80-data-source", default="src/sound/z80/data.asm")
    parser.add_argument("--z80-data-obj", default="build/z80_sound_data.p")
    parser.add_argument("--z80-data-output", default="build/z80_sound_data.bin")
    parser.add_argument("--z80-data-reference", default="data/sound/data_z80_part2.bin")
    args = parser.parse_args()

    runner = Path(__file__).resolve().parents[1] / "run.py"
    rom_path = Path(args.orig_rom)

    step(1, 3, "Validating the reference ROM")
    if not rom_path.is_file():
        fail(
            f"Reference ROM not found: {rom_path}\n"
            "        Place a legally obtained cartridge dump in the project root."
        )
    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    reference = manifest["reference_rom"]
    data = rom_path.read_bytes()
    digest = hashlib.sha1(data).hexdigest()
    if digest != reference["sha1"]:
        fail(
            f"{rom_path.name} is not the supported revision.\n"
            f"        expected SHA1 {reference['sha1']} ({reference['name']})\n"
            f"        actual   SHA1 {digest}"
        )
    print(f"[OK] {rom_path.name}: {len(data)} bytes, SHA1 {digest}")

    step(2, 3, "Extracting data segments from the reference ROM")
    result = subprocess.run(
        [
            sys.executable,
            str(runner),
            "build.split_data_from_rom",
            "--rom-file", str(rom_path),
            "--output", args.data_dir,
            "--addrs", args.data_addrs,
        ]
    )
    if result.returncode != 0:
        fail("Data extraction failed")

    result = subprocess.run(
        [
            sys.executable,
            str(runner),
            "build.check_assets",
            "--manifest", args.manifest,
            "--asset-dir", args.data_dir,
        ]
    )
    if result.returncode != 0:
        fail("Extracted segments do not match the manifest")

    step(3, 3, "Building and verifying the ROM")
    for source, obj, output, reference, extra in (
        (args.z80_source, args.z80_obj, args.z80_output, args.z80_reference, []),
        (
            args.z80_data_source,
            args.z80_data_obj,
            args.z80_data_output,
            args.z80_data_reference,
            ["--reference-offset", "12", "--description", "Z80 sound-data banks"],
        ),
    ):
        result = subprocess.run(
            [
                sys.executable,
                str(runner),
                "build.build_z80_driver",
                "--source", source,
                "--obj", obj,
                "--output", output,
                "--reference", reference,
                "--as-bin", args.as_bin,
                "--p2bin", args.p2bin,
                "--as-args", args.as_args,
                *extra,
            ]
        )
        if result.returncode != 0:
            fail(f"Z80 component build failed: {source}")

    result = subprocess.run(
        [
            sys.executable,
            str(runner),
            "build.build_rom",
            "--source", args.source,
            "--output", args.output,
            "--obj", args.obj,
            "--manifest", args.manifest,
            "--original-rom", str(rom_path),
            "--as-bin", args.as_bin,
            "--p2bin", args.p2bin,
            "--as-args", args.as_args,
            "--verify",
        ]
    )
    if result.returncode != 0:
        fail("The build does not reproduce the reference ROM")

    print("\n[OK] Project initialized. The source reproduces the reference ROM byte for byte.")
    print("[INFO] Next: 'make verify' after every change; 'make help' lists the workflow.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

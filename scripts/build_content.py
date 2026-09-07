#!/usr/bin/env python3
"""Build an isolated Flicky ROM from the editable content workspace."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from content_workspace import load_manifest, stage_sources, validate_workspace
from graphics_studio_model import (
    build_assets as build_graphics_assets,
    export_document as export_graphics_document,
    load_document as load_graphics_document,
    redirect_includes as redirect_graphics_includes,
)
from graphics_semantics_model import (
    apply_document as apply_graphics_semantics,
    export_document as export_graphics_semantics,
    load_document as load_graphics_semantics,
)
from graphics_sequences_model import (
    apply_document as apply_graphics_sequences,
    export_document as export_graphics_sequences,
    load_document as load_graphics_sequences,
)
from level_studio_model import apply_document, export_document, load_document


def run(command: list[str], root: Path) -> None:
    print(f"[RUN] {' '.join(command)}")
    result = subprocess.run(command, cwd=root)
    if result.returncode:
        raise SystemExit(result.returncode)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="config/content_studios.json")
    parser.add_argument("--root", default=".")
    parser.add_argument("--as-bin", required=True)
    parser.add_argument("--p2bin", required=True)
    parser.add_argument("--as-args", default="-maxerrors 2")
    parser.add_argument("--original-rom", default="Flicky (UE) [!].bin")
    parser.add_argument("--asset-manifest", default="assets/manifest.json")
    parser.add_argument("--zero-edit", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    manifest = load_manifest(root / args.manifest)
    artifact = next(item for item in manifest["artifacts"] if item["id"] == "z80_sound_banks")
    baseline_source = root / artifact["baseline"]
    if args.zero_edit:
        sound_source = baseline_source
        build_dir = root / "build" / "content" / "zero-edit"
        rom_output = build_dir / "flicky.bin"
    else:
        validate_workspace(root, manifest)
        sound_source = root / manifest["workspace"] / artifact["workspace"]
        build_dir = root / "build" / "content"
        rom_output = root / manifest["output"]
    driver_output = build_dir / "z80_driver.bin"
    sound_output = build_dir / "z80_sound_data.bin"
    build_dir.mkdir(parents=True, exist_ok=True)

    common = [
        "--as-bin", str(Path(args.as_bin).resolve()),
        "--p2bin", str(Path(args.p2bin).resolve()),
        "--as-args", args.as_args,
    ]
    run([
        sys.executable, "scripts/build_z80_driver.py",
        "--source", "src/sound/z80_driver_z80.asm",
        "--obj", str(build_dir / "z80_driver.p"),
        "--output", str(driver_output),
        "--reference", "data/sound/data_z80_part1.bin",
        "--expected-size", "4070",
        *common,
    ], root)
    sound_command = [
        sys.executable, "scripts/build_z80_driver.py",
        "--source", str(sound_source),
        "--obj", str(build_dir / "z80_sound_data.p"),
        "--output", str(sound_output),
        "--reference", "data/sound/data_z80_part2.bin",
        "--reference-offset", "12",
        "--description", "editable Z80 sound-data banks",
        "--expected-size", str(artifact["capacity"]),
        *common,
    ]
    if not args.zero_edit:
        sound_command.append("--allow-different")
    run(sound_command, root)

    staged_main = stage_sources(
        root,
        build_dir / "src",
        driver_output.relative_to(root),
        sound_output.relative_to(root),
    )
    level_artifact = next(
        item for item in manifest["artifacts"] if item["id"] == "level_layouts"
    )
    if args.zero_edit:
        level_document = export_document(root)
    else:
        level_document = load_document(
            root / manifest["workspace"] / level_artifact["workspace"]
        )
    apply_document(level_document, staged_main.parent)
    graphics_artifact = next(
        item for item in manifest["artifacts"] if item["id"] == "graphics_assets"
    )
    if args.zero_edit:
        graphics_document = export_graphics_document(root)
    else:
        graphics_document = load_graphics_document(
            root / manifest["workspace"] / graphics_artifact["workspace"]
        )
    graphics_outputs = build_graphics_assets(graphics_document, root, build_dir)
    redirect_graphics_includes(staged_main.parent, graphics_outputs)
    semantics_artifact = next(
        item for item in manifest["artifacts"] if item["id"] == "graphics_semantics"
    )
    if args.zero_edit:
        semantics_document = export_graphics_semantics(root)
    else:
        semantics_document = load_graphics_semantics(
            root / manifest["workspace"] / semantics_artifact["workspace"]
        )
    apply_graphics_semantics(semantics_document, root, staged_main.parent)
    sequences_artifact = next(
        item for item in manifest["artifacts"] if item["id"] == "graphics_sequences"
    )
    if args.zero_edit:
        sequences_document = export_graphics_sequences(root)
    else:
        sequences_document = load_graphics_sequences(
            root / manifest["workspace"] / sequences_artifact["workspace"]
        )
    apply_graphics_sequences(sequences_document, root, staged_main.parent)
    rom_command = [
        sys.executable, "scripts/build_rom.py",
        "--source", str(staged_main),
        "--obj", str(build_dir / "main.p"),
        "--output", str(rom_output),
        "--manifest", args.asset_manifest,
        "--original-rom", args.original_rom,
        *common,
    ]
    if args.zero_edit:
        rom_command.append("--verify")
    run(rom_command, root)
    print(f"[OK] Content ROM built: {rom_output.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

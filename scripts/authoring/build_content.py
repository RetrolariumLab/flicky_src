#!/usr/bin/env python3
"""Build an isolated Flicky ROM from the editable content workspace."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from authoring.content_workspace import load_manifest, stage_sources, validate_workspace
from authoring.graphics_studio_model import (
    build_assets as build_graphics_assets,
    export_document as export_graphics_document,
    load_document as load_graphics_document,
    redirect_includes as redirect_graphics_includes,
)
from authoring.graphics_semantics_model import (
    apply_document as apply_graphics_semantics,
    export_document as export_graphics_semantics,
    load_document as load_graphics_semantics,
)
from authoring.graphics_sequences_model import (
    apply_document as apply_graphics_sequences,
    export_document as export_graphics_sequences,
    load_document as load_graphics_sequences,
)
from authoring.level_studio_model import apply_document, export_document, load_document


WORKSPACE_ARGUMENTS = {
    "level_layouts": "level_workspace",
    "graphics_assets": "graphics_workspace",
    "graphics_semantics": "semantics_workspace",
    "graphics_sequences": "sequences_workspace",
    "z80_sound_banks": "sound_workspace",
}


def run(command: list[str], root: Path) -> None:
    print(f"[RUN] {' '.join(command)}")
    result = subprocess.run(command, cwd=root)
    if result.returncode:
        raise SystemExit(result.returncode)


def resolve_workspace_paths(
    root: Path, manifest: dict, overrides: dict[str, str | None]
) -> dict[str, Path]:
    """Resolve explicit inputs, falling back to manifest-owned workspace paths."""
    artifacts = {artifact["id"]: artifact for artifact in manifest["artifacts"]}
    paths: dict[str, Path] = {}
    for artifact_id in WORKSPACE_ARGUMENTS:
        value = overrides.get(artifact_id)
        if value is None:
            value = str(
                Path(manifest["workspace"]) / artifacts[artifact_id]["workspace"]
            )
        path = Path(value)
        paths[artifact_id] = (path if path.is_absolute() else root / path).resolve()
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="config/authoring/content_studios.json")
    parser.add_argument("--root", default=".")
    parser.add_argument("--as-bin", required=True)
    parser.add_argument("--p2bin", required=True)
    parser.add_argument("--as-args", default="-maxerrors 2")
    parser.add_argument("--original-rom", default="Flicky (UE) [!].bin")
    parser.add_argument("--asset-manifest", default="assets/manifest.json")
    parser.add_argument("--level-workspace")
    parser.add_argument("--graphics-workspace")
    parser.add_argument("--semantics-workspace")
    parser.add_argument("--sequences-workspace")
    parser.add_argument("--sound-workspace")
    parser.add_argument("--zero-edit", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    manifest = load_manifest(root / args.manifest)
    workspace_paths = resolve_workspace_paths(
        root,
        manifest,
        {
            artifact_id: getattr(args, argument)
            for artifact_id, argument in WORKSPACE_ARGUMENTS.items()
        },
    )
    artifact = next(item for item in manifest["artifacts"] if item["id"] == "z80_sound_banks")
    baseline_source = root / artifact["baseline"]
    if args.zero_edit:
        sound_source = baseline_source
        build_dir = root / "build" / "content" / "zero-edit"
        rom_output = build_dir / "flicky.bin"
    else:
        validate_workspace(root, manifest, overrides=workspace_paths)
        sound_source = workspace_paths["z80_sound_banks"]
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
        sys.executable, "scripts/run.py", "build.build_z80_driver",
        "--source", "src/sound/z80/driver.asm",
        "--obj", str(build_dir / "z80_driver.p"),
        "--output", str(driver_output),
        "--reference", "data/sound/data_z80_part1.bin",
        "--expected-size", "4070",
        *common,
    ], root)
    sound_command = [
        sys.executable, "scripts/run.py", "build.build_z80_driver",
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
    if args.zero_edit:
        level_document = export_document(root)
    else:
        level_document = load_document(workspace_paths["level_layouts"])
    apply_document(level_document, staged_main.parent)
    if args.zero_edit:
        graphics_document = export_graphics_document(root)
    else:
        graphics_document = load_graphics_document(workspace_paths["graphics_assets"])
    graphics_outputs = build_graphics_assets(graphics_document, root, build_dir)
    redirect_graphics_includes(staged_main.parent, graphics_outputs)
    if args.zero_edit:
        semantics_document = export_graphics_semantics(root)
    else:
        semantics_document = load_graphics_semantics(
            workspace_paths["graphics_semantics"]
        )
    apply_graphics_semantics(semantics_document, root, staged_main.parent)
    if args.zero_edit:
        sequences_document = export_graphics_sequences(root)
    else:
        sequences_document = load_graphics_sequences(
            workspace_paths["graphics_sequences"]
        )
    apply_graphics_sequences(sequences_document, root, staged_main.parent)
    rom_command = [
        sys.executable, "scripts/run.py", "build.build_rom",
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

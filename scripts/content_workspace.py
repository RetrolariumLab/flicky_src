#!/usr/bin/env python3
"""Initialize, validate, and stage Flicky's isolated content workspace."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path
from typing import Any


EXPECTED_STUDIOS = ("level", "graphics", "sound")


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def sha1(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot load content manifest {path}: {error}") from error
    errors = validate_manifest(document)
    if errors:
        raise ValueError("; ".join(errors))
    return document


def validate_manifest(document: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if document.get("schema_version") != 1:
        return ["content manifest is not schema 1"]
    if document.get("profile") != "canonical":
        errors.append("only the canonical content profile is supported")
    studios = document.get("studios", [])
    studio_ids = tuple(studio.get("id") for studio in studios)
    if studio_ids != EXPECTED_STUDIOS:
        errors.append("studio identity or order differs")
    if len(set(studio_ids)) != len(studio_ids):
        errors.append("studio identifiers are not unique")
    artifact_ids = [artifact.get("id") for artifact in document.get("artifacts", [])]
    if len(set(artifact_ids)) != len(artifact_ids):
        errors.append("artifact identifiers are not unique")
    known = set(artifact_ids)
    for studio in studios:
        if studio.get("status") not in {"planned", "foundation", "supported"}:
            errors.append(f"invalid studio status: {studio.get('id')}")
        for artifact in studio.get("artifacts", []):
            if artifact not in known:
                errors.append(f"studio {studio.get('id')} names unknown artifact {artifact}")
    for artifact in document.get("artifacts", []):
        identifier = artifact.get("id", "<missing>")
        if artifact.get("studio") not in EXPECTED_STUDIOS:
            errors.append(f"invalid artifact studio: {identifier}")
        kind = artifact.get("kind")
        if kind not in {
            "assembly_source",
            "level_document",
            "graphics_document",
            "graphics_semantics_document",
            "graphics_sequences_document",
        }:
            errors.append(f"unsupported artifact kind: {identifier}")
        if kind == "assembly_source" and (
            not isinstance(artifact.get("capacity"), int) or artifact["capacity"] <= 0
        ):
            errors.append(f"invalid artifact capacity: {identifier}")
        required_paths = (
            ("baseline", "workspace", "output")
            if kind == "assembly_source"
            else ("workspace",)
        )
        for field in required_paths:
            value = artifact.get(field)
            if not isinstance(value, str) or Path(value).is_absolute() or ".." in Path(value).parts:
                errors.append(f"invalid artifact {field}: {identifier}")
    image_sha1 = document.get("image_sha1")
    if not isinstance(image_sha1, str) or len(image_sha1) != 40:
        errors.append("invalid canonical image SHA-1")
    if document.get("image_size") != 131072:
        errors.append("canonical image size differs")
    return errors


def artifact_paths(root: Path, manifest: dict[str, Any], artifact: dict[str, Any]) -> tuple[Path, Path]:
    baseline = root / artifact["baseline"]
    workspace = root / manifest["workspace"] / artifact["workspace"]
    return baseline, workspace


def atomic_copy(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    shutil.copyfile(source, temporary)
    temporary.replace(destination)


def initialize(root: Path, manifest: dict[str, Any], force: bool = False) -> int:
    created = 0
    for artifact in manifest["artifacts"]:
        workspace = root / manifest["workspace"] / artifact["workspace"]
        if workspace.exists() and not force:
            continue
        if artifact["kind"] == "assembly_source":
            baseline = root / artifact["baseline"]
            if not baseline.is_file():
                fail(f"baseline artifact not found: {baseline}")
            atomic_copy(baseline, workspace)
        elif artifact["kind"] == "level_document":
            from level_studio_model import atomic_write_json, export_document

            atomic_write_json(workspace, export_document(root))
        elif artifact["kind"] == "graphics_document":
            from graphics_studio_model import atomic_write_json, export_document

            atomic_write_json(workspace, export_document(root))
        elif artifact["kind"] == "graphics_semantics_document":
            from graphics_semantics_model import atomic_write_json, export_document

            atomic_write_json(workspace, export_document(root))
        elif artifact["kind"] == "graphics_sequences_document":
            from graphics_sequences_model import atomic_write_json, export_document

            atomic_write_json(workspace, export_document(root))
        created += 1
    print(f"[OK] Content workspace ready ({created} artifact(s) initialized)")
    return created


def validate_workspace(root: Path, manifest: dict[str, Any], zero_edit: bool = False) -> None:
    for artifact in manifest["artifacts"]:
        workspace = root / manifest["workspace"] / artifact["workspace"]
        if not workspace.is_file():
            fail(f"workspace artifact not found: {workspace}; run make init-content")
        if artifact["kind"] == "assembly_source":
            baseline = root / artifact["baseline"]
            if not baseline.is_file():
                fail(f"baseline artifact not found: {baseline}")
            if zero_edit and workspace.read_bytes() != baseline.read_bytes():
                fail(f"zero-edit check found a modified artifact: {workspace}")
            if artifact["id"] == "z80_sound_banks":
                from sound_studio_model import export_document, validate_document

                validate_document(export_document(workspace), baseline)
        elif artifact["kind"] == "level_document":
            from level_studio_model import load_document, validate_document

            validate_document(load_document(workspace))
        elif artifact["kind"] == "graphics_document":
            from graphics_studio_model import load_document, validate_document

            validate_document(load_document(workspace), root)
        elif artifact["kind"] == "graphics_semantics_document":
            from graphics_semantics_model import load_document, validate_document

            validate_document(load_document(workspace), root)
        elif artifact["kind"] == "graphics_sequences_document":
            from graphics_sequences_model import load_document, validate_document

            validate_document(load_document(workspace), root)
    mode = "zero-edit " if zero_edit else ""
    print(f"[OK] {mode}content workspace is structurally valid")


def stage_sources(
    root: Path,
    destination: Path,
    driver_binary: Path,
    sound_binary: Path,
) -> Path:
    source_root = root / "src"
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(source_root, destination)
    replacements = {
        destination / "data" / "bank0.s": (
            'binclude "build/z80_driver.bin"',
            f'binclude "{driver_binary.as_posix()}"',
        ),
        destination / "data" / "z80_sound.s": (
            'binclude "build/z80_sound_data.bin"',
            f'binclude "{sound_binary.as_posix()}"',
        ),
    }
    for path, (old, new) in replacements.items():
        text = path.read_text(encoding="utf-8")
        if text.count(old) != 1:
            fail(f"content staging expected one include in {path}: {old}")
        path.write_text(text.replace(old, new), encoding="utf-8", newline="\n")
    return destination / "main.s"


def inspect(root: Path, manifest: dict[str, Any]) -> None:
    print(f"Profile: {manifest['profile']}")
    print(f"Workspace: {manifest['workspace']}")
    for artifact in manifest["artifacts"]:
        workspace = root / manifest["workspace"] / artifact["workspace"]
        state = "missing"
        if workspace.is_file():
            if artifact["kind"] == "assembly_source":
                baseline = root / artifact["baseline"]
                unchanged = workspace.read_bytes() == baseline.read_bytes()
            elif artifact["kind"] == "level_document":
                from level_studio_model import export_document, load_document

                unchanged = load_document(workspace) == export_document(root)
            elif artifact["kind"] == "graphics_document":
                from graphics_studio_model import export_document, load_document

                unchanged = load_document(workspace) == export_document(root)
            elif artifact["kind"] == "graphics_semantics_document":
                from graphics_semantics_model import export_document, load_document

                unchanged = load_document(workspace) == export_document(root)
            else:
                from graphics_sequences_model import export_document, load_document

                unchanged = load_document(workspace) == export_document(root)
            state = "unchanged" if unchanged else "edited"
        digest = sha1(workspace.read_bytes()) if workspace.is_file() else "-"
        print(f"{artifact['id']}: {state}, SHA1 {digest}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "validate", "inspect"))
    parser.add_argument("--manifest", default="config/content_studios.json")
    parser.add_argument("--root", default=".")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--zero-edit", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        manifest = load_manifest(root / args.manifest)
    except ValueError as error:
        fail(str(error))
    if args.command == "init":
        initialize(root, manifest, args.force)
    elif args.command == "validate":
        validate_workspace(root, manifest, args.zero_edit)
    else:
        inspect(root, manifest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

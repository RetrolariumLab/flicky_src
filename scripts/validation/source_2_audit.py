#!/usr/bin/env python3
"""Audit Flicky's aggregate Source Reconstruction 2.0 contract."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Any


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def git_output(root: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", *arguments], cwd=root, check=True, capture_output=True,
        text=True, encoding="utf-8",
    )
    return result.stdout.strip()


def validate_source_2(root: Path, manifest_path: Path, require_ready: bool = False) -> list[str]:
    release = load_json(manifest_path)
    errors: list[str] = []
    status = release.get("status")
    if release.get("schema_version") != 1:
        errors.append("Source Reconstruction 2.0 manifest is not schema 1")
    if release.get("release_line") != "2.0":
        errors.append("Source Reconstruction release line is not 2.0")
    if status not in {"development", "tag-ready"}:
        errors.append("Source Reconstruction 2.0 status is invalid")
    if require_ready and status != "tag-ready":
        errors.append("Source Reconstruction 2.0 manifest is not tag-ready")

    predecessor = release.get("predecessor", {})
    predecessor_path = root / predecessor.get("manifest", "")
    if not predecessor_path.is_file():
        errors.append("Source Reconstruction 1.0 manifest is missing")
    else:
        source_1 = load_json(predecessor_path)
        if predecessor.get("tag") != source_1.get("tag"):
            errors.append("predecessor tag disagrees with the 1.0 manifest")
        reference = source_1.get("reference", {})
        preservation = release.get("preservation_compatibility", {})
        if preservation.get("canonical_rom_sha1") != reference.get("rom_sha1"):
            errors.append("2.0 canonical ROM SHA-1 differs from Source 1.0")
        if preservation.get("canonical_rom_size") != reference.get("rom_size"):
            errors.append("2.0 canonical ROM size differs from Source 1.0")
    try:
        tag_commit = git_output(root, "rev-list", "-n", "1", predecessor.get("tag", ""))
    except subprocess.CalledProcessError:
        errors.append(f"predecessor tag is missing: {predecessor.get('tag')}")
    else:
        if tag_commit != predecessor.get("commit"):
            errors.append("predecessor tag target differs from the 2.0 contract")
        ancestor = subprocess.run(
            ["git", "merge-base", "--is-ancestor", predecessor.get("commit", ""), "HEAD"],
            cwd=root, check=False, capture_output=True,
        )
        if ancestor.returncode:
            errors.append("Source Reconstruction 1.0 is not an ancestor of HEAD")

    content = release.get("authoring", {})
    studios_path = root / content.get("manifest", "")
    if not studios_path.is_file():
        errors.append("content studio manifest is missing")
    else:
        studios = load_json(studios_path)
        if len(studios.get("studios", [])) != content.get("studio_count"):
            errors.append("content studio count differs from the 2.0 manifest")
        if len(studios.get("artifacts", [])) != content.get("artifact_count"):
            errors.append("content artifact count differs from the 2.0 manifest")
        supported = [item["id"] for item in studios.get("studios", []) if item.get("status") == "supported"]
        if supported != content.get("supported_studios"):
            errors.append("supported studio list differs from the 2.0 manifest")
        known_artifacts = {item["id"] for item in studios.get("artifacts", [])}
        claimed_artifacts = {artifact for studio in studios.get("studios", []) for artifact in studio.get("artifacts", [])}
        if known_artifacts != claimed_artifacts:
            errors.append("content studios do not claim every artifact exactly once")
        preservation = release.get("preservation_compatibility", {})
        if studios.get("image_sha1") != preservation.get("canonical_rom_sha1"):
            errors.append("content manifest pins a different canonical image")

    fidelity = content.get("sound_fidelity", {})
    fidelity_gate = content.get("sound_fidelity_gate")
    if fidelity_gate != "verify-sound-sequencer":
        errors.append("sound fidelity gate is not verify-sound-sequencer")
    if fidelity.get("header") != "zMusic85Header":
        errors.append("sound fidelity header is not the observed title song")
    if fidelity.get("gens_frames") != [320, 457]:
        errors.append("sound fidelity frame window differs from the observed window")
    if fidelity.get("exact_ordered_ym2612_writes", 0) < 2600:
        errors.append("sound fidelity claim covers fewer than 2600 YM2612 writes")
    if fidelity.get("max_timing_error_frames", float("inf")) > 2.1:
        errors.append("sound fidelity timing tolerance exceeds 2.1 frames")
    toolchain_path = root / "config/toolchain.json"
    if toolchain_path.is_file():
        components = {
            item.get("id"): item for item in load_json(toolchain_path).get("components", [])
        }
        emulator_commit = components.get("emulator", {}).get("source_commit")
        if fidelity.get("emulator_commit") != emulator_commit:
            errors.append("sound fidelity emulator commit differs from toolchain pin")

    semantic = release.get("semantic_source", {})
    formats_path = root / semantic.get("format_manifest", "")
    if not formats_path.is_file():
        errors.append("semantic data format manifest is missing")
    else:
        formats = load_json(formats_path)
        counts = {
            kind: sum(item.get("round_trip") == kind for item in formats.get("artifacts", []))
            for kind in ("exact", "semantic", "none")
        }
        expected = {
            "exact": semantic.get("exact_round_trips"),
            "semantic": semantic.get("semantic_round_trips"),
            "none": semantic.get("opaque_extracted_segments"),
        }
        if counts != expected:
            errors.append(f"format strength counts differ: {counts} != {expected}")
    for field in ("z80_driver_source", "z80_sound_data_source"):
        path = root / semantic.get(field, "")
        if not path.is_file():
            errors.append(f"semantic sound source is missing: {field}")
        elif "binclude" in path.read_text(encoding="utf-8").lower():
            errors.append(f"semantic sound source still includes an opaque binary: {field}")

    unknowns = (root / "docs/unknowns.md").read_text(encoding="utf-8")
    for identifier in semantic.get("residual_uncertainty", []):
        if re.search(rf"^### {re.escape(identifier)}\b", unknowns, re.MULTILINE) is None:
            errors.append(f"residual uncertainty is not registered: {identifier}")
    for item in release.get("documented_exclusions", []):
        if not item.get("id") or not item.get("reason"):
            errors.append("2.0 documented exclusion lacks an id or reason")
    conditional = release.get("conditional_scope", {})
    for identifier in ("revisions", "platform_profiles", "experimental_builds"):
        item = conditional.get(identifier, {})
        if item.get("status") != "not_applicable" or not item.get("reason"):
            errors.append(f"conditional scope is not justified: {identifier}")

    for relative in release.get("required_documents", []):
        if not (root / relative).is_file():
            errors.append(f"required 2.0 document is missing: {relative}")
    makefile = (root / "Makefile").read_text(encoding="utf-8")
    for target in release.get("required_targets", []):
        if re.search(rf"^{re.escape(target)}\s*:", makefile, re.MULTILINE) is None:
            errors.append(f"required 2.0 Make target is missing: {target}")
    roadmap = (root / "docs/roadmap.md").read_text(encoding="utf-8")
    expected_status = "Complete" if status == "tag-ready" else "In Progress"
    if re.search(rf"^### 12\. Source Reconstruction 2\.0 - {expected_status}$", roadmap, re.MULTILINE) is None:
        errors.append(f"roadmap Source Reconstruction 2.0 milestone is not {expected_status}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--manifest", type=Path, default=Path("config/source_reconstruction_2_0.json"))
    parser.add_argument("--require-ready", action="store_true")
    args = parser.parse_args()
    root = args.project_root.resolve()
    manifest = args.manifest if args.manifest.is_absolute() else root / args.manifest
    errors = validate_source_2(root, manifest, args.require_ready)
    if errors:
        for error in errors:
            print(f"[ERROR] {error}")
        print(f"[FAIL] Source Reconstruction 2.0 audit found {len(errors)} error(s)")
        return 1
    print("[OK] Source Reconstruction 2.0 preservation, semantic source, studios, and predecessor agree")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

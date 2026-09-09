#!/usr/bin/env python3
"""Audit Flicky against the Source Reconstruction 2.0 release contract."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Any

from validation.make_interface import makefile_recipe, makefile_targets


MANIFEST_SCHEMA_VERSION = 1
RELEASE_STATUSES = {"development", "tag-ready", "tagged"}
REQUIREMENT_STATUSES = {
    "satisfied",
    "not_applicable",
    "partial",
    "unsupported",
    "planned",
}
PUBLIC_TEXT_SUFFIXES = {
    ".asm",
    ".bat",
    ".cfg",
    ".inc",
    ".ini",
    ".json",
    ".lua",
    ".md",
    ".mk",
    ".ps1",
    ".py",
    ".s",
    ".sh",
    ".toml",
    ".txt",
    ".yaml",
    ".yml",
}
PUBLIC_TEXT_NAMES = {"Makefile", ".gitattributes", ".gitignore"}
NON_ENGLISH_SCRIPT = re.compile(
    "["
    "\\u0370-\\u052f"  # Greek, Coptic, and Cyrillic
    "\\u0590-\\u08ff"  # Hebrew and Arabic scripts
    "\\u0900-\\u0fff"  # Indic and Southeast Asian scripts
    "\\u3040-\\u30ff"  # Japanese kana
    "\\u3400-\\u9fff"  # CJK ideographs
    "\\uac00-\\ud7af"  # Hangul
    "]"
)
GENERIC_COMMIT_TITLES = {"fix", "update", "changes", "wip"}
LABEL_RENAME_REGISTRY = Path("config/reconstruction/label_renames.json")
LABEL_PROVENANCE_NARRATIVE = Path("docs/provenance.md")


def load_json(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read JSON document {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise ValueError(f"expected a JSON object in {path}")
    return document


def git_output(root: Path, *arguments: str, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *arguments],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if check and result.returncode:
        raise subprocess.CalledProcessError(
            result.returncode, result.args, result.stdout, result.stderr
        )
    return result.stdout.strip()


def git_lines(root: Path, *arguments: str) -> list[str]:
    output = git_output(root, *arguments)
    return [line for line in output.splitlines() if line]


def is_public_text_path(relative: str) -> bool:
    path = Path(relative)
    return (
        path.name in PUBLIC_TEXT_NAMES
        or path.suffix.lower() in PUBLIC_TEXT_SUFFIXES
    )


def validate_public_language(
    root: Path,
    predecessor: str | None,
    errors: list[str],
) -> None:
    """Reject identifiable non-English scripts in public text changed for 2.0."""
    if not predecessor:
        return
    changed = git_lines(
        root,
        "diff",
        "--name-only",
        "--diff-filter=ACMRT",
        predecessor,
        "--",
    )
    tracked = set(git_lines(root, "ls-files"))
    for relative in changed:
        if relative not in tracked or not is_public_text_path(relative):
            continue
        path = root / relative
        if not path.is_file():
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            errors.append(f"changed public text is not UTF-8: {relative}")
            continue
        lines = {
            text.count("\n", 0, match.start()) + 1
            for match in NON_ENGLISH_SCRIPT.finditer(text)
        }
        if lines:
            errors.append(
                f"changed public text contains a non-English script: {relative} "
                f"lines {sorted(lines)}"
            )


def validate_contract(
    root: Path,
    release: dict[str, Any],
    errors: list[str],
    require_ready: bool,
) -> None:
    if release.get("schema_version") != MANIFEST_SCHEMA_VERSION:
        errors.append(
            f"schema_version is {release.get('schema_version')!r}, "
            f"expected {MANIFEST_SCHEMA_VERSION}"
        )
    if release.get("release_line") != "2.0":
        errors.append("release_line is not 2.0")
    if "contract" in release:
        errors.append("manifest exposes non-project review metadata")

    identity = release.get("release")
    if identity != {"name": "Source Reconstruction 2.0", "version": "2.0"}:
        errors.append("release identity is not Source Reconstruction 2.0")
    if release.get("release_kind") != "baseline":
        errors.append("release_kind is not baseline")
    if release.get("tag") != "source-reconstruction-2.0":
        errors.append("release tag does not follow the contract template")
    publish_remote = release.get("publish_remote")
    if not publish_remote:
        errors.append("publish_remote is not declared")
    elif publish_remote not in set(git_lines(root, "remote")):
        errors.append(f"publish_remote does not exist: {publish_remote}")
    status = release.get("status")
    if status not in RELEASE_STATUSES:
        errors.append(f"invalid release status: {status!r}")
    if require_ready and status != "tag-ready":
        errors.append("Source Reconstruction 2.0 manifest is not tag-ready")


def validate_predecessor(
    root: Path, release: dict[str, Any], errors: list[str]
) -> str | None:
    predecessor = release.get("predecessor")
    if not isinstance(predecessor, dict):
        errors.append("predecessor is missing")
        return None
    for field in ("manifest", "tag", "commit"):
        if not predecessor.get(field):
            errors.append(f"predecessor is missing {field}")
    predecessor_path = root / predecessor.get("manifest", "")
    if not predecessor_path.is_file():
        errors.append("Source Reconstruction 1.0 manifest is missing")
        return predecessor.get("commit")

    source_1 = load_json(predecessor_path)
    if predecessor.get("tag") != source_1.get("tag"):
        errors.append("predecessor tag disagrees with the 1.0 manifest")
    valid_commit = False
    try:
        tag_commit = git_output(
            root, "rev-list", "-n", "1", predecessor.get("tag", "")
        )
    except subprocess.CalledProcessError:
        errors.append(f"predecessor tag is missing: {predecessor.get('tag')}")
    else:
        if tag_commit != predecessor.get("commit"):
            errors.append("predecessor tag target differs from the 2.0 contract")
        else:
            valid_commit = True
        ancestor = subprocess.run(
            [
                "git",
                "merge-base",
                "--is-ancestor",
                predecessor.get("commit", ""),
                "HEAD",
            ],
            cwd=root,
            check=False,
            capture_output=True,
        )
        if ancestor.returncode:
            errors.append("Source Reconstruction 1.0 is not an ancestor of HEAD")

    reference = source_1.get("reference", {})
    preservation = release.get("preservation_compatibility", {})
    if preservation.get("canonical_rom_sha1") != reference.get("rom_sha1"):
        errors.append("2.0 canonical ROM SHA-1 differs from Source 1.0")
    if preservation.get("canonical_rom_size") != reference.get("rom_size"):
        errors.append("2.0 canonical ROM size differs from Source 1.0")
    return predecessor.get("commit") if valid_commit else None


def validate_scope(release: dict[str, Any], errors: list[str]) -> None:
    included = release.get("included_scope")
    if not isinstance(included, list) or not included:
        errors.append("included_scope is empty")
        included = []
    excluded = release.get("excluded_scope")
    if not isinstance(excluded, list) or not excluded:
        errors.append("excluded_scope is empty")
        return
    seen: set[str] = set()
    for item in excluded:
        if not isinstance(item, dict):
            errors.append("excluded_scope entry is not an object")
            continue
        identifier = item.get("id")
        if not identifier:
            errors.append("excluded_scope entry has no id")
            continue
        if identifier in seen:
            errors.append(f"excluded_scope lists {identifier} twice")
        seen.add(identifier)
        if item.get("status") not in REQUIREMENT_STATUSES:
            errors.append(f"excluded_scope {identifier} has invalid status")
        if not item.get("reason"):
            errors.append(f"excluded_scope {identifier} has no reason")
    overlap = set(included) & seen
    if overlap:
        errors.append(f"scope is both included and excluded: {sorted(overlap)}")


def validate_requirements(
    root: Path,
    release: dict[str, Any],
    targets: set[str],
    errors: list[str],
    require_ready: bool,
) -> None:
    requirements = release.get("requirements")
    if not isinstance(requirements, dict) or not requirements:
        errors.append("requirements registry is empty")
        return
    artifact_ids = {
        item.get("id")
        for item in release.get("artifacts", [])
        if isinstance(item, dict)
    }
    for identifier, requirement in requirements.items():
        if not isinstance(requirement, dict):
            errors.append(f"requirement {identifier} is not an object")
            continue
        status = requirement.get("status")
        if status not in REQUIREMENT_STATUSES:
            errors.append(f"requirement {identifier} has invalid status {status!r}")
        evidence = requirement.get("evidence")
        if not isinstance(evidence, dict):
            errors.append(f"requirement {identifier} has no evidence object")
            continue
        if not any(evidence.get(field) for field in evidence):
            errors.append(f"requirement {identifier} names no evidence")
        for target in evidence.get("targets", []):
            if target not in targets:
                errors.append(f"requirement {identifier} names missing target: {target}")
        for field in ("files", "scenarios"):
            for relative in evidence.get(field, []):
                if not (root / relative).exists():
                    errors.append(
                        f"requirement {identifier} names missing {field[:-1]}: {relative}"
                    )
        for artifact in evidence.get("artifacts", []):
            if artifact not in artifact_ids:
                errors.append(
                    f"requirement {identifier} names unknown artifact: {artifact}"
                )
    if require_ready:
        unfinished = [
            identifier
            for identifier, requirement in requirements.items()
            if requirement.get("status") not in {"satisfied", "not_applicable"}
        ]
        if unfinished:
            errors.append(f"tag-ready release has unfinished requirements: {unfinished}")


def validate_profiles(
    root: Path,
    release: dict[str, Any],
    targets: set[str],
    errors: list[str],
) -> None:
    artifacts = {
        item.get("id"): item
        for item in release.get("artifacts", [])
        if isinstance(item, dict) and item.get("id")
    }
    if not artifacts:
        errors.append("release declares no artifacts")
    for identifier, artifact in artifacts.items():
        target = artifact.get("build_target")
        if target not in targets:
            errors.append(f"artifact {identifier} names missing target: {target}")
        if not isinstance(artifact.get("size"), int) or artifact["size"] <= 0:
            errors.append(f"artifact {identifier} has invalid size")
        if not re.fullmatch(r"[0-9a-fA-F]{64}", artifact.get("sha256", "")):
            errors.append(f"artifact {identifier} has invalid SHA-256")

    profiles = release.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        errors.append("release declares no profiles")
        return
    supported = {
        item.get("id"): item
        for item in profiles
        if isinstance(item, dict) and item.get("status") == "supported"
    }
    coverage = {
        item.get("profile_id"): item
        for item in release.get("runtime_coverage", [])
        if isinstance(item, dict)
    }
    for identifier, profile in supported.items():
        if profile.get("identity") != "byte-identical":
            errors.append(f"profile {identifier} is not byte-identical")
        if profile.get("artifact") not in artifacts:
            errors.append(f"profile {identifier} names an unknown artifact")
        layout = profile.get("layout")
        if not layout or not (root / layout).is_file():
            errors.append(f"profile {identifier} names a missing layout")
        row = coverage.get(identifier)
        if row is None:
            errors.append(f"profile {identifier} has no runtime coverage")
            continue
        if row.get("mode") != "direct":
            errors.append(f"profile {identifier} does not have direct runtime coverage")
            continue
        scenario_path = root / row.get("manifest", "")
        if not scenario_path.is_file():
            errors.append(f"profile {identifier} runtime manifest is missing")
            continue
        declared = {
            item.get("id")
            for item in load_json(scenario_path).get("scenarios", [])
            if isinstance(item, dict)
        }
        named = set(row.get("scenarios", []))
        if not named or not named.issubset(declared):
            errors.append(f"profile {identifier} runtime scenarios do not resolve")


def validate_toolchain(
    root: Path, release: dict[str, Any], errors: list[str]
) -> None:
    block = release.get("toolchain")
    if not isinstance(block, dict):
        errors.append("toolchain contract is missing")
        return
    path = root / block.get("manifest", "")
    if not path.is_file():
        errors.append("toolchain manifest is missing")
        return
    document = load_json(path)
    components = document.get("components", [])
    if not components:
        errors.append("toolchain manifest has no components")
    for component in components:
        for field in ("id", "name", "version", "source", "provenance", "verification"):
            if not component.get(field):
                errors.append(
                    f"toolchain component {component.get('id', '<unknown>')} lacks {field}"
                )
        if component.get("id") in {"assembler", "binary_converter"} and not any(
            component.get(field)
            for field in ("source_release", "source_commit", "source_archive_sha256")
        ):
            errors.append(
                f"toolchain component {component.get('id')} has no exact source revision"
            )
        if component.get("id") == "binary_converter":
            if not re.fullmatch(
                r"[0-9a-f]{40}", component.get("source_commit") or ""
            ):
                errors.append("binary converter source commit is not exact")
            if component.get("identity") != "source_commit_and_binary_hash":
                errors.append(
                    "binary converter identity does not require source commit and binary hash"
                )
            binary_provenance = component.get("binary_provenance", {})
            for platform in component.get("files", {}):
                origin = binary_provenance.get(platform, {})
                if not origin.get("origin") or not origin.get("origin_commit"):
                    errors.append(
                        f"binary converter {platform} has no exact binary origin"
                    )
                elif not re.fullmatch(r"[0-9a-f]{40}", origin["origin_commit"]):
                    errors.append(
                        f"binary converter {platform} origin commit is not exact"
                    )
    emulator = next(
        (component for component in components if component.get("id") == "emulator"),
        None,
    )
    if emulator is None:
        errors.append("toolchain manifest has no emulator component")
    else:
        if emulator.get("identity") != "source_commit_and_binary_hash":
            errors.append("emulator identity does not require commit and binary hash")
        emulator_files = [
            entry
            for entries in emulator.get("files", {}).values()
            for entry in entries
        ]
        if not emulator_files:
            errors.append("emulator has no approved executable")
        for entry in emulator_files:
            if entry.get("observed_only"):
                errors.append("emulator executable hash is observational only")
    if not any(
        host.get("supported_status") == "supported"
        for host in document.get("hosts", [])
        if isinstance(host, dict)
    ):
        errors.append("toolchain declares no supported host")


def validate_make_contract(
    root: Path,
    release: dict[str, Any],
    targets: set[str],
    errors: list[str],
) -> None:
    for target in release.get("release_commands", []):
        if target not in targets:
            errors.append(f"release command names missing target: {target}")
    gates = release.get("aggregate_gates")
    if not isinstance(gates, dict):
        errors.append("aggregate_gates are missing")
    else:
        for phase in ("pre_tag", "post_tag"):
            commands = gates.get(phase)
            if not isinstance(commands, list) or not commands:
                errors.append(f"aggregate_gates {phase} is empty")
                continue
            for command in commands:
                parts = command.split()
                if len(parts) != 2 or parts[0] != "make" or parts[1] not in targets:
                    errors.append(f"aggregate_gates {phase} has invalid command: {command}")

    recipe = makefile_recipe("source-2-check", root)
    make_calls = [
        match.group(1)
        for line in recipe
        if (match := re.search(r"\$\(MAKE\)\s+([\w.-]+)", line))
    ]
    if not make_calls or make_calls[0] != "release-check":
        errors.append("source-2-check does not begin with the complete 1.0 gate")


def validate_documents_and_provenance(
    root: Path, release: dict[str, Any], errors: list[str]
) -> None:
    for relative in release.get("required_documents", []):
        if not (root / relative).is_file():
            errors.append(f"required 2.0 document is missing: {relative}")
    for deviation in release.get("layout_deviations", []):
        if not all(
            deviation.get(field)
            for field in ("rule_id", "actual_path", "reason", "equivalent_control")
        ):
            errors.append("layout deviation is incomplete")
        elif not (root / deviation["actual_path"]).exists():
            errors.append(
                f"layout deviation path is missing: {deviation['actual_path']}"
            )
    licensing = release.get("licensing")
    if not isinstance(licensing, list) or not licensing:
        errors.append("licensing registry is empty")
    else:
        for item in licensing:
            for field in (
                "component",
                "category",
                "origin",
                "license_id_or_status",
                "redistribution",
                "notes",
            ):
                if not item.get(field):
                    errors.append(
                        f"licensing entry {item.get('component', '<unknown>')} lacks {field}"
                    )
    provenance = release.get("provenance")
    if not isinstance(provenance, dict):
        errors.append("provenance contract is missing")
    else:
        if provenance.get("private_inputs_tracked") is not False:
            errors.append("provenance does not reject tracked private inputs")
        for relative in provenance.get("references", []):
            if not (root / relative).exists():
                errors.append(f"provenance reference is missing: {relative}")


def validate_label_rename_registry(
    root: Path, release: dict[str, Any], errors: list[str]
) -> None:
    """Require one canonical, machine-readable label provenance registry."""
    canonical = LABEL_RENAME_REGISTRY.as_posix()
    tracked_json = git_lines(root, "ls-files", "*.json")
    named_registries = [
        relative
        for relative in tracked_json
        if Path(relative).name == "label_renames.json"
    ]
    shaped_registries: list[str] = []
    for relative in tracked_json:
        try:
            document = load_json(root / relative)
        except ValueError:
            continue
        if "rename_columns" in document and "renames" in document:
            shaped_registries.append(relative)
    if named_registries != [canonical] or shaped_registries != [canonical]:
        found = sorted(set(named_registries + shaped_registries))
        errors.append(
            "label rename registry is not unique at "
            f"{canonical}: {found or ['none']}"
        )
        return

    table = load_json(root / canonical)
    if table.get("schema_version") != 1:
        errors.append("label rename registry schema_version is not 1")
    if table.get("rename_columns") != ["original", "current", "current_path"]:
        errors.append("label rename registry columns are invalid")
    if table.get("addition_columns") != ["current", "current_path"]:
        errors.append("label addition registry columns are invalid")
    renames = table.get("renames")
    additions = table.get("project_additions")
    counts = table.get("counts", {})
    if not isinstance(renames, list) or counts.get("renames") != len(renames):
        errors.append("label rename registry count is stale")
    if (
        not isinstance(additions, list)
        or counts.get("project_additions") != len(additions)
    ):
        errors.append("label addition registry count is stale")

    required = release.get("required_documents", [])
    references = release.get("provenance", {}).get("references", [])
    if required.count(canonical) != 1:
        errors.append("required documents do not name the canonical label registry once")
    if references.count(canonical) != 1:
        errors.append("provenance does not name the canonical label registry once")
    narrative = root / LABEL_PROVENANCE_NARRATIVE
    if not narrative.is_file():
        errors.append("top-level label provenance narrative is missing")
    elif "../config/reconstruction/label_renames.json" not in narrative.read_text(
        encoding="utf-8"
    ):
        errors.append("label provenance narrative does not link the canonical registry")

    tracked = git_lines(root, "ls-files")
    obsolete = [
        relative
        for relative in tracked
        if relative.startswith(("docs/adr/", "docs/provenance/"))
    ]
    if obsolete:
        errors.append(f"retired documentation directories remain tracked: {obsolete}")


def validate_project_claims(
    root: Path, release: dict[str, Any], errors: list[str]
) -> None:
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
        supported = [
            item["id"]
            for item in studios.get("studios", [])
            if item.get("status") == "supported"
        ]
        if supported != content.get("supported_studios"):
            errors.append("supported studio list differs from the 2.0 manifest")
        known = {item["id"] for item in studios.get("artifacts", [])}
        claimed = {
            artifact
            for studio in studios.get("studios", [])
            for artifact in studio.get("artifacts", [])
        }
        if known != claimed:
            errors.append("content studios do not claim every artifact exactly once")
        if content.get("workstation_gate") != studios.get("workstation_smoke"):
            errors.append("workstation Studio gate differs from its manifest")

    fidelity = content.get("sound_fidelity", {})
    if content.get("sound_fidelity_gate") != "verify-sound-sequencer":
        errors.append("sound fidelity gate is not verify-sound-sequencer")
    if fidelity.get("header") != "zMusic85Header":
        errors.append("sound fidelity header is not the observed title song")
    if fidelity.get("gens_frames") != [320, 457]:
        errors.append("sound fidelity frame window differs from the observed window")
    if fidelity.get("exact_ordered_chip_writes", 0) < 2600:
        errors.append("sound fidelity claim covers fewer than 2600 chip writes")
    if fidelity.get("max_timing_error_frames", float("inf")) > 2.1:
        errors.append("sound fidelity timing tolerance exceeds 2.1 frames")
    toolchain_path = root / release.get("toolchain", {}).get("manifest", "")
    if toolchain_path.is_file():
        components = {
            item.get("id"): item
            for item in load_json(toolchain_path).get("components", [])
        }
        if fidelity.get("emulator_commit") != components.get("emulator", {}).get(
            "source_commit"
        ):
            errors.append("sound fidelity emulator commit differs from toolchain pin")
        emulator_files = components.get("emulator", {}).get("files", {}).get("any", [])
        approved_hashes = {entry.get("sha256") for entry in emulator_files}
        if fidelity.get("emulator_sha256") not in approved_hashes:
            errors.append("sound fidelity emulator hash differs from toolchain pin")

    semantic = release.get("semantic_source", {})
    formats_path = root / semantic.get("format_manifest", "")
    if not formats_path.is_file():
        errors.append("semantic data format manifest is missing")
    else:
        formats = load_json(formats_path)
        counts = {
            kind: sum(
                item.get("round_trip") == kind
                for item in formats.get("artifacts", [])
            )
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
            errors.append(f"semantic sound source includes an opaque binary: {field}")

    unknowns_path = root / "docs/unknowns.md"
    if unknowns_path.is_file():
        unknowns = unknowns_path.read_text(encoding="utf-8")
        for identifier in semantic.get("residual_uncertainty", []):
            if re.search(
                rf"^### {re.escape(identifier)}\b", unknowns, re.MULTILINE
            ) is None:
                errors.append(
                    f"residual uncertainty is not registered: {identifier}"
                )

    roadmap_path = root / "docs/roadmap.md"
    if roadmap_path.is_file():
        roadmap = roadmap_path.read_text(encoding="utf-8")
        expected = "Complete" if release.get("status") in {"tag-ready", "tagged"} else "In Progress"
        if re.search(
            rf"^### 12\. Source Reconstruction 2\.0 - {expected}$",
            roadmap,
            re.MULTILINE,
        ) is None:
            errors.append(f"roadmap Source Reconstruction 2.0 milestone is not {expected}")


def validate_history(
    root: Path,
    release: dict[str, Any],
    predecessor: str | None,
    errors: list[str],
    pre_tag: bool,
) -> None:
    if not predecessor:
        return
    commits = git_lines(root, "rev-list", "--reverse", f"{predecessor}..HEAD")
    commit_set = set(commits)

    for commit in commits:
        fields = git_output(root, "rev-list", "--parents", "-n", "1", commit).split()
        tree = git_output(root, "rev-parse", f"{commit}^{{tree}}")
        parent_trees = [
            git_output(root, "rev-parse", f"{parent}^{{tree}}")
            for parent in fields[1:]
        ]
        if parent_trees and all(tree == parent_tree for parent_tree in parent_trees):
            errors.append(f"empty commit after predecessor: {commit}")

    targets = makefile_targets(root)
    covered: set[str] = set()
    has_pending = False
    for entry in release.get("delta", []):
        if not all(entry.get(field) for field in ("id", "kind", "summary", "evidence")):
            errors.append(f"delta entry is incomplete: {entry.get('id', '<unknown>')}")
        for evidence in entry.get("evidence", []):
            if evidence not in targets and not (root / evidence).exists():
                errors.append(
                    f"delta {entry.get('id')} names missing evidence: {evidence}"
                )
        for reference in entry.get("commits", []):
            if reference == "pending":
                has_pending = True
                continue
            if reference == "release-commit":
                covered.add(git_output(root, "rev-parse", "HEAD"))
                continue
            try:
                resolved = git_output(root, "rev-parse", f"{reference}^{{commit}}")
            except subprocess.CalledProcessError:
                errors.append(
                    f"delta {entry.get('id')} names unreachable commit: {reference}"
                )
                continue
            if resolved not in commit_set:
                errors.append(
                    f"delta {entry.get('id')} names commit outside predecessor range: {reference}"
                )
            covered.add(resolved)
    missing = commit_set - covered
    if missing:
        errors.append(f"delta does not cover commits: {sorted(missing)}")
    if pre_tag and has_pending:
        errors.append("tag-ready delta still contains pending commits")

    history = release.get("delta_history")
    if not isinstance(history, dict):
        errors.append("delta_history is missing")
    elif history.get("base_commit") != predecessor:
        errors.append("delta_history base differs from predecessor")
    elif pre_tag:
        if history.get("tip") not in {"release-commit", git_output(root, "rev-parse", "HEAD")}:
            errors.append("tag-ready delta_history tip is not the release commit")
        if history.get("commit_count") != len(commits):
            errors.append("tag-ready delta_history commit count is stale")

    if not pre_tag:
        return
    previous_author_time: int | None = None
    previous_commit_time: int | None = None
    for commit in commits:
        parents = git_output(root, "rev-list", "--parents", "-n", "1", commit).split()
        if len(parents) > 2:
            continue
        author_time = int(git_output(root, "show", "-s", "--format=%at", commit))
        commit_time = int(git_output(root, "show", "-s", "--format=%ct", commit))
        if previous_author_time is not None and author_time < previous_author_time:
            errors.append(f"author dates are not monotonic at commit: {commit}")
        if previous_commit_time is not None and commit_time < previous_commit_time:
            errors.append(f"commit dates are not monotonic at commit: {commit}")
        previous_author_time = author_time
        previous_commit_time = commit_time
        message = git_output(root, "show", "-s", "--format=%B", commit)
        paragraphs = [
            paragraph.strip()
            for paragraph in re.split(r"\n\s*\n", message.strip())
            if paragraph.strip()
        ]
        title = paragraphs[0] if paragraphs else ""
        body = [
            paragraph
            for paragraph in paragraphs[1:]
            if not all(
                line.startswith(("Co-Authored-By:", "Claude-Session:"))
                for line in paragraph.splitlines()
            )
        ]
        if NON_ENGLISH_SCRIPT.search(message):
            errors.append(f"commit message contains a non-English script: {commit}")
        if title.endswith(".") or title.lower() in GENERIC_COMMIT_TITLES:
            errors.append(f"commit title is not concrete: {commit}")
        if len(body) not in {2, 3}:
            errors.append(
                f"commit must have two or three body paragraphs: {commit}"
            )


def validate_tag_state(
    root: Path,
    release: dict[str, Any],
    errors: list[str],
    pre_tag: bool,
    require_tag: bool,
) -> None:
    tag = release.get("tag", "")
    local_tags = set(git_lines(root, "tag", "--list", tag))
    if pre_tag:
        if local_tags:
            errors.append(f"future release tag already exists: {tag}")
        if git_output(root, "status", "--porcelain"):
            errors.append("pre-tag worktree is not clean")
        remote = release.get("publish_remote", "")
        if remote:
            published = git_output(
                root, "ls-remote", "--tags", remote, f"refs/tags/{tag}"
            )
            if published:
                errors.append(f"future release tag already exists on {remote}: {tag}")
    if require_tag:
        if tag not in local_tags:
            errors.append(f"release tag is missing: {tag}")
            return
        if git_output(root, "cat-file", "-t", tag) != "tag":
            errors.append(f"release tag is not annotated: {tag}")
        peeled = git_output(root, "rev-list", "-n", "1", tag)
        head = git_output(root, "rev-parse", "HEAD")
        if peeled != head:
            errors.append("release tag does not point at HEAD")
        remote = release.get("publish_remote", "")
        if remote:
            published = git_output(
                root, "ls-remote", "--tags", remote, f"refs/tags/{tag}^{{}}"
            )
            if published and published.split()[0] != head:
                errors.append(f"published tag on {remote} does not point at HEAD")


def validate_source_2(
    root: Path,
    manifest_path: Path,
    require_ready: bool = False,
    pre_tag: bool = False,
    require_tag: bool = False,
) -> list[str]:
    release = load_json(manifest_path)
    errors: list[str] = []
    ready_check = require_ready or pre_tag or require_tag
    targets = makefile_targets(root)

    validate_contract(root, release, errors, ready_check)
    predecessor = validate_predecessor(root, release, errors)
    validate_public_language(root, predecessor, errors)
    validate_scope(release, errors)
    validate_requirements(root, release, targets, errors, ready_check)
    validate_profiles(root, release, targets, errors)
    validate_toolchain(root, release, errors)
    validate_make_contract(root, release, targets, errors)
    validate_documents_and_provenance(root, release, errors)
    validate_label_rename_registry(root, release, errors)
    validate_project_claims(root, release, errors)
    validate_history(root, release, predecessor, errors, pre_tag or require_tag)
    validate_tag_state(root, release, errors, pre_tag, require_tag)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--project-root", type=Path, default=Path(__file__).resolve().parents[2]
    )
    parser.add_argument(
        "--manifest", type=Path, default=Path("config/source_reconstruction_2_0.json")
    )
    parser.add_argument("--require-ready", action="store_true")
    parser.add_argument("--pre-tag", action="store_true")
    parser.add_argument("--require-tag", action="store_true")
    args = parser.parse_args()
    root = args.project_root.resolve()
    manifest = args.manifest if args.manifest.is_absolute() else root / args.manifest
    try:
        errors = validate_source_2(
            root,
            manifest,
            require_ready=args.require_ready,
            pre_tag=args.pre_tag,
            require_tag=args.require_tag,
        )
    except (ValueError, subprocess.CalledProcessError) as exc:
        errors = [str(exc)]
    if errors:
        for error in errors:
            print(f"[ERROR] {error}")
        print(f"[FAIL] Source Reconstruction 2.0 audit found {len(errors)} error(s)")
        return 1
    release = load_json(manifest)
    print(
        "[OK] Source Reconstruction 2.0 "
        f"({release['status']}), public manifest schema "
        f"v{release['schema_version']}"
    )
    print(
        f"[OK] {len(release['requirements'])} requirements, "
        f"{len(release['profiles'])} profile, {len(release['delta'])} delta groups"
    )
    print("[OK] preservation, authoring, runtime, provenance, Make, and history agree")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

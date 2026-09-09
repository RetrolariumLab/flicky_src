#!/usr/bin/env python3
"""Audit the repository against the Source Reconstruction 1.0 release contract.

The manifest is only worth having if something checks it against reality, so
this does not stop at "the field is present". Every document, Make target and
file a requirement cites has to exist; every accepted profile has to have an
artifact and runtime coverage; the scenarios the coverage names have to be the
ones the scenario manifest declares; and the whole reachable git history is
searched for ROM-derived payloads, not just the working tree.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from validation.make_interface import makefile_targets, makefile_text

MILESTONE_RE = re.compile(r"^###\s+(\d+)\.\s+.*?-\s+(\w[\w ]*)$", re.MULTILINE)

MANIFEST_SCHEMA_VERSION = 1
REQUIREMENT_STATUSES = {"satisfied", "not_applicable", "partial", "unsupported", "planned"}
RELEASE_STATUSES = {"development", "tag-ready", "tagged"}
RELEASE_KINDS = {"preservation", "baseline", "compatible_minor", "advanced"}
SCOPE_STATUSES = REQUIREMENT_STATUSES


def load(path: Path) -> dict:
    if not path.is_file():
        raise SystemExit(f"[ERROR] missing {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def git_output(args: list[str]) -> list[str]:
    result = subprocess.run(["git", *args], capture_output=True, text=True, check=False)
    return [line for line in result.stdout.splitlines() if line]


def check_release_header(contract: dict, errors: list[str]) -> None:
    """Validate the public, project-owned manifest header."""
    if contract.get("schema_version") != MANIFEST_SCHEMA_VERSION:
        errors.append(
            f"schema_version is {contract.get('schema_version')!r}, "
            f"expected {MANIFEST_SCHEMA_VERSION}"
        )
    release = contract.get("release", {})
    version = release.get("version")
    if contract.get("release_line") != version:
        errors.append(
            f"release_line {contract.get('release_line')!r} does not match "
            f"release.version {version!r}"
        )
    expected_tag = f"source-reconstruction-{version}"
    if contract.get("tag") != expected_tag:
        errors.append(f"tag is {contract.get('tag')!r}, the template gives {expected_tag!r}")
    if contract.get("status") not in RELEASE_STATUSES:
        errors.append(f"status {contract.get('status')!r} is not one of {sorted(RELEASE_STATUSES)}")
    if contract.get("release_kind") not in RELEASE_KINDS:
        errors.append(
            f"release_kind {contract.get('release_kind')!r} is not one of {sorted(RELEASE_KINDS)}"
        )

    if "predecessor" not in contract:
        errors.append("manifest does not record a predecessor (use null for a first release)")
    elif contract["predecessor"] is not None:
        predecessor = contract["predecessor"]
        for field in ("manifest", "tag", "commit"):
            if not predecessor.get(field):
                errors.append(f"predecessor is missing {field}")


def check_scope(contract: dict, errors: list[str]) -> None:
    if not contract.get("included_scope"):
        errors.append("included_scope is empty; a release has to say what it accepts")
    seen = set()
    for entry in contract.get("excluded_scope", []):
        identifier = entry.get("id")
        if not identifier:
            errors.append("an excluded_scope entry has no id")
            continue
        if identifier in seen:
            errors.append(f"excluded_scope lists {identifier} twice")
        seen.add(identifier)
        if entry.get("status") not in SCOPE_STATUSES:
            errors.append(f"excluded_scope {identifier}: status {entry.get('status')!r} is invalid")
        if not entry.get("reason"):
            errors.append(f"excluded_scope {identifier} has no reason")
    overlap = set(contract.get("included_scope", [])) & seen
    if overlap:
        errors.append(f"scope entries are both included and excluded: {sorted(overlap)}")


def check_delta(contract: dict, errors: list[str]) -> None:
    delta = contract.get("delta")
    if not delta:
        errors.append("delta is empty; it has to describe the whole range after the predecessor")
        return
    known = set(git_output(["rev-list", "--all"]))
    short = {commit[:7] for commit in known}
    for entry in delta:
        if not entry.get("id") or not entry.get("summary"):
            errors.append(f"delta entry {entry.get('id', '<no id>')} is incomplete")
        for commit in entry.get("commits", []):
            if commit == "release-commit":
                # The manifest ships inside the release commit, so that commit's
                # own hash cannot appear in it. This token says so explicitly
                # instead of leaving a hash that would have to be wrong.
                continue
            if commit == "pending":
                # Fine while the work is still being written; a tag-ready
                # manifest has to have resolved it one way or the other.
                if contract.get("status") in {"tag-ready", "tagged"}:
                    errors.append(
                        f"delta {entry.get('id')} still says 'pending' while the "
                        f"release is {contract['status']}"
                    )
                continue
            if commit not in known and commit[:7] not in short:
                errors.append(
                    f"delta {entry.get('id')} cites commit {commit}, "
                    "which is not reachable in this repository"
                )


def check_requirements(contract: dict, errors: list[str]) -> int:
    requirements = contract.get("requirements")
    if not requirements:
        errors.append("manifest has no requirements block")
        return 0

    targets = makefile_targets()
    for identifier, entry in sorted(requirements.items()):
        status = entry.get("status")
        if status not in REQUIREMENT_STATUSES:
            errors.append(f"requirement {identifier}: status {status!r} is invalid")
        if status == "not_applicable" and not entry.get("reason"):
            errors.append(f"requirement {identifier}: not_applicable needs a reason")

        evidence = entry.get("evidence")
        if not evidence:
            errors.append(f"requirement {identifier}: no evidence")
            continue
        if not any(evidence.get(key) for key in ("targets", "files", "scenarios", "artifacts", "note")):
            errors.append(f"requirement {identifier}: evidence names nothing concrete")

        for target in evidence.get("targets", []):
            if target not in targets:
                errors.append(f"requirement {identifier}: Makefile has no target '{target}'")
        for relative in evidence.get("files", []):
            path = Path(relative)
            if not (path.is_file() or path.is_dir()):
                errors.append(f"requirement {identifier}: cites a missing path {relative}")
        for relative in evidence.get("scenarios", []):
            if not Path(relative).is_file():
                errors.append(f"requirement {identifier}: cites a missing scenario file {relative}")
    return len(requirements)


def check_profiles_and_artifacts(contract: dict, errors: list[str]) -> None:
    artifacts = {entry["id"]: entry for entry in contract.get("artifacts", [])}
    if not artifacts:
        errors.append("manifest declares no artifacts")

    reference = contract["reference"]
    for entry in contract.get("artifacts", []):
        if entry.get("size") != reference["rom_size"]:
            errors.append(f"artifact {entry['id']}: size disagrees with the reference ROM")
        if entry.get("sha1", "").lower() != reference["rom_sha1"].lower():
            errors.append(f"artifact {entry['id']}: sha1 disagrees with the reference ROM")
        target = entry.get("build_target")
        if target and target not in makefile_targets():
            errors.append(f"artifact {entry['id']}: build_target '{target}' is not a Make target")

    profiles = contract.get("profiles", [])
    if not profiles:
        errors.append("manifest declares no profiles")
    coverage = {row["profile_id"]: row for row in contract.get("runtime_coverage", [])}

    for profile in profiles:
        identifier = profile.get("id")
        if profile.get("status") == "supported" and profile.get("identity") != "byte-identical":
            errors.append(f"profile {identifier}: supported but identity is not byte-identical")
        if profile.get("artifact") not in artifacts:
            errors.append(f"profile {identifier}: names an artifact that is not declared")
        if profile.get("status") != "supported":
            continue
        row = coverage.get(identifier)
        if row is None:
            errors.append(f"profile {identifier}: accepted but has no runtime coverage")
            continue
        if row.get("mode") == "direct":
            if not row.get("scenarios"):
                errors.append(f"profile {identifier}: direct coverage lists no scenarios")
        elif row.get("mode") == "runtime_equivalent_to":
            for field in ("equivalent_to", "equivalence_scope", "evidence"):
                if not row.get(field):
                    errors.append(f"profile {identifier}: equivalence record is missing {field}")
        else:
            errors.append(f"profile {identifier}: coverage mode {row.get('mode')!r} is invalid")


def check_runtime_coverage(contract: dict, errors: list[str]) -> None:
    """The scenarios the coverage names must be the ones actually declared."""
    for row in contract.get("runtime_coverage", []):
        manifest = row.get("manifest")
        if not manifest:
            continue
        path = Path(manifest)
        if not path.is_file():
            errors.append(f"runtime coverage cites a missing manifest {manifest}")
            continue
        declared = {entry["id"] for entry in load(path)["scenarios"]}
        named = set(row.get("scenarios", []))
        for missing in sorted(named - declared):
            errors.append(f"runtime coverage names scenario '{missing}', which {manifest} lacks")
        for uncovered in sorted(declared - named):
            errors.append(f"{manifest} declares scenario '{uncovered}', which no profile covers")


def check_toolchain(contract: dict, errors: list[str]) -> None:
    block = contract.get("toolchain", {})
    manifest = block.get("manifest")
    if not manifest or not Path(manifest).is_file():
        errors.append("toolchain.manifest does not name an existing file")
        return
    verification = block.get("verification")
    if not verification:
        errors.append("toolchain has no verification command")

    toolchain = load(Path(manifest))
    if not toolchain.get("components"):
        errors.append(f"{manifest} declares no components")
    for component in toolchain.get("components", []):
        identifier = component.get("id", "<no id>")
        for field in ("version", "source", "provenance", "verification"):
            if not component.get(field):
                errors.append(f"toolchain {identifier}: missing {field}")
        if identifier in {"assembler", "binary_converter"} and not any(
            component.get(field)
            for field in ("source_release", "source_commit", "source_archive_sha256")
        ):
            errors.append(f"toolchain {identifier}: no exact source revision pinned")
        if identifier == "binary_converter":
            if not re.fullmatch(
                r"[0-9a-f]{40}", component.get("source_commit") or ""
            ):
                errors.append("toolchain binary_converter: source commit is not exact")
            if component.get("identity") != "source_commit_and_binary_hash":
                errors.append(
                    "toolchain binary_converter: identity does not require source "
                    "commit and binary hash"
                )
            binary_provenance = component.get("binary_provenance", {})
            for platform in component.get("files", {}):
                origin = binary_provenance.get(platform, {})
                if not origin.get("origin") or not origin.get("origin_commit"):
                    errors.append(
                        f"toolchain binary_converter: {platform} has no exact binary origin"
                    )
                elif not re.fullmatch(r"[0-9a-f]{40}", origin["origin_commit"]):
                    errors.append(
                        f"toolchain binary_converter: {platform} origin commit is not exact"
                    )
        if component.get("provenance") == "source-built" and not component.get("source_commit"):
            errors.append(f"toolchain {identifier}: source-built but no source_commit pinned")
        files = component.get("files", {})
        if not files:
            errors.append(f"toolchain {identifier}: no files recorded")
        for entries in files.values():
            for entry in entries:
                if not entry.get("sha256"):
                    errors.append(f"toolchain {identifier}: {entry.get('path')} has no sha256")

    if not toolchain.get("hosts"):
        errors.append(f"{manifest} declares no supported host environment")
    for host in toolchain.get("hosts", []):
        for field in ("os", "architecture", "shell", "supported_status"):
            if not host.get(field):
                errors.append(f"toolchain host {host.get('os', '<no os>')}: missing {field}")


def check_licensing(contract: dict, errors: list[str]) -> None:
    allowed = {
        "licensed", "license_not_granted", "private_user_supplied",
        "external_unbundled", "unknown",
    }
    entries = contract.get("licensing", [])
    if not entries:
        errors.append("manifest has no licensing block")
    categories = {entry.get("category") for entry in entries}
    for required in ("reconstructed_game_source", "private_user_supplied"):
        if required not in categories:
            errors.append(f"licensing does not classify {required}")
    for entry in entries:
        name = entry.get("component", "<no component>")
        if entry.get("license_id_or_status") not in allowed:
            errors.append(
                f"licensing {name}: status {entry.get('license_id_or_status')!r} is invalid"
            )
        for field in ("origin", "redistribution"):
            if not entry.get(field):
                errors.append(f"licensing {name}: missing {field}")

    provenance = contract.get("provenance", {})
    if provenance.get("private_inputs_tracked") is not False:
        errors.append("provenance must state that private inputs are not tracked")
    for relative in provenance.get("references", []):
        if not Path(relative).is_file():
            errors.append(f"provenance cites a missing reference {relative}")


def check_layout_deviations(contract: dict, errors: list[str]) -> None:
    for entry in contract.get("layout_deviations", []):
        for field in ("rule_id", "actual_path", "reason", "equivalent_control"):
            if not entry.get(field):
                errors.append(
                    f"layout deviation {entry.get('rule_id', '<no rule>')}: missing {field}"
                )


def check_aggregate_gates(contract: dict, errors: list[str]) -> None:
    gates = contract.get("aggregate_gates", {})
    for phase in ("pre_tag", "post_tag"):
        commands = gates.get(phase)
        if not commands:
            errors.append(f"aggregate_gates has no {phase} command")
            continue
        targets = makefile_targets()
        for command in commands:
            target = command.split()[-1]
            if target not in targets:
                errors.append(f"aggregate_gates {phase}: '{command}' names no Make target")


def check_manifests(contract: dict, errors: list[str]) -> None:
    """The release contract, the asset manifest and the scenarios must agree."""
    reference = contract["reference"]

    assets = load(Path("assets/manifest.json"))
    rom = assets["reference_rom"]
    for field, key in (("sha1", "rom_sha1"), ("md5", "rom_md5"), ("crc32", "rom_crc32")):
        if rom[field] != reference[key]:
            errors.append(f"assets/manifest.json {field} disagrees with the release contract")
    if rom["size"] != reference["rom_size"]:
        errors.append("assets/manifest.json size disagrees with the release contract")
    if len(assets["assets"]) != contract["evidence"]["extracted_segments"]:
        errors.append(
            f"assets/manifest.json lists {len(assets['assets'])} segments, "
            f"contract says {contract['evidence']['extracted_segments']}"
        )

    scenarios = load(Path("scenarios/runtime_scenarios.json"))
    if scenarios["rom_sha1"] != reference["rom_sha1"]:
        errors.append("scenarios/runtime_scenarios.json pins a different ROM")
    if len(scenarios["scenarios"]) != contract["evidence"]["runtime_scenarios"]:
        errors.append(
            f"scenarios declare {len(scenarios['scenarios'])}, "
            f"contract says {contract['evidence']['runtime_scenarios']}"
        )

    formats = load(Path("config/authoring/data_formats.json"))
    exact = sum(1 for a in formats["artifacts"] if a["round_trip"] == "exact")
    semantic = sum(1 for a in formats["artifacts"] if a["round_trip"] == "semantic")
    # The 1.0 contract records the minimum evidence shipped at that milestone.
    # Later source releases may strengthen a codec without rewriting history.
    if exact < contract["evidence"]["exact_round_trips"]:
        errors.append(f"{exact} exact round trips declared, contract requires at least "
                      f"{contract['evidence']['exact_round_trips']}")
    required_understood = (
        contract["evidence"]["exact_round_trips"]
        + contract["evidence"]["semantic_round_trips"]
    )
    if exact + semantic < required_understood:
        errors.append(
            f"{exact + semantic} exact or semantic round trips declared, "
            f"contract requires at least {required_understood}"
        )
    if len(formats["artifacts"]) != contract["evidence"]["extracted_segments"]:
        errors.append("config/authoring/data_formats.json does not cover every extracted segment")

    layout = load(Path("config/linker/rom_layout.json"))
    if layout["rom_image"]["size"] != reference["rom_size"]:
        errors.append("config/linker/rom_layout.json size disagrees with the release contract")
    if layout["rom_image"]["padding_byte"].lower() != reference["padding_byte"].lower():
        errors.append("config/linker/rom_layout.json padding byte disagrees with the release contract")
    if len(layout["modules"]) != contract["evidence"]["modules"]:
        errors.append(
            f"config/linker/rom_layout.json declares {len(layout['modules'])} modules, "
            f"contract says {contract['evidence']['modules']}"
        )


def check_milestones(contract: dict, errors: list[str]) -> None:
    roadmap = Path("docs/roadmap.md")
    if not roadmap.is_file():
        errors.append("docs/roadmap.md is missing")
        return
    statuses = {int(n): status.strip() for n, status in MILESTONE_RE.findall(
        roadmap.read_text(encoding="utf-8"))}
    for number in contract["complete_milestones"]:
        if statuses.get(number) != "Complete":
            errors.append(
                f"milestone {number} is '{statuses.get(number)}' in the roadmap, "
                "contract claims Complete"
            )
    for number in contract["open_milestones"]:
        status = statuses.get(int(number))
        if status == "Complete":
            errors.append(
                f"milestone {number} is marked Complete but the contract records it as open"
            )


def check_documents(contract: dict, errors: list[str]) -> None:
    for relative in contract["required_documents"]:
        if not Path(relative).is_file():
            errors.append(f"required document missing: {relative}")


def check_make_targets(contract: dict, errors: list[str]) -> None:
    targets = makefile_targets()
    for target in contract["release_commands"]:
        if target not in targets:
            errors.append(f"Makefile has no target '{target}'")

    gate = re.search(
        r"^release-check:\n((?:\t.*\n)+)", makefile_text(), re.MULTILINE
    )
    if not gate:
        errors.append("Makefile has no release-check recipe")
        return
    ordered = re.findall(r"\$\(MAKE\)\s+([\w.-]+)", gate.group(1))
    if ordered != contract["release_commands"]:
        errors.append(
            "release-check runs a different sequence than the contract declares:\n"
            f"        Makefile: {ordered}\n"
            f"        contract: {contract['release_commands']}"
        )


def check_tracked_payloads(contract: dict, errors: list[str]) -> None:
    """No ROM-derived payload, in the working tree or anywhere in history."""
    suffixes = tuple(contract["prohibited_tracked_extensions"])
    prefixes = tuple(contract["prohibited_tracked_prefixes"])

    def offending(paths: list[str]) -> list[str]:
        return [
            path for path in paths
            if path.endswith(suffixes) or path.startswith(prefixes)
        ]

    for path in offending(git_output(["ls-files"])):
        errors.append(f"tracked payload in the working tree: {path}")

    history = [
        line.split(" ", 1)[1]
        for line in git_output(["rev-list", "--objects", "--all"])
        if " " in line
    ]
    for path in sorted(set(offending(history))):
        errors.append(f"payload reachable in history: {path}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", default="config/source_reconstruction_1_0.json")
    args = parser.parse_args()

    contract = load(Path(args.contract))

    errors: list[str] = []
    check_release_header(contract, errors)
    check_scope(contract, errors)
    check_delta(contract, errors)
    requirements = check_requirements(contract, errors)
    check_profiles_and_artifacts(contract, errors)
    check_runtime_coverage(contract, errors)
    check_toolchain(contract, errors)
    check_licensing(contract, errors)
    check_layout_deviations(contract, errors)
    check_aggregate_gates(contract, errors)
    check_manifests(contract, errors)
    check_milestones(contract, errors)
    check_documents(contract, errors)
    check_make_targets(contract, errors)
    check_tracked_payloads(contract, errors)

    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        print(f"[FAIL] audit found {len(errors)} problem(s)", file=sys.stderr)
        return 1

    name = contract["release"]["name"]
    open_milestones = ", ".join(contract["open_milestones"]) or "none"
    profiles = len(contract["profiles"])
    print(
        f"[OK] {name} ({contract['status']}), public manifest schema "
        f"v{contract['schema_version']}"
    )
    print(f"[OK] {requirements} requirement(s), {profiles} profile(s) with identity and")
    print(f"[OK] runtime coverage, toolchain, licensing, documents, targets and history")
    print(f"[OK] all agree. Open milestones: {open_milestones}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

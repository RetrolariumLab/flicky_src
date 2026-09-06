#!/usr/bin/env python3
"""Audit the repository against the Source Reconstruction 1.0 release contract."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

MILESTONE_RE = re.compile(r"^###\s+(\d+)\.\s+.*?-\s+(\w[\w ]*)$", re.MULTILINE)


def load(path: Path) -> dict:
    if not path.is_file():
        raise SystemExit(f"[ERROR] missing {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def git_output(args: list[str]) -> list[str]:
    result = subprocess.run(["git", *args], capture_output=True, text=True, check=False)
    return [line for line in result.stdout.splitlines() if line]


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

    formats = load(Path("config/data_formats.json"))
    exact = sum(1 for a in formats["artifacts"] if a["round_trip"] == "exact")
    semantic = sum(1 for a in formats["artifacts"] if a["round_trip"] == "semantic")
    if exact != contract["evidence"]["exact_round_trips"]:
        errors.append(f"{exact} exact round trips declared, contract says "
                      f"{contract['evidence']['exact_round_trips']}")
    if semantic != contract["evidence"]["semantic_round_trips"]:
        errors.append(f"{semantic} semantic round trips declared, contract says "
                      f"{contract['evidence']['semantic_round_trips']}")
    if len(formats["artifacts"]) != contract["evidence"]["extracted_segments"]:
        errors.append("config/data_formats.json does not cover every extracted segment")


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
    makefile = Path("Makefile").read_text(encoding="utf-8")
    for target in contract["release_commands"]:
        if not re.search(rf"^{re.escape(target)}:", makefile, re.MULTILINE):
            errors.append(f"Makefile has no target '{target}'")


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


def check_toolchain(contract: dict, errors: list[str]) -> None:
    for platform in contract["toolchain"]["platforms"]:
        directory = Path("bin") / platform
        if not directory.is_dir():
            errors.append(f"vendored toolchain missing: {directory}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", default="config/source_reconstruction_1_0.json")
    args = parser.parse_args()

    contract = load(Path(args.contract))
    if contract.get("schema_version") != 1:
        print("[ERROR] unsupported contract schema_version", file=sys.stderr)
        return 1

    errors: list[str] = []
    check_manifests(contract, errors)
    check_milestones(contract, errors)
    check_documents(contract, errors)
    check_make_targets(contract, errors)
    check_tracked_payloads(contract, errors)
    check_toolchain(contract, errors)

    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        print(f"[FAIL] {contract['release']} audit found {len(errors)} problem(s)", file=sys.stderr)
        return 1

    open_milestones = ", ".join(contract["open_milestones"]) or "none"
    print(f"[OK] {contract['release']}: manifests, milestones, documents, targets,")
    print(f"[OK] history and toolchain agree. Open milestones: {open_milestones}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

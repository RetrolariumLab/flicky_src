#!/usr/bin/env python3
"""Check repository-wide text, documentation and evidence invariants."""

from __future__ import annotations

import argparse
import ast
import re
import subprocess
import sys
from pathlib import Path

TEXT_SUFFIXES = {".s", ".inc", ".py", ".c", ".h", ".md", ".txt", ".json", ".csv", ".lua", ".cfg"}
TEXT_FILENAMES = {".gitattributes", ".gitignore", ".editorconfig", "Makefile"}

# Evidence tags separate what was observed from what was inferred.
# See docs/roadmap.md. Every tag except OBS must name a registry entry.
EVIDENCE_TAG_RE = re.compile(r"!\((OBS|ASSUME|WHY\?|UNKNOWN|BUG\?|UNUSED)\)(\s+([A-Z]+-\d{3}))?")
UNKNOWN_TAG_RE = re.compile(r"!\(([A-Za-z?]+)\)")
APPROVED_TAGS = {"OBS", "ASSUME", "WHY?", "UNKNOWN", "BUG?", "UNUSED"}
REGISTRY_ID_RE = re.compile(r"\b(?:CODE|DATA|RAM|SND)-\d{3}\b")
REGISTRY = Path("docs/unknowns.md")

MARKDOWN_LINK_RE = re.compile(r"\[[^\]]*\]\(([^)#]+)(?:#[^)]*)?\)")

# Payloads that must never enter the repository, in the working tree or in any
# reachable commit.
FORBIDDEN_SUFFIXES = {".bin", ".p", ".gen", ".md5"}
FORBIDDEN_PREFIXES = ("data/artnem/", "data/arteni/", "data/artunc/", "data/sound/", "data/other/")


def tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files"], capture_output=True, text=True, check=False
    )
    return [Path(line) for line in result.stdout.splitlines() if line]


def is_text(path: Path) -> bool:
    return path.suffix in TEXT_SUFFIXES or path.name in TEXT_FILENAMES


def check_text_hygiene(path: Path, errors: list[str]) -> str | None:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        errors.append(f"{path}: not valid UTF-8")
        return None
    if "\r" in text:
        errors.append(f"{path}: contains CR; text files use LF")
    if text and not text.endswith("\n"):
        errors.append(f"{path}: missing final newline")
    if text.endswith("\n\n"):
        errors.append(f"{path}: more than one final newline")
    for number, line in enumerate(text.split("\n"), 1):
        if line != line.rstrip():
            errors.append(f"{path}:{number}: trailing whitespace")
    return text


def check_python(path: Path, text: str, errors: list[str]) -> None:
    try:
        ast.parse(text)
    except SyntaxError as error:
        errors.append(f"{path}:{error.lineno}: syntax error: {error.msg}")


def check_markdown_links(path: Path, text: str, errors: list[str]) -> None:
    for target in MARKDOWN_LINK_RE.findall(text):
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.exists():
            errors.append(f"{path}: link target does not exist: {target}")


def check_payload_policy(files: list[Path], errors: list[str]) -> None:
    for path in files:
        text = str(path).replace("\\", "/")
        if path.suffix in FORBIDDEN_SUFFIXES or text.startswith(FORBIDDEN_PREFIXES):
            errors.append(f"{path}: ROM-derived payload must never be tracked")


def check_evidence(files: list[Path], texts: dict[Path, str], errors: list[str]) -> tuple[int, set[str]]:
    used_ids: set[str] = set()
    tag_count = 0
    for path in files:
        text = texts.get(path)
        if text is None or path == REGISTRY:
            continue
        for number, line in enumerate(text.split("\n"), 1):
            for raw in UNKNOWN_TAG_RE.finditer(line):
                name = raw.group(1)
                if name not in APPROVED_TAGS:
                    errors.append(f"{path}:{number}: unknown evidence tag !({name})")
                    continue
                tag_count += 1
                match = EVIDENCE_TAG_RE.search(line[raw.start():])
                identifier = match.group(3) if match else None
                if name == "OBS":
                    continue
                if not identifier:
                    errors.append(
                        f"{path}:{number}: !({name}) must name a registry entry from {REGISTRY}"
                    )
                else:
                    used_ids.add(identifier)
    return tag_count, used_ids


def check_registry(used_ids: set[str], errors: list[str]) -> int:
    if not REGISTRY.is_file():
        if used_ids:
            errors.append(f"{REGISTRY} is missing but evidence tags reference it")
        return 0
    text = REGISTRY.read_text(encoding="utf-8")
    defined = set(re.findall(r"^###\s+((?:CODE|DATA|RAM|SND)-\d{3})\b", text, re.MULTILINE))
    for identifier in sorted(used_ids - defined):
        errors.append(f"{REGISTRY}: no entry for {identifier}, which is referenced from the source")
    for identifier in sorted(defined - used_ids):
        errors.append(f"{REGISTRY}: entry {identifier} is not referenced from anywhere")
    return len(defined)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()

    files = tracked_files()
    if not files:
        print("[ERROR] no tracked files found; run from the repository root", file=sys.stderr)
        return 1

    errors: list[str] = []
    texts: dict[Path, str] = {}

    check_payload_policy(files, errors)

    for path in files:
        if not path.is_file() or not is_text(path):
            continue
        text = check_text_hygiene(path, errors)
        if text is None:
            continue
        texts[path] = text
        if path.suffix == ".py":
            check_python(path, text, errors)
        if path.suffix == ".md":
            check_markdown_links(path, text, errors)

    tag_count, used_ids = check_evidence(files, texts, errors)
    entry_count = check_registry(used_ids, errors)

    if errors:
        for error in errors[:60]:
            print(f"[ERROR] {error}", file=sys.stderr)
        if len(errors) > 60:
            print(f"[ERROR] ... and {len(errors) - 60} more", file=sys.stderr)
        print(f"[FAIL] {len(errors)} project issue(s)", file=sys.stderr)
        return 1

    print(f"[OK] {len(texts)} tracked text files clean; no ROM-derived payload tracked")
    print(f"[OK] {tag_count} evidence tags resolve against {entry_count} registry entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

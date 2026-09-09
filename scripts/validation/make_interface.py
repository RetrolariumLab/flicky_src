"""Read the public Make interface across the root file and workflow fragments."""

from __future__ import annotations

import re
from pathlib import Path


RULE_RE = re.compile(r"^([A-Za-z][^:=\n]*):(?:[^=]|$)", re.MULTILINE)
TARGET_RE = re.compile(r"^[A-Za-z][\w.-]*$")


def makefile_paths(project_root: Path = Path(".")) -> list[Path]:
    """Return the canonical root Makefile followed by its workflow fragments."""
    root = project_root.resolve()
    paths = [root / "Makefile"]
    fragment_root = root / "mk"
    if fragment_root.is_dir():
        paths.extend(sorted(fragment_root.glob("*.mk")))
    return paths


def makefile_text(project_root: Path = Path(".")) -> str:
    """Return one searchable view of every declared Make source file."""
    chunks = []
    for path in makefile_paths(project_root):
        if path.is_file():
            chunks.append(path.read_text(encoding="utf-8"))
    return "\n".join(chunks)


def makefile_targets(project_root: Path = Path(".")) -> set[str]:
    """Collect explicit public and internal rule names from all Make sources."""
    targets: set[str] = set()
    for match in RULE_RE.finditer(makefile_text(project_root)):
        for candidate in match.group(1).split():
            if TARGET_RE.fullmatch(candidate):
                targets.add(candidate)
    return targets


def makefile_recipe(target: str, project_root: Path = Path(".")) -> list[str]:
    """Return the tab-indented recipe lines for one explicit target."""
    lines = makefile_text(project_root).splitlines()
    for index, line in enumerate(lines):
        match = re.match(r"^([A-Za-z][^:=]*):(?:[^=]|$)", line)
        if match is None or target not in match.group(1).split():
            continue
        recipe: list[str] = []
        for candidate in lines[index + 1 :]:
            if not candidate.startswith("\t"):
                break
            recipe.append(candidate[1:])
        return recipe
    return []

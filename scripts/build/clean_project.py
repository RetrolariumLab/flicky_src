#!/usr/bin/env python3
"""Remove approved generated artifacts without traversing user workspaces."""

from __future__ import annotations

import argparse
import os
import shutil
import stat
from pathlib import Path

EXACT_TARGETS = (
    "fbuilt.bin",
    "build/main.p",
    "build/main.lst",
    "flicky.map",
    "flicky.asm",
    "temp.asm",
    "build",
    "language.dat",
    "Gens.cfg",
    "rename_log.txt",
)
ROOT_GLOBS = ("flicky_backup_*.s",)
TOOLS_GLOBS = ("*.exe", "*.o")
CACHE_ROOTS = ("scripts", "tests", "tools")


def resolved_inside(root: Path, path: Path) -> Path:
    """Resolve an approved candidate and reject anything outside the project."""
    resolved = path.resolve()
    if resolved == root:
        raise ValueError("cleanup may not select the project root")
    try:
        resolved.relative_to(root)
    except ValueError as error:
        raise ValueError(f"cleanup path escapes the project root: {path}") from error
    return resolved


def approved_targets(root: Path) -> list[Path]:
    """Return only project-owned generated paths that cleanup may remove."""
    candidates = [root / relative for relative in EXACT_TARGETS]
    candidates.extend(path for pattern in ROOT_GLOBS for path in root.glob(pattern))
    tools = root / "tools"
    if tools.is_dir():
        candidates.extend(path for pattern in TOOLS_GLOBS for path in tools.glob(pattern))
    for relative in CACHE_ROOTS:
        cache_root = root / relative
        if cache_root.is_dir():
            candidates.extend(cache_root.rglob("__pycache__"))

    unique: dict[Path, None] = {}
    for candidate in candidates:
        unique[resolved_inside(root, candidate)] = None
    return sorted(unique, key=lambda path: (len(path.parts), str(path)), reverse=True)


def remove(path: Path) -> bool:
    """Remove one approved file or directory. Return whether it existed."""
    if not path.exists():
        return False
    if path.is_dir():
        shutil.rmtree(path, onerror=remove_readonly)
    else:
        path.unlink()
    print(f"[INFO] removed {path}")
    return True


def remove_readonly(function, path: str, _error) -> None:
    """Retry deletion of a read-only entry inside an approved target."""
    os.chmod(path, stat.S_IWRITE)
    function(path)


def clean(root: Path) -> int:
    """Remove approved generated paths below a resolved project root."""
    root = root.resolve()
    removed = sum(remove(path) for path in approved_targets(root))
    if removed:
        print(f"[OK] removed {removed} build artifact(s); user workspaces left untouched")
    else:
        print("[OK] nothing to clean")
    return removed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    args = parser.parse_args()
    clean(Path(args.root))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

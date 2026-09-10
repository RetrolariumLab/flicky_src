#!/usr/bin/env python3
"""Build the project YMFM frontend through its pinned Docker recipe."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DOCKERFILE = Path("scripts/authoring/ymfm_renderer/Dockerfile")
FRONTEND_SOURCE = Path("scripts/authoring/ymfm_renderer/main.cpp")


def build_command(docker: str, output_dir: Path) -> list[str]:
    """Return the reproducible container build command for the native frontend."""
    for relative in (DOCKERFILE, FRONTEND_SOURCE, Path("third_party/ymfm/src")):
        if not (PROJECT_ROOT / relative).exists():
            raise FileNotFoundError(f"YMFM renderer input is missing: {relative}")
    return [
        docker,
        "build",
        "--platform",
        "linux/amd64",
        "--file",
        DOCKERFILE.as_posix(),
        "--output",
        f"type=local,dest={output_dir.as_posix()}",
        ".",
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--docker", default="docker")
    parser.add_argument("--output-dir", type=Path, default=Path("bin/windows_i386"))
    args = parser.parse_args()
    result = subprocess.run(
        build_command(args.docker, args.output_dir),
        cwd=PROJECT_ROOT,
        check=False,
    )
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())

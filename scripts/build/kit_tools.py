#!/usr/bin/env python3
"""The programs Retrolarium Kit ships, for the build's cc65."""

from __future__ import annotations

import os
from pathlib import Path
import shlex
import subprocess


def kit_tool_path(spec: str) -> Path:
    """A program Retrolarium Kit ships, as suite/tool (nes/ca65); RLTOOL
    names the kit command (default rltool)."""
    suite, _, tool = spec.partition("/")
    # On Windows the command keeps its quoted paths (they may hold spaces).
    kit = [part[1:-1] if len(part) > 1 and part[0] == part[-1] == '"' else part
           for part in shlex.split(os.environ.get("RLTOOL", "rltool"), posix=os.name != "nt")]
    completed = subprocess.run([*kit, "build-tools", "path", suite, tool],
                               capture_output=True, text=True, check=False)
    if completed.returncode:
        raise ValueError(f"Retrolarium Kit has no {spec}: {completed.stderr.strip()}")
    return Path(completed.stdout.strip().splitlines()[-1])

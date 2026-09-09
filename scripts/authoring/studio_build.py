"""Construct content-build commands with explicit Studio workspace inputs."""

from __future__ import annotations

from pathlib import Path
from typing import Mapping


MAKE_VARIABLES = {
    "level_layouts": "CONTENT_LEVEL_WORKSPACE",
    "graphics_assets": "CONTENT_GRAPHICS_WORKSPACE",
    "graphics_semantics": "CONTENT_SEMANTICS_WORKSPACE",
    "graphics_sequences": "CONTENT_SEQUENCES_WORKSPACE",
    "z80_sound_banks": "CONTENT_SOUND_WORKSPACE",
}


def build_content_command(workspaces: Mapping[str, Path]) -> list[str]:
    """Return a make command that preserves every supplied workspace path."""
    unknown = sorted(set(workspaces) - set(MAKE_VARIABLES))
    if unknown:
        raise ValueError(f"unsupported content workspace override: {unknown[0]}")
    command = ["make", "build-content"]
    for artifact_id, variable in MAKE_VARIABLES.items():
        if artifact_id in workspaces:
            path = workspaces[artifact_id].resolve().as_posix()
            command.append(f"{variable}={path}")
    return command

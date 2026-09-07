"""Extract source payloads from the user's ROM and read their assembly views."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys
from tempfile import NamedTemporaryFile


def write_payload(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(data)
            stream.close()
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def project_root(path: Path) -> Path:
    for parent in (path.resolve(), *path.resolve().parents):
        if (parent / "assets/rom_payloads.json").is_file():
            return parent
    raise ValueError(f"{path}: the ROM asset configuration is missing")


def prepare(root: Path, *, replace: bool = False) -> None:
    config = json.loads((root / "assets/rom_payloads.json").read_text(encoding="utf-8"))
    images = {}
    by_id = {image["id"]: image for image in config["images"]}
    for asset in config["assets"]:
        output = root / config["output"] / asset["path"]
        if output.is_file() and not replace:
            continue
        for image_id in asset["sources"]:
            spec = by_id[image_id]
            source = root / spec["file"]
            if not source.is_file():
                continue
            if image_id not in images:
                image = source.read_bytes()
                if len(image) != spec["size"] or hashlib.sha1(image).hexdigest() != spec["sha1"]:
                    raise ValueError(f"{source.name}: the reference ROM does not match its identity")
                images[image_id] = image
            offset = asset["sources"][image_id]
            data = images[image_id][offset : offset + asset["size"]]
            if hashlib.sha1(data).hexdigest() != asset["sha1"]:
                raise ValueError(f"{asset['path']}: the extracted bytes do not match")
            write_payload(output, data)
            break
        else:
            # A regional branch may be inactive when only one cartridge is supplied.
            continue
    for include in config.get("c_includes", []):
        output = root / include["path"]
        if output.is_file() and not replace:
            continue
        data = (root / config["output"] / include["asset"]).read_bytes()
        data = data[include["offset"] : include["offset"] + include["size"]]
        write_payload(output, (", ".join(f"0x{value:02X}" for value in data) + ",\n").encode("ascii"))
    document = config.get("music_document")
    if document and (replace or not (root / document["path"]).is_file()):
        script = root / document["decoder"]
        sys.path.insert(0, str(root))
        sys.path.insert(0, str(script.parent))
        spec = importlib.util.spec_from_file_location("rom_music_decoder", script)
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        source = root / by_id[document["image"]]["file"]
        image = source.read_bytes()
        prg = image[16 : 16 + image[4] * 16384]
        layout = json.loads((root / document["layout"]).read_text(encoding="utf-8"))
        result = module.decode_authoring(prg, layout)
        output = root / document["path"]
        write_payload(output, (json.dumps(result, indent=2) + "\n").encode("utf-8"))


INCLUDE = re.compile(
    r'(?P<head>[^\n]*?)(?:\.incbin|binclude)\s+"(?P<path>[^"]+)"'
    r"(?:\s*,\s*(?P<offset>\$[\dA-Fa-f]+|\d+)\s*,\s*(?P<size>\$[\dA-Fa-f]+|\d+))?"
    r"\s*(?:; rom-asset (?P<kind>\.byte|\.word|dc\.b|dc\.w))?\s*$",
    re.MULTILINE,
)


def number(value: str) -> int:
    return int(value[1:], 16) if value.startswith("$") else int(value)


def read_asm_source(path: Path) -> str:
    root = project_root(path)
    text = path.read_text(encoding="utf-8")

    def expand(match: re.Match[str]) -> str:
        config = json.loads((root / "assets/rom_payloads.json").read_text(encoding="utf-8"))
        relative = match["path"].removeprefix(config["output"] + "/")
        if relative not in {asset["path"] for asset in config["assets"]}:
            return match[0]
        prepare(root)
        data = (root / match["path"]).read_bytes()
        if match["offset"]:
            start = number(match["offset"])
            data = data[start : start + number(match["size"])]
        kind = match["kind"] or ("dc.b" if relative.endswith("sega-fade.bin") else "dc.w")
        width = 2 if kind in (".word", "dc.w") else 1
        endian = "big" if kind.startswith("dc.") else "little"
        values = [int.from_bytes(data[i : i + width], endian) for i in range(0, len(data), width)]
        return match["head"] + kind + " " + ", ".join(f"${value:0{width * 2}X}" for value in values)

    return INCLUDE.sub(expand, text)


def read_source_text(path: Path, *args, **kwargs) -> str:
    text = path.read_text(*args, **kwargs)
    if path.suffix.lower() in {".s", ".asm", ".inc"} and ("; rom-asset " in text or 'binclude "data/palettes/' in text):
        return read_asm_source(path)
    return text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("ensure", "split"))
    args = parser.parse_args()
    prepare(project_root(Path(__file__)), replace=args.command == "split")


if __name__ == "__main__":
    main()

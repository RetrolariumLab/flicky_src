import hashlib
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import debug_symbols  # noqa: E402
import genstate  # noqa: E402
import run_runtime_scenarios  # noqa: E402
import validate_runtime_scenarios  # noqa: E402

SPEC = json.loads(
    (ROOT / "scenarios" / "runtime_scenarios.json").read_text(encoding="utf-8")
)


def dump(ram: bytes) -> bytes:
    """A minimal state dump carrying only work RAM, for the validator tests."""
    header = bytearray(genstate.HEADER_SIZE)
    header[0:len(genstate.MAGIC)] = genstate.MAGIC
    struct.pack_into("<I", header, len(genstate.MAGIC), 1)
    offset = genstate.HEADER_SIZE + 2 * genstate.SECTION_ENTRY.size
    table = genstate.SECTION_ENTRY.pack(genstate.SECTION_M68K_RAM, offset, len(ram), 0)
    table += genstate.SECTION_ENTRY.pack(0, 0, 0, 0)
    return bytes(header) + table + ram


class Pinning(unittest.TestCase):
    def test_every_movie_matches_the_sha1_the_scenarios_pin(self):
        for name, movie in SPEC["movies"].items():
            path = ROOT / movie["path"]
            digest = hashlib.sha1(path.read_bytes()).hexdigest()
            self.assertEqual(digest, movie["sha1"], name)

    def test_the_rom_hash_matches_the_asset_manifest(self):
        assets = json.loads((ROOT / "assets" / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(SPEC["rom_sha1"], assets["reference_rom"]["sha1"])


class Scenarios(unittest.TestCase):
    def test_ids_are_unique(self):
        ids = [scenario["id"] for scenario in SPEC["scenarios"]]
        self.assertEqual(len(ids), len(set(ids)))

    def test_every_scenario_names_a_declared_movie(self):
        for scenario in SPEC["scenarios"]:
            self.assertIn(scenario["movie"], SPEC["movies"], scenario["id"])

    def test_frame_ranges_are_ordered(self):
        for scenario in SPEC["scenarios"]:
            self.assertLess(scenario["first_frame"], scenario["last_frame"], scenario["id"])

    def test_every_scenario_declares_how_it_reaches_its_state(self):
        # Natural play and controlled patches are never interchangeable, so the
        # method is mandatory even when every scenario currently uses the same one.
        for scenario in SPEC["scenarios"]:
            self.assertIn(scenario["method"], {"natural play", "controlled"}, scenario["id"])

    def test_the_attract_demo_is_covered(self):
        # The longplay presses start before the demos run, so without this
        # scenario Demo_Init and the four input streams have no coverage at all.
        ids = {scenario["id"] for scenario in SPEC["scenarios"]}
        self.assertIn("demos-demo-play-round-1", ids)

    def test_frame_ranges_come_from_the_tracked_scene_index(self):
        index = (ROOT / "movies" / "longplay_description.txt").read_text(encoding="utf-8")
        ranges = {line.split(",")[0].strip() for line in index.splitlines()[1:] if "," in line}
        for scenario in SPEC["scenarios"]:
            if scenario["movie"] != "longplay":
                continue
            span = f"{scenario['first_frame']}-{scenario['last_frame']}"
            self.assertIn(span, ranges, scenario["id"])


class Expectations(unittest.TestCase):
    def setUp(self):
        self.symbols = debug_symbols.equates([ROOT / SPEC["symbols"]["source"]])

    def test_every_expected_symbol_exists_in_the_ram_map(self):
        # Expectations name symbols, never addresses, so a rename that misses
        # ram.inc has to break here rather than silently read other memory.
        for scenario in SPEC["scenarios"]:
            state = scenario["expect_state"]
            for name in list(state["holds"]) + list(state["reaches"]):
                self.assertIn(name, self.symbols, f"{scenario['id']}: {name}")
                self.assertIn(name, SPEC["symbols"]["sizes"], f"{scenario['id']}: {name}")

    def test_every_declared_value_fits_its_field(self):
        for scenario in SPEC["scenarios"]:
            state = scenario["expect_state"]
            for name, text in list(state["holds"].items()) + list(state["reaches"].items()):
                size = SPEC["symbols"]["sizes"][name]
                self.assertEqual(len(text), 1 + size * 2, f"{scenario['id']}: {name}={text}")
                self.assertLess(validate_runtime_scenarios.parse_value(text), 1 << (size * 8))

    def test_every_scenario_declares_something(self):
        for scenario in SPEC["scenarios"]:
            state = scenario["expect_state"]
            self.assertTrue(state["holds"] or state["reaches"], scenario["id"])

    def test_a_field_is_never_both_held_and_reached(self):
        # The two are contradictory: a field that holds one value cannot also be
        # asserted to take a different one somewhere in the same window.
        for scenario in SPEC["scenarios"]:
            state = scenario["expect_state"]
            self.assertEqual(set(state["holds"]) & set(state["reaches"]), set(), scenario["id"])


class Validator(unittest.TestCase):
    def test_a_missing_capture_directory_is_an_error_not_a_pass(self):
        with self.assertRaises(SystemExit) as raised:
            validate_runtime_scenarios.fail("no capture")
        self.assertEqual(raised.exception.code, 1)

    def test_frames_are_hashed_by_name(self):
        empty = validate_runtime_scenarios.frames(ROOT / "tests")
        self.assertEqual(empty, {})

    def test_hex_and_decimal_values_both_parse(self):
        self.assertEqual(validate_runtime_scenarios.parse_value("$8004"), 0x8004)
        self.assertEqual(validate_runtime_scenarios.parse_value("12"), 12)

    def test_only_dumps_inside_the_window_are_considered(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            for frame in (100, 200, 300, 400):
                (directory / f"{frame:06d}.genstate").write_bytes(b"")
            found = validate_runtime_scenarios.dumps_in_window(directory, 200, 300)
            self.assertEqual([path.stem for path in found], ["000200", "000300"])

    def test_a_broken_expectation_is_reported(self):
        scenario = {
            "id": "synthetic", "first_frame": 0, "last_frame": 0,
            "expect_state": {"holds": {"Ram_Lives": "$03"}, "reaches": {}},
        }
        ram = bytearray(genstate.WORK_RAM_SIZE)
        ram[0xD882 ^ 1] = 5
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            (directory / "000000.genstate").write_bytes(dump(bytes(ram)))
            errors = validate_runtime_scenarios.check_state(
                scenario, directory, {"Ram_Lives": 0xFFD882}, {"Ram_Lives": 1}
            )
        self.assertEqual(len(errors), 1)
        self.assertIn("$05", errors[0])

    def test_an_empty_window_is_an_error_not_a_pass(self):
        scenario = {
            "id": "synthetic", "first_frame": 500, "last_frame": 600,
            "expect_state": {"holds": {"Ram_Lives": "$03"}, "reaches": {}},
        }
        with tempfile.TemporaryDirectory() as tmp:
            errors = validate_runtime_scenarios.check_state(
                scenario, Path(tmp), {"Ram_Lives": 0xFFD882}, {"Ram_Lives": 1}
            )
        self.assertEqual(len(errors), 1)
        self.assertIn("no state dumps", errors[0])


class Pruning(unittest.TestCase):
    def files(self, directory):
        return sorted(path.name for path in directory.iterdir())

    def test_only_frames_inside_the_window_survive(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            for frame in (80, 100, 200, 300, 320):
                (directory / f"{frame:06d}.png").write_bytes(b"x")
                (directory / f"{frame:06d}.genstate").write_bytes(b"y")
            removed, freed = run_runtime_scenarios.prune_to_window(directory, 100, 300)
            self.assertEqual(removed, 4)
            self.assertEqual(freed, 4)
            self.assertEqual(
                self.files(directory),
                ["000100.genstate", "000100.png", "000200.genstate", "000200.png",
                 "000300.genstate", "000300.png"],
            )

    def test_the_window_bounds_are_inclusive(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            for frame in (100, 300):
                (directory / f"{frame:06d}.png").write_bytes(b"x")
            run_runtime_scenarios.prune_to_window(directory, 100, 300)
            self.assertEqual(self.files(directory), ["000100.png", "000300.png"])

    def test_unrelated_files_are_left_alone(self):
        # Pruning deletes, so it must only ever match the emulator's own output.
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            (directory / "000900.png").write_bytes(b"x")
            (directory / "notes.txt").write_bytes(b"x")
            (directory / "summary.json").write_bytes(b"x")
            (directory / "reference.png").write_bytes(b"x")
            run_runtime_scenarios.prune_to_window(directory, 100, 300)
            self.assertEqual(
                self.files(directory), ["notes.txt", "reference.png", "summary.json"]
            )


if __name__ == "__main__":
    unittest.main()

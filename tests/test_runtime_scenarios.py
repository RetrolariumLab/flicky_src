import hashlib
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import validate_runtime_scenarios  # noqa: E402

SPEC = json.loads(
    (ROOT / "scenarios" / "runtime_scenarios.json").read_text(encoding="utf-8")
)


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


class Validator(unittest.TestCase):
    def test_a_missing_capture_directory_is_an_error_not_a_pass(self):
        with self.assertRaises(SystemExit) as raised:
            validate_runtime_scenarios.fail("no capture")
        self.assertEqual(raised.exception.code, 1)

    def test_frames_are_hashed_by_name(self):
        empty = validate_runtime_scenarios.frames(ROOT / "tests")
        self.assertEqual(empty, {})


if __name__ == "__main__":
    unittest.main()

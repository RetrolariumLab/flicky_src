import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import release_audit  # noqa: E402

CONTRACT = json.loads(
    (ROOT / "config" / "source_reconstruction_1_0.json").read_text(encoding="utf-8")
)


class MilestoneParsing(unittest.TestCase):
    def test_status_is_read_from_the_heading(self):
        # A fixture, not the roadmap: the parser has to report whatever word the
        # heading carries, not assume every milestone is complete.
        text = "### 3. Semantic naming - Complete\n### 7. Runtime evidence - Blocked\n"
        found = dict(release_audit.MILESTONE_RE.findall(text))
        self.assertEqual(found["3"], "Complete")
        self.assertEqual(found["7"], "Blocked")

    def test_the_roadmap_agrees_with_the_contract(self):
        errors: list[str] = []
        release_audit.check_milestones(CONTRACT, errors)
        self.assertEqual(errors, [])

    def test_a_contradiction_is_caught(self):
        contract = dict(CONTRACT)
        contract["complete_milestones"] = [n for n in CONTRACT["complete_milestones"] if n != 7]
        contract["open_milestones"] = {"7": "claimed open while the roadmap says complete"}
        errors: list[str] = []
        release_audit.check_milestones(contract, errors)
        self.assertTrue(any("milestone 7" in error for error in errors), errors)


class Agreement(unittest.TestCase):
    def test_the_manifests_agree(self):
        errors: list[str] = []
        release_audit.check_manifests(CONTRACT, errors)
        self.assertEqual(errors, [])

    def test_every_required_document_exists(self):
        errors: list[str] = []
        release_audit.check_documents(CONTRACT, errors)
        self.assertEqual(errors, [])

    def test_every_release_command_is_a_make_target(self):
        errors: list[str] = []
        release_audit.check_make_targets(CONTRACT, errors)
        self.assertEqual(errors, [])

    def test_no_payload_is_tracked_anywhere_in_history(self):
        errors: list[str] = []
        release_audit.check_tracked_payloads(CONTRACT, errors)
        self.assertEqual(errors, [])


class Contract(unittest.TestCase):
    def test_runtime_captures_are_claimed_and_the_roadmap_agrees(self):
        # Claiming runtime evidence commits the roadmap and the scenarios to it:
        # the flag, the milestone status and the declared count move together.
        self.assertTrue(CONTRACT["evidence"]["runtime_captures_produced"])
        self.assertNotIn("7", CONTRACT["open_milestones"])
        self.assertIn(7, CONTRACT["complete_milestones"])

    def test_the_declared_expectation_count_matches_the_scenarios(self):
        spec = json.loads(
            (ROOT / "scenarios" / "runtime_scenarios.json").read_text(encoding="utf-8")
        )
        declared = sum(
            len(scenario["expect_state"]["holds"]) + len(scenario["expect_state"]["reaches"])
            for scenario in spec["scenarios"]
        )
        self.assertEqual(declared, CONTRACT["evidence"]["runtime_state_expectations"])

    def test_the_gate_runs_the_capture(self):
        self.assertIn("trace", CONTRACT["release_commands"])

    def test_the_reference_hashes_match_the_asset_manifest(self):
        assets = json.loads((ROOT / "assets" / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(assets["reference_rom"]["sha1"], CONTRACT["reference"]["rom_sha1"])


class EndToEnd(unittest.TestCase):
    def test_the_audit_passes(self):
        result = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "release_audit.py")],
            cwd=ROOT, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()

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
        contract["complete_milestones"] = CONTRACT["complete_milestones"] + [7]
        errors: list[str] = []
        release_audit.check_milestones(contract, errors)
        self.assertTrue(any("milestone 7" in error for error in errors))


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
    def test_runtime_captures_are_declared_as_not_produced(self):
        # The one thing 1.0 does not claim. If this ever flips to true the
        # roadmap and the release document have to change with it.
        self.assertFalse(CONTRACT["evidence"]["runtime_captures_produced"])
        self.assertIn("7", CONTRACT["open_milestones"])

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

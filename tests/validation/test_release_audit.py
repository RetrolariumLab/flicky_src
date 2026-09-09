import copy
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import release_audit  # noqa: E402

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


class ContractShape(unittest.TestCase):
    """The manifest has to expose a stable project-owned public shape."""

    def test_it_names_the_public_schema_and_release_line(self):
        self.assertEqual(
            CONTRACT["schema_version"], release_audit.MANIFEST_SCHEMA_VERSION
        )
        self.assertEqual(CONTRACT["release_line"], CONTRACT["release"]["version"])

    def test_the_tag_follows_the_template(self):
        self.assertEqual(CONTRACT["tag"], f"source-reconstruction-{CONTRACT['release']['version']}")

    def test_a_first_release_records_a_null_predecessor_rather_than_omitting_it(self):
        # Omitting the field and having no predecessor look identical otherwise.
        self.assertIn("predecessor", CONTRACT)
        self.assertIsNone(CONTRACT["predecessor"])

    def test_every_required_field_is_present(self):
        for field in ("release_kind", "status", "included_scope", "excluded_scope",
                      "delta", "requirements", "profiles", "runtime_coverage",
                      "toolchain", "artifacts", "aggregate_gates",
                      "layout_deviations", "licensing", "provenance"):
            self.assertIn(field, CONTRACT)

    def test_requirement_statuses_are_from_the_allowed_set(self):
        for name, entry in CONTRACT["requirements"].items():
            self.assertIn(entry["status"], release_audit.REQUIREMENT_STATUSES, name)

    def test_a_partial_requirement_points_at_its_exclusion(self):
        # A requirement may fall short, but then the manifest has to say where
        # the shortfall is recorded rather than leaving it as a bare status.
        excluded = {entry["id"] for entry in CONTRACT["excluded_scope"]}
        self.assertIn("z80_sound_driver_source", excluded)
        self.assertEqual(CONTRACT["requirements"]["source_boundary"]["status"], "partial")

    def test_the_accepted_profile_has_identity_and_coverage(self):
        profile = CONTRACT["profiles"][0]
        self.assertEqual(profile["status"], "supported")
        self.assertEqual(profile["identity"], "byte-identical")
        covered = {row["profile_id"] for row in CONTRACT["runtime_coverage"]}
        self.assertIn(profile["id"], covered)

    def test_licensing_separates_the_game_from_the_tooling(self):
        by_category = {entry["category"]: entry for entry in CONTRACT["licensing"]}
        self.assertEqual(
            by_category["reconstructed_game_source"]["license_id_or_status"],
            "license_not_granted",
        )
        self.assertEqual(by_category["own_project_tools"]["license_id_or_status"], "licensed")
        self.assertFalse(CONTRACT["provenance"]["private_inputs_tracked"])

    def test_every_layout_deviation_names_an_equivalent_control(self):
        for entry in CONTRACT["layout_deviations"]:
            self.assertTrue(entry["equivalent_control"], entry["rule_id"])

    def test_build_tools_pin_exact_source_revisions(self):
        errors: list[str] = []
        release_audit.check_toolchain(CONTRACT, errors)
        self.assertEqual(errors, [])

    def test_converter_without_source_or_binary_origin_is_rejected(self):
        toolchain = json.loads(
            (ROOT / "config/toolchain.json").read_text(encoding="utf-8")
        )
        converter = next(
            component
            for component in toolchain["components"]
            if component["id"] == "binary_converter"
        )
        converter["source_commit"] = None
        converter.pop("binary_provenance")
        with tempfile.TemporaryDirectory() as directory:
            manifest = Path(directory) / "toolchain.json"
            manifest.write_text(json.dumps(toolchain), encoding="utf-8")
            contract = copy.deepcopy(CONTRACT)
            contract["toolchain"]["manifest"] = str(manifest)
            errors: list[str] = []
            release_audit.check_toolchain(contract, errors)
        self.assertTrue(any("no exact source revision" in error for error in errors))
        self.assertTrue(any("no exact binary origin" in error for error in errors))

    def test_the_gate_runs_the_declared_commands_in_the_declared_order(self):
        # check_make_targets compares the release-check recipe against
        # release_commands, so the contract cannot claim a layer the gate skips.
        errors: list[str] = []
        release_audit.check_make_targets(CONTRACT, errors)
        self.assertEqual(errors, [])

    def test_a_reordered_gate_is_caught(self):
        contract = dict(CONTRACT)
        contract["release_commands"] = list(reversed(CONTRACT["release_commands"]))
        errors: list[str] = []
        release_audit.check_make_targets(contract, errors)
        self.assertTrue(any("different sequence" in error for error in errors), errors)


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
            [sys.executable, str(ROOT / "scripts" / "run.py"), "validation.release_audit"],
            cwd=ROOT, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()

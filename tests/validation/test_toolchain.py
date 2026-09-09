import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

from validation import verify_toolchain  # noqa: E402

CONFIG = json.loads((ROOT / "config" / "toolchain.json").read_text(encoding="utf-8"))


class Manifest(unittest.TestCase):
    def test_every_component_records_what_it_is(self):
        for component in CONFIG["components"]:
            for field in ("id", "version", "source", "provenance", "verification"):
                self.assertTrue(component.get(field), f"{component.get('id')}: {field}")

    def test_a_source_built_component_pins_a_commit(self):
        # A source-built component keeps its source identity in addition to
        # the approved hash of the executable that actually runs.
        for component in CONFIG["components"]:
            if component["provenance"] == "source-built":
                self.assertRegex(component["source_commit"] or "", r"^[0-9a-f]{40}$")

    def test_the_converter_pins_its_actual_source_and_binary_origins(self):
        converter = next(
            component
            for component in CONFIG["components"]
            if component["id"] == "binary_converter"
        )
        self.assertEqual(converter["source"], "https://github.com/Clownacy/p2bin")
        self.assertRegex(converter["source_commit"], r"^[0-9a-f]{40}$")
        self.assertEqual(
            set(converter["binary_provenance"]),
            {"windows_i386", "linux_x86_64"},
        )
        for provenance in converter["binary_provenance"].values():
            self.assertRegex(provenance["origin_commit"], r"^[0-9a-f]{40}$")
            self.assertTrue(provenance["origin"].startswith("https://github.com/"))

    def test_every_recorded_file_has_a_hash_and_a_size(self):
        for component in CONFIG["components"]:
            for entries in component["files"].values():
                for entry in entries:
                    self.assertRegex(entry["sha256"], r"^[0-9a-f]{64}$")
                    self.assertGreater(entry["size"], 0)

    def test_the_recorded_hashes_match_the_vendored_files(self):
        for component in CONFIG["components"]:
            for entries in component["files"].values():
                for entry in entries:
                    path = ROOT / entry["path"]
                    if not path.is_file():
                        continue
                    digest = hashlib.sha256(path.read_bytes()).hexdigest()
                    self.assertEqual(digest, entry["sha256"], entry["path"])

    def test_a_host_is_declared_with_a_support_status(self):
        self.assertTrue(CONFIG["hosts"])
        allowed = {"supported", "partial", "unsupported", "planned"}
        for host in CONFIG["hosts"]:
            self.assertIn(host["supported_status"], allowed)
            self.assertTrue(host["evidence"], host["os"])


class Verification(unittest.TestCase):
    def entry(self, path: Path) -> dict:
        return {
            "path": str(path),
            "size": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }

    def test_a_matching_file_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tool.exe"
            path.write_bytes(b"assembler")
            errors, notes = [], []
            checked = verify_toolchain.check_files([self.entry(path)], errors, notes)
            self.assertEqual((errors, checked), ([], 1))

    def test_a_swapped_binary_is_caught(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "tool.exe"
            path.write_bytes(b"assembler")
            entry = self.entry(path)
            path.write_bytes(b"assemblES")  # same length, different bytes
            errors, notes = [], []
            verify_toolchain.check_files([entry], errors, notes)
            self.assertTrue(
                any("does not match the recorded build" in error for error in errors),
                errors,
            )

    def test_a_missing_binary_is_an_error(self):
        errors, notes = [], []
        verify_toolchain.check_files(
            [{"path": "does/not/exist", "size": 1, "sha256": "0" * 64}], errors, notes
        )
        self.assertEqual(len(errors), 1)
        self.assertIn("missing", errors[0])

    def test_a_substituted_emulator_binary_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "Gens.exe"
            path.write_bytes(b"a build")
            entry = self.entry(path)
            entry["sha256"] = "0" * 64
            errors, notes = [], []
            verify_toolchain.check_files([entry], errors, notes)
            self.assertEqual(notes, [])
            self.assertEqual(len(errors), 1)
            self.assertIn("does not match the recorded build", errors[0])

    def test_emulator_manifest_enforces_commit_and_binary_hash(self):
        emulator = next(
            component for component in CONFIG["components"]
            if component["id"] == "emulator"
        )
        self.assertEqual(emulator["identity"], "source_commit_and_binary_hash")
        for entries in emulator["files"].values():
            for entry in entries:
                self.assertNotIn("observed_only", entry)

    def test_selected_executable_path_is_hashed(self):
        with tempfile.TemporaryDirectory() as tmp:
            approved = Path(tmp) / "approved.exe"
            approved.write_bytes(b"approved tool")
            component = {
                "id": "assembler",
                "files": {
                    "test": [dict(self.entry(approved), executable=True)]
                },
            }
            substitute = Path(tmp) / "substitute.exe"
            substitute.write_bytes(b"substitute!!")
            errors, notes = [], []
            verify_toolchain.check_selected_executables(
                [component],
                "test",
                {"assembler": substitute},
                errors,
                notes,
            )
            self.assertTrue(
                any("does not match the recorded build" in error for error in errors),
                errors,
            )

    def test_make_rejects_mismatched_tool_overrides_before_z80_build(self):
        with tempfile.TemporaryDirectory() as tmp:
            substitute = Path(tmp) / "substitute.exe"
            substitute.write_bytes(b"not an approved build tool")
            for variable in ("AS_BIN", "P2BIN"):
                with self.subTest(variable=variable):
                    result = subprocess.run(
                        [
                            "make",
                            "-B",
                            "z80-check",
                            f"{variable}={substitute}",
                            "Z80_REFERENCE=assets/manifest.json",
                            f"Z80_BIN={Path(tmp) / (variable + '.bin')}",
                            f"Z80_OBJ={Path(tmp) / (variable + '.p')}",
                        ],
                        cwd=ROOT,
                        capture_output=True,
                        text=True,
                    )
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("does not match the recorded build", result.stderr)
                    self.assertNotIn("[RUN]", result.stdout)

    def test_make_rejects_a_mismatched_emulator_override_before_launch(self):
        with tempfile.TemporaryDirectory() as tmp:
            substitute = Path(tmp) / "Gens.exe"
            substitute.write_bytes(b"not the approved emulator")
            result = subprocess.run(
                [
                    "make",
                    "-B",
                    "reference",
                    "MOVIE=longplay",
                    f"GENS_EXE={substitute}",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("does not match the recorded build", result.stderr)
            self.assertNotIn("-screenshot-interval", result.stdout)


if __name__ == "__main__":
    unittest.main()

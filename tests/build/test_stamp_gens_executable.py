import hashlib
import json
import struct
import tempfile
import unittest
from pathlib import Path

from scripts.build.stamp_gens_executable import StampError, stamp_executable, stamp_pe


class StampGensExecutableTests(unittest.TestCase):
    def test_stamps_approved_pe_and_rejects_other_bytes_without_overwriting(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            executable = root / "Gens.exe"
            image = bytearray(256)
            image[:2] = b"MZ"
            struct.pack_into("<I", image, 60, 128)
            image[128:132] = b"PE\0\0"
            struct.pack_into("<I", image, 136, 123)
            executable.write_bytes(image)
            approved = stamp_pe(bytes(image), 456)
            digest = hashlib.sha256(approved).hexdigest()
            config = root / "toolchain.json"
            config.write_text(
                json.dumps({"components": [{
                    "id": "emulator",
                    "pe_timestamp": 456,
                    "files": {"any": [{"sha256": digest}]},
                }]}),
                encoding="utf-8",
            )

            self.assertEqual(stamp_executable(config, executable), digest)
            self.assertEqual(executable.read_bytes(), approved)

            changed = bytearray(approved)
            changed[-1] = 1
            executable.write_bytes(changed)
            with self.assertRaisesRegex(StampError, "differs from approved"):
                stamp_executable(config, executable)
            self.assertEqual(executable.read_bytes(), changed)


if __name__ == "__main__":
    unittest.main()

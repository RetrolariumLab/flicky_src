import csv
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_sequencer import ChipWrite  # noqa: E402
from validation import verify_sound_trace  # noqa: E402


class SoundTraceComparison(unittest.TestCase):
    def test_python_trace_selects_ym_and_omits_timer_maintenance(self):
        writes = [
            ChipWrite(0, "ym2612", 0x91, address=0x24),
            ChipWrite(0, "ym2612", 0xF0, address=0x28),
            ChipWrite(0, "sn76489", 0x9F),
        ]
        self.assertEqual(
            verify_sound_trace.python_writes(writes),
            [
                verify_sound_trace.RegisterWrite("YM2612", 0, 0x28, 0xF0),
            ],
        )

    def test_csv_frame_window_and_hex_fields(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "trace.csv"
            with path.open("w", newline="", encoding="ascii") as target:
                writer = csv.writer(target)
                writer.writerow(("sequence", "frame", "chip", "port", "address", "value"))
                writer.writerow((0, 9, "YM2612", 0, "28", "00"))
                writer.writerow((1, 10, "YM2612", 1, "A4", "2C"))
                writer.writerow((2, 10, "YM2612", 0, "24", "91"))
                writer.writerow((3, 11, "SN76489", 0, "00", "9F"))
            self.assertEqual(
                verify_sound_trace.gens_writes(path, 10, 11),
                [
                    verify_sound_trace.RegisterWrite("YM2612", 1, 0xA4, 0x2C),
                ],
            )
            self.assertEqual(
                verify_sound_trace.gens_timed_writes(path, 10, 11),
                [(10, verify_sound_trace.RegisterWrite("YM2612", 1, 0xA4, 0x2C))],
            )

    def test_alignment_requires_one_exact_signature(self):
        expected = [
            verify_sound_trace.RegisterWrite("YM2612", 0, 0x30 + i, i)
            for i in range(32)
        ]
        prefix = [verify_sound_trace.RegisterWrite("YM2612", 0, 0x22, 0)]
        self.assertEqual(
            verify_sound_trace.find_alignment(prefix + expected, expected), 1
        )
        self.assertEqual(
            verify_sound_trace.compare_traces(prefix + expected, expected, 32), 32
        )

    def test_timing_comparison_rejects_double_speed(self):
        writes = [
            verify_sound_trace.RegisterWrite("YM2612", 0, 0x30 + index, index)
            for index in range(32)
        ]
        observed = [(100 + index, write) for index, write in enumerate(writes)]
        correct = [(735 * index, write) for index, write in enumerate(writes)]
        fast = [(368 * index, write) for index, write in enumerate(writes)]
        self.assertLess(
            verify_sound_trace.compare_timing(observed, correct, 44_100),
            0.1,
        )
        with self.assertRaisesRegex(ValueError, "sound timing differs"):
            verify_sound_trace.compare_timing(observed, fast, 44_100)


if __name__ == "__main__":
    unittest.main()

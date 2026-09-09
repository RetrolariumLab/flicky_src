import struct
import subprocess
import sys
import tempfile
import unittest
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

from authoring.sound_sequencer import (  # noqa: E402
    YM2612_CLOCK,
    SoundSequencer,
    timer_a_period_samples,
    timer_b_period_samples,
)
from authoring.sound_vgm import encode_vgm, write_vgm  # noqa: E402


class OfflineSoundSequencer(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = ROOT / "src/sound/z80/data.asm"

    def sequencer(self):
        return SoundSequencer.from_source(self.source, self.source)

    def test_music_emits_notes_voices_and_timer_registers(self):
        result = self.sequencer().render("zMusic81Header", seconds=1)
        self.assertGreater(len(result.notes), 10)
        self.assertTrue(any(write.address == 0x24 for write in result.writes))
        self.assertTrue(any(write.address == 0x28 and write.value & 0xF0 == 0xF0 for write in result.writes))
        self.assertTrue(any(write.address == 0xB0 for write in result.writes))

    def test_ym2612_timer_periods_include_all_24_operators_and_prescale(self):
        self.assertAlmostEqual(
            timer_a_period_samples(0x00B4, 44_100),
            44_100 * 24 * 6 * (1024 - 0x00B4) / YM2612_CLOCK,
        )
        self.assertAlmostEqual(
            timer_b_period_samples(0xE6, 44_100),
            44_100 * 24 * 6 * 16 * (256 - 0xE6) / YM2612_CLOCK,
        )

    def test_title_music_trace_span_is_about_two_seconds(self):
        result = self.sequencer().render("zMusic85Header", seconds=4)
        audible = [
            write for write in result.writes
            if write.chip == "ym2612" and write.address not in {0x24, 0x25, 0x26, 0x27}
        ]
        span = (audible[2623].sample - audible[0].sample) / result.sample_rate
        self.assertGreater(span, 2.0)
        self.assertLess(span, 2.15)

    def test_sfx_advances_only_on_timer_b(self):
        result = self.sequencer().render("zSFX90Header", seconds=1)
        samples = sorted({write.sample for write in result.writes})
        self.assertGreater(len(samples), 1)
        self.assertEqual(samples[1], round(timer_b_period_samples(0xE6, 44_100)))

    def test_all_resident_headers_execute(self):
        sequencer = self.sequencer()
        for identifier in sequencer.headers:
            with self.subTest(identifier=identifier):
                result = sequencer.render(identifier, seconds=0.25)
                self.assertGreater(result.total_samples, 0)
                self.assertTrue(result.writes or result.notes)

    def test_channel_filter_removes_other_channel_writes(self):
        result = self.sequencer().render(
            "zMusic83Header", seconds=0.5, enabled_channels={1}
        )
        self.assertTrue(result.writes)
        self.assertEqual({write.channel for write in result.writes}, {1})
        self.assertTrue(all(note.track == 1 for note in result.notes if note.track == 1))

    def test_vgm_has_clocks_duration_and_end_command(self):
        result = self.sequencer().render("zSFX90Header", seconds=1)
        data = encode_vgm(result)
        self.assertEqual(data[:4], b"Vgm ")
        self.assertEqual(struct.unpack_from("<I", data, 4)[0], len(data) - 4)
        self.assertEqual(struct.unpack_from("<I", data, 0x18)[0], result.total_samples)
        self.assertIn(0x52, data[0x100:])
        self.assertEqual(data[-1], 0x66)

    @unittest.skipUnless(sys.platform == "win32", "vendored renderer is a Windows executable")
    def test_vendored_ymfm_renderer_writes_non_silent_stereo_wav(self):
        result = self.sequencer().render("zSFX90Header", seconds=0.25)
        renderer = ROOT / "bin/windows_i386/ymfm_renderer.exe"
        with tempfile.TemporaryDirectory() as directory:
            vgm_path = Path(directory) / "effect.vgm"
            wav_path = Path(directory) / "effect.wav"
            write_vgm(result, vgm_path)
            subprocess.run([renderer, vgm_path, wav_path], check=True, capture_output=True)
            with wave.open(str(wav_path), "rb") as sound:
                self.assertEqual(sound.getnchannels(), 2)
                self.assertEqual(sound.getsampwidth(), 2)
                samples = sound.readframes(sound.getnframes())
            self.assertTrue(any(samples))


if __name__ == "__main__":
    unittest.main()

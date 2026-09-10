import random
import unittest

from formats import enigma_dec, enigma_enc


def words(values: list[int]) -> bytes:
    return b"".join(value.to_bytes(2, "big") for value in values)


class EnigmaEncoder(unittest.TestCase):
    def round_trip(self, values: list[int]) -> bytes:
        plain = words(values)
        packed = enigma_enc.encode(plain)
        self.assertEqual(enigma_dec.decompress(packed), plain)
        return packed

    def test_incrementing_screen_fits_the_original_slot(self):
        packed = self.round_trip(list(range(48)))
        self.assertLessEqual(len(packed), 10)

    def test_static_and_explicit_runs(self):
        self.round_trip([7] * 20 + [3, 4, 5, 6] + [9] * 3)

    def test_arbitrary_words_round_trip(self):
        generator = random.Random(0xF11C)
        self.round_trip([generator.randrange(0x800) for _ in range(50)])

    def test_odd_input_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "whole big-endian words"):
            enigma_enc.encode(b"odd")


if __name__ == "__main__":
    unittest.main()

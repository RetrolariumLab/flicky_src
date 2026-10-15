import unittest

from scripts.validation.verify_relocation import ROM_SIZE, runnable


class RunnableImageTests(unittest.TestCase):
    def test_the_packed_image_is_padded_and_its_header_updated(self):
        packed = bytearray(0x300)
        packed[0x200:0x204] = bytes((0x12, 0x34, 0x00, 0x01))
        image = runnable(bytes(packed))
        self.assertEqual(ROM_SIZE, len(image))
        self.assertEqual(b"\xff" * (ROM_SIZE - 0x300), image[0x300:])
        self.assertEqual(ROM_SIZE - 1, int.from_bytes(image[0x1A4:0x1A8], "big"))
        expected = (0x1234 + 0x0001 + 0xFFFF * ((ROM_SIZE - 0x300) // 2)) & 0xFFFF
        self.assertEqual(expected, int.from_bytes(image[0x18E:0x190], "big"))

    def test_an_image_larger_than_the_cartridge_is_refused(self):
        with self.assertRaises(SystemExit):
            runnable(bytes(ROM_SIZE + 2))


if __name__ == "__main__":
    unittest.main()

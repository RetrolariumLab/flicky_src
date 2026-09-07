import struct
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from runtime import genstate  # noqa: E402


def build(sections: dict[int, bytes], magic: bytes = genstate.MAGIC, version: int = 1) -> bytes:
    """Assemble a dump in the layout state_dump.cpp writes."""
    header = bytearray(genstate.HEADER_SIZE)
    header[0:len(magic)] = magic
    struct.pack_into("<I", header, len(genstate.MAGIC), version)

    table_size = (len(sections) + 1) * genstate.SECTION_ENTRY.size
    offset = genstate.HEADER_SIZE + table_size
    table, payload = bytearray(), bytearray()
    for ident, blob in sections.items():
        table += genstate.SECTION_ENTRY.pack(ident, offset, len(blob), 0)
        payload += blob
        offset += len(blob)
    table += genstate.SECTION_ENTRY.pack(0, 0, 0, 0)
    return bytes(header + table + payload)


class Layout(unittest.TestCase):
    def test_sections_are_read_from_the_table(self):
        dump = build({genstate.SECTION_M68K_RAM: b"\x00" * 8, 0x10: b"\xFF" * 4})
        table = genstate.sections(dump)
        self.assertEqual(sorted(table), [genstate.SECTION_M68K_RAM, 0x10])
        offset, size = table[0x10]
        self.assertEqual(dump[offset:offset + size], b"\xFF" * 4)

    def test_a_foreign_file_is_rejected(self):
        with self.assertRaises(genstate.DumpError):
            genstate.sections(b"not a dump at all, just some bytes")

    def test_an_unknown_version_is_rejected(self):
        # Silently misreading a future layout would be worse than refusing it.
        with self.assertRaises(genstate.DumpError):
            genstate.sections(build({genstate.SECTION_M68K_RAM: b"\x00" * 4}, version=2))

    def test_a_truncated_section_is_rejected(self):
        dump = bytearray(build({genstate.SECTION_M68K_RAM: b"\x00" * 64}))
        with self.assertRaises(genstate.DumpError):
            genstate.sections(bytes(dump[:-32]))


class WorkRam(unittest.TestCase):
    def test_a_dump_without_work_ram_is_an_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "x.genstate"
            path.write_bytes(build({0x10: b"\x00" * 4}))
            with self.assertRaises(genstate.DumpError):
                genstate.work_ram(path)

    def test_work_ram_must_be_the_full_64_kib(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "x.genstate"
            path.write_bytes(build({genstate.SECTION_M68K_RAM: b"\x00" * 16}))
            with self.assertRaises(genstate.DumpError):
                genstate.work_ram(path)


class ByteOrder(unittest.TestCase):
    def setUp(self):
        # Gens stores work RAM as host-endian 16 bit words, so a dump holds the
        # two bytes of every word the other way round from the 68000's view.
        self.ram = bytearray(genstate.WORK_RAM_SIZE)
        self.ram[0xFFFC ^ 1] = ord("i")
        self.ram[0xFFFD ^ 1] = ord("n")
        self.ram[0xFFFE ^ 1] = ord("i")
        self.ram[0xFFFF ^ 1] = ord("t")

    def test_the_boot_marker_reads_back(self):
        value = genstate.read(bytes(self.ram), 0xFFFFFC, 4)
        self.assertEqual(value.to_bytes(4, "big"), b"init")

    def test_reading_without_the_swap_would_give_the_neighbour(self):
        # The failure mode this guards: unswapped, $FFFFFC reads "niti", which
        # looks like data rather than an error.
        raw = bytes(self.ram)[0xFFFC:0x10000]
        self.assertEqual(raw, b"niti")

    def test_byte_reads_pick_the_right_half_of_the_word(self):
        ram = bytearray(genstate.WORK_RAM_SIZE)
        ram[0xD882 ^ 1] = 3   # Ram_Lives
        ram[0xD883 ^ 1] = 6   # Ram_ChicksRemaining
        self.assertEqual(genstate.read(bytes(ram), 0xFFD882, 1), 3)
        self.assertEqual(genstate.read(bytes(ram), 0xFFD883, 1), 6)

    def test_addresses_outside_work_ram_are_rejected(self):
        for address in (0x000000, 0xFEFFFF, 0x100000):
            with self.assertRaises(genstate.DumpError):
                genstate.read(bytes(self.ram), address, 2)


if __name__ == "__main__":
    unittest.main()

/*
 * Nemesis Decompressor - C port from 68000
 * Based on clownnemesis by Clownacy and Sonic disassembly
 *
 * Compile (MinGW): gcc -O2 -shared -o nemesis_dec.dll nemesis_dec.c
 * Compile (MSVC):  cl /O2 /LD nemesis_dec.c
 * Test build:      gcc -O2 -DTEST_MAIN -o nemesis_dec.exe nemesis_dec.c
 *
 * Usage: int nemesis_decompress(const uint8_t* src, uint8_t* dst)
 * Returns: number of bytes written
 */

#include <stdint.h>
#include <string.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

/* Code table entry */
typedef struct {
    uint8_t code_length;  /* Number of bits in this code (1-8) */
    uint8_t nybble;       /* Output nybble value (0-15) */
    uint8_t run_length;   /* Number of times to output (1-8) */
    uint8_t valid;        /* 1 if entry is valid, 0 if not */
} CodeEntry;

/* Decompressor state */
typedef struct {
    const uint8_t* src;
    uint8_t* dst;
    uint16_t bit_buffer;
    int bits_remaining;
    int xor_mode;
    int output_count;      /* Number of 8-nybble groups to output */
    uint32_t nybble_buffer;
    int nybbles_in_buffer;
    uint32_t xor_buffer;
    CodeEntry code_table[256];
} NemesisState;

/* Read next byte from source */
static inline uint8_t read_byte(NemesisState* s) {
    return *s->src++;
}

/* Refill bit buffer */
static void refill_bits(NemesisState* s) {
    s->bit_buffer = (s->bit_buffer << 8) | read_byte(s);
    s->bits_remaining += 8;
}

/* Get N bits from buffer without consuming */
static uint16_t peek_bits(NemesisState* s, int count) {
    while (s->bits_remaining < count) {
        refill_bits(s);
    }
    int shift = s->bits_remaining - count;
    return (s->bit_buffer >> shift) & ((1 << count) - 1);
}

/* Consume N bits from buffer */
static void consume_bits(NemesisState* s, int count) {
    s->bits_remaining -= count;
}

/* Get N bits (peek + consume) */
static uint16_t get_bits(NemesisState* s, int count) {
    uint16_t val = peek_bits(s, count);
    consume_bits(s, count);
    return val;
}

/* Output a single nybble */
static int output_nybble(NemesisState* s, uint8_t nybble) {
    s->nybble_buffer = (s->nybble_buffer << 4) | (nybble & 0xF);
    s->nybbles_in_buffer++;

    if (s->nybbles_in_buffer == 8) {
        /* Write 4 bytes (8 nybbles = 32 bits) */
        uint32_t output = s->nybble_buffer;

        if (s->xor_mode) {
            output ^= s->xor_buffer;
            s->xor_buffer = output;
        }

        *s->dst++ = (output >> 24) & 0xFF;
        *s->dst++ = (output >> 16) & 0xFF;
        *s->dst++ = (output >> 8) & 0xFF;
        *s->dst++ = output & 0xFF;

        s->nybble_buffer = 0;
        s->nybbles_in_buffer = 0;
        s->output_count--;

        if (s->output_count == 0) {
            return 1;  /* Done */
        }
    }
    return 0;
}

/* Output N copies of a nybble */
static int output_nybbles(NemesisState* s, uint8_t nybble, int count) {
    for (int i = 0; i < count; i++) {
        if (output_nybble(s, nybble)) {
            return 1;
        }
    }
    return 0;
}

/* Build the code table from header data */
static void build_code_table(NemesisState* s) {
    memset(s->code_table, 0, sizeof(s->code_table));

    while (1) {
        uint8_t val = read_byte(s);
        if (val == 0xFF) {
            break;
        }

        uint8_t palette_index = val & 0x0F;

        while (1) {
            val = read_byte(s);

            if (val >= 0x80) {
                if (val == 0xFF) {
                    return;
                }
                /* New palette index */
                palette_index = val & 0x0F;
                continue;
            }

            /* Parse code entry */
            /* bits 6-4: repeat count - 1 (so 0-7 means 1-8) */
            /* bits 3-0: code length (0 means 8) */
            int run_length = ((val >> 4) & 7) + 1;
            int code_length = val & 0x0F;
            if (code_length == 0) {
                code_length = 8;
            }

            uint8_t code_byte = read_byte(s);

            /* Fill lookup table entries */
            /* For N-bit codes, fill 2^(8-N) consecutive entries */
            if (code_length < 8) {
                /* Short code: the code value is in the upper bits of code_byte */
                /* E.g., 3-bit code 5 is stored as byte value 5 */
                /* We need to fill entries where upper N bits match */
                int base = code_byte << (8 - code_length);
                int num_entries = 1 << (8 - code_length);

                for (int i = 0; i < num_entries; i++) {
                    int idx = base | i;
                    s->code_table[idx].code_length = code_length;
                    s->code_table[idx].nybble = palette_index;
                    s->code_table[idx].run_length = run_length;
                    s->code_table[idx].valid = 1;
                }
            } else {
                /* 8-bit code: single entry */
                s->code_table[code_byte].code_length = code_length;
                s->code_table[code_byte].nybble = palette_index;
                s->code_table[code_byte].run_length = run_length;
                s->code_table[code_byte].valid = 1;
            }
        }
    }
}

/* Process compressed data stream */
static void process_codes(NemesisState* s) {
    while (s->output_count > 0) {
        /* Peek 8 bits for table lookup */
        uint16_t lookup = peek_bits(s, 8);
        CodeEntry* entry = &s->code_table[lookup];

        if (entry->valid) {
            /* Found code in table */
            consume_bits(s, entry->code_length);
            if (output_nybbles(s, entry->nybble, entry->run_length)) {
                return;
            }
        } else if ((lookup >> 2) == 0x3F) {
            /* Inline mode: 6-bit marker 0x3F followed by 3-bit length and 4-bit nybble */
            consume_bits(s, 6);  /* Consume the 0x3F marker */
            int run_length = get_bits(s, 3) + 1;
            int nybble = get_bits(s, 4);
            if (output_nybbles(s, nybble, run_length)) {
                return;
            }
        } else {
            /* Unknown code - should not happen with valid data */
            /* Skip one bit and try again */
            consume_bits(s, 1);
        }
    }
}

/*
 * Main decompression function
 *
 * src: pointer to compressed data
 * dst: pointer to output buffer (must be large enough!)
 *
 * Returns: number of bytes written
 */
EXPORT int nemesis_decompress(const uint8_t* src, uint8_t* dst) {
    NemesisState s;
    uint8_t* dst_start = dst;

    s.src = src;
    s.dst = dst;
    s.bit_buffer = 0;
    s.bits_remaining = 0;
    s.nybble_buffer = 0;
    s.nybbles_in_buffer = 0;
    s.xor_buffer = 0;

    /* Read header: 2 bytes */
    /* High bit = XOR mode, lower 15 bits = number of TILES to output */
    /* Each tile = 8x8 pixels at 4bpp = 32 bytes = 8 groups of 8 nybbles */
    uint16_t header = (read_byte(&s) << 8) | read_byte(&s);
    s.xor_mode = (header & 0x8000) != 0;
    s.output_count = (header & 0x7FFF) * 8;  /* Convert tiles to 8-nybble groups */

    if (s.output_count == 0) {
        return 0;
    }

    /* Build code table */
    build_code_table(&s);

    /* Initialize bit buffer */
    refill_bits(&s);
    refill_bits(&s);

    /* Decompress */
    process_codes(&s);

    return (int)(s.dst - dst_start);
}

/* Test main for standalone compilation */
#ifdef TEST_MAIN
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    if (argc < 3) {
        printf("Usage: %s input.bin output.bin\n", argv[0]);
        return 1;
    }

    FILE* f = fopen(argv[1], "rb");
    if (!f) {
        printf("Cannot open %s\n", argv[1]);
        return 1;
    }

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    uint8_t* src = malloc(size);
    fread(src, 1, size, f);
    fclose(f);

    /* Allocate generous output buffer */
    uint8_t* dst = malloc(1024 * 1024);  /* 1MB should be enough */

    int out_size = nemesis_decompress(src, dst);

    int tiles = ((src[0] & 0x7F) << 8) | src[1];
    printf("Decompressed %ld -> %d bytes (%d tiles)\n", size, out_size, tiles);
    printf("Header: xor=%d, tiles=%d\n", (src[0] & 0x80) != 0, tiles);

    f = fopen(argv[2], "wb");
    fwrite(dst, 1, out_size, f);
    fclose(f);

    free(src);
    free(dst);
    return 0;
}
#endif

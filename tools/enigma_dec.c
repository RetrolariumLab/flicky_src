/*
 * Enigma Decompressor - C port from 68000
 * Original: Flicky (Genesis) / Sonic disassembly
 *
 * Compile (MinGW): gcc -O2 -shared -o enigma_dec.dll enigma_dec.c
 * Compile (MSVC):  cl /O2 /LD enigma_dec.c
 *
 * Usage: int enigma_decompress(const uint8_t* src, uint8_t* dst, uint16_t base_tile)
 * Returns: number of bytes written
 */

#include <stdint.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

/* Bit masks table */
static const uint16_t bit_masks[16] = {
    0x0001, 0x0003, 0x0007, 0x000F,
    0x001F, 0x003F, 0x007F, 0x00FF,
    0x01FF, 0x03FF, 0x07FF, 0x0FFF,
    0x1FFF, 0x3FFF, 0x7FFF, 0xFFFF
};

/* Decompressor state */
typedef struct {
    const uint8_t* src;      /* a0: source pointer */
    uint8_t* dst;            /* a1: destination pointer */
    uint16_t inc_tile;       /* a2: incrementing tile */
    uint16_t base_tile;      /* a3: base tile flags */
    uint16_t static_tile;    /* a4: static tile */
    int16_t bits_count;      /* a5: bits per inline tile (signed!) */
    uint16_t bit_buffer;     /* d5: bit buffer */
    int16_t bits_remaining;  /* d6: bits remaining in buffer */
    uint32_t flags;          /* d4: vflip/hflip flags */
} EnigmaState;

/* Read big-endian word */
static inline uint16_t read_word(const uint8_t** p) {
    uint16_t val = (*p)[0] << 8 | (*p)[1];
    *p += 2;
    return val;
}

/* Write big-endian word */
static inline void write_word(uint8_t** p, uint16_t val) {
    (*p)[0] = val >> 8;
    (*p)[1] = val & 0xFF;
    *p += 2;
}

/* Nem_GetCodeWord: read 2 bytes into bit buffer, reset count to 16 */
static void get_code_word(EnigmaState* s) {
    s->bit_buffer = (s->src[0] << 8) | s->src[1];
    s->src += 2;
    s->bits_remaining = 16;
}

/* Nem_GetBits: extract N bits from buffer (doesn't consume them) */
static uint16_t get_bits(EnigmaState* s, int count) {
    int shift = s->bits_remaining - count;
    uint16_t val = s->bit_buffer >> shift;
    return val & bit_masks[count - 1];
}

/* Nem_PCD_InlineData: consume N bits, refill if needed */
static void consume_bits(EnigmaState* s, int count) {
    s->bits_remaining -= count;
    if (s->bits_remaining < 9) {
        s->bits_remaining += 8;
        s->bit_buffer = (s->bit_buffer << 8) | *s->src++;
    }
}

/* Eni_DecodeTile: decode inline tile value with flags */
static uint16_t decode_tile(EnigmaState* s) {
    uint16_t tile = s->base_tile;

    /* Check vflip flag (bit 31 of d4) */
    if (s->flags & 0x80000000) {
        s->bits_remaining--;
        if (s->bit_buffer & (1 << s->bits_remaining)) {
            tile |= 0x1000;  /* Set vflip bit */
        }
    }

    /* Check hflip flag (bit 15 of d4) */
    if (s->flags & 0x8000) {
        s->bits_remaining--;
        if (s->bit_buffer & (1 << s->bits_remaining)) {
            tile |= 0x0800;  /* Set hflip bit */
        }
    }

    /* Read tile index bits */
    int bits = s->bits_count;
    if (bits == 0) {
        return tile;
    }

    /* Handle signed bits_count (can be negative!) */
    if (bits < 0) {
        bits = -bits;
    }

    int shift = s->bits_remaining - bits;

    if (shift > 0) {
        /* Enough bits in buffer */
        uint16_t val = (s->bit_buffer >> shift) & bit_masks[bits - 1];
        tile += val;
        consume_bits(s, bits);
    } else if (shift == 0) {
        /* Exact number of bits */
        uint16_t val = s->bit_buffer & bit_masks[bits - 1];
        tile += val;
        get_code_word(s);
    } else {
        /* Need more bits from next byte */
        int need = -shift;
        uint16_t val = s->bit_buffer << need;

        /* Read bits from next byte */
        uint8_t next = *s->src;
        val |= (next >> (8 - need)) & bit_masks[need - 1];
        val &= bit_masks[bits - 1];
        tile += val;

        /* Update buffer state */
        s->bits_remaining = 16 + shift;  /* 16 - need */
        s->bit_buffer = (s->src[0] << 8) | s->src[1];
        s->src += 2;
    }

    return tile;
}

/*
 * Main decompression function
 *
 * src: pointer to compressed data
 * dst: pointer to output buffer (must be large enough!)
 * base_tile: base tile value to add to all tiles
 *
 * Returns: number of bytes written
 */
EXPORT int enigma_decompress(const uint8_t* src, uint8_t* dst, uint16_t base_tile) {
    EnigmaState s;
    uint8_t* dst_start = dst;

    s.src = src;
    s.dst = dst;
    s.base_tile = base_tile;

    /* Read header byte 1: bits per inline tile (signed!) */
    s.bits_count = (int8_t)*s.src++;

    /* Read header byte 2: flags */
    /* 68000 does: ext.w, ext.l, ror.l #1, ror.w #1 */
    /* This puts original bit 0 -> bit 31 (vflip), bit 1 -> bit 15 (hflip) */
    int8_t flags_byte = (int8_t)*s.src++;
    uint32_t flags = (int32_t)flags_byte;  /* sign extend to 32 bits */
    /* ror.l #1: bit 0 -> bit 31 */
    flags = (flags >> 1) | ((flags & 1) << 31);
    /* ror.w #1: bit 0 of low word -> bit 15 of low word */
    uint16_t low = flags & 0xFFFF;
    low = (low >> 1) | ((low & 1) << 15);
    s.flags = (flags & 0xFFFF0000) | low;

    /* Read inc_tile and add base */
    s.inc_tile = read_word(&s.src) + base_tile;

    /* Read static_tile and add base */
    s.static_tile = read_word(&s.src) + base_tile;

    /* Initialize bit buffer */
    get_code_word(&s);

    /* Main decompression loop */
    while (1) {
        /* Read format bit and mode/repeat */
        uint16_t code = get_bits(&s, 7);
        uint16_t repeat = code;
        int bits_used = 7;

        if (code < 0x40) {
            /* Short format: 6 bits */
            bits_used = 6;
            repeat >>= 1;
        }

        consume_bits(&s, bits_used);

        int mode = (repeat >> 4) & 0x07;
        repeat &= 0x0F;

        switch (mode) {
            case 0:
            case 1:
                /* Write incrementing from inc_tile */
                for (int i = 0; i <= repeat; i++) {
                    write_word(&dst, s.inc_tile++);
                }
                break;

            case 2:
            case 3:
                /* Write static_tile repeated */
                for (int i = 0; i <= repeat; i++) {
                    write_word(&dst, s.static_tile);
                }
                break;

            case 4: {
                /* Decode tile and write repeated */
                uint16_t tile = decode_tile(&s);
                for (int i = 0; i <= repeat; i++) {
                    write_word(&dst, tile);
                }
                break;
            }

            case 5: {
                /* Decode tile and write incrementing */
                uint16_t tile = decode_tile(&s);
                for (int i = 0; i <= repeat; i++) {
                    write_word(&dst, tile++);
                }
                break;
            }

            case 6: {
                /* Decode tile and write decrementing */
                uint16_t tile = decode_tile(&s);
                for (int i = 0; i <= repeat; i++) {
                    write_word(&dst, tile--);
                }
                break;
            }

            case 7:
                /* Inline mode or end marker */
                if (repeat == 0x0F) {
                    /* End marker - return bytes written */
                    return (int)(dst - dst_start);
                }
                /* Decode tiles inline */
                for (int i = 0; i <= repeat; i++) {
                    uint16_t tile = decode_tile(&s);
                    write_word(&dst, tile);
                }
                break;
        }
    }

    return (int)(dst - dst_start);
}

/* Test main for standalone compilation */
#ifdef TEST_MAIN
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    if (argc < 3) {
        printf("Usage: %s input.bin output.bin [base_tile] [skip_bytes]\n", argv[0]);
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

    uint8_t* dst = malloc(65536);  /* 64KB should be enough */
    uint16_t base = argc > 3 ? strtol(argv[3], NULL, 0) : 0;
    int skip = argc > 4 ? atoi(argv[4]) : 0;

    if (skip >= size) {
        printf("Skip offset %d >= file size %ld\n", skip, size);
        return 1;
    }

    int out_size = enigma_decompress(src + skip, dst, base);

    printf("Decompressed %ld -> %d bytes (skipped %d)\n", size - skip, out_size, skip);

    f = fopen(argv[2], "wb");
    fwrite(dst, 1, out_size, f);
    fclose(f);

    free(src);
    free(dst);
    return 0;
}
#endif

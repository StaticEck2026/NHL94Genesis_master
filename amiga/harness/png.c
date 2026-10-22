/* PNG files for the test harness: RGB, 8 bits a channel, no filtering. */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <zlib.h>
#include "png.h"

static void put32(uint8_t *p, uint32_t v) { p[0] = v >> 24; p[1] = v >> 16; p[2] = v >> 8; p[3] = v; }

static void chunk(FILE *f, const char *type, const uint8_t *data, uint32_t len)
{
    uint8_t h[8];
    put32(h, len);
    memcpy(h + 4, type, 4);
    fwrite(h, 1, 8, f);
    if (len) fwrite(data, 1, len, f);
    uint32_t crc = crc32(0, (const uint8_t *)type, 4);
    if (len) crc = crc32(crc, data, len);
    put32(h, crc);
    fwrite(h, 1, 4, f);
}

int png_write(const char *name, const uint8_t *rgb, int w, int h)
{
    FILE *f = fopen(name, "wb");
    if (!f) return -1;
    static const uint8_t sig[8] = {137, 80, 78, 71, 13, 10, 26, 10};
    fwrite(sig, 1, 8, f);
    uint8_t ihdr[13];
    put32(ihdr, w);
    put32(ihdr + 4, h);
    ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
    chunk(f, "IHDR", ihdr, 13);
    uLongf rawlen = (uLongf)(w * 3 + 1) * h;
    static uint8_t raw[(1024 * 3 + 1) * 1024], z[(1024 * 3 + 1) * 1024 + 4096];
    for (int y = 0; y < h; y++) {
        raw[y * (w * 3 + 1)] = 0;
        memcpy(raw + y * (w * 3 + 1) + 1, rgb + y * w * 3, w * 3);
    }
    uLongf zl = sizeof z;
    compress(z, &zl, raw, rawlen);
    chunk(f, "IDAT", z, zl);
    chunk(f, "IEND", NULL, 0);
    fclose(f);
    return 0;
}

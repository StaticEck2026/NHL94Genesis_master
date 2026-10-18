/*
 * Reference Genesis VDP renderer for the test harness: draws planes A and B, the window and the
 * sprites from the emulated VDP memories, with priorities, and writes a PNG. It is the yardstick
 * for the Amiga renderer (amiga/src/render.asm).
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <zlib.h>
#include "vdpref.h"

static const uint8_t *R, *V, *C, *VS;

static int rw(const uint8_t *p, int a) { return (p[a] << 8) | p[a + 1]; }

/* One pixel of a tile: returns colour 0-15. */
static int tilepix(int tile, int x, int y)
{
    int a = ((tile & 0x7FF) * 32 + y * 4 + (x >> 1)) & 0xFFFF;
    int b = V[a];
    return (x & 1) ? (b & 15) : (b >> 4);
}

int vdpref_render(uint8_t *out, int *pw, int *ph, const uint8_t *regs, const uint8_t *vram,
                  const uint8_t *cram, const uint8_t *vsram)
{
    R = regs; V = vram; C = cram; VS = vsram;
    int h40 = (R[12] & 0x81) != 0;
    int W = h40 ? 320 : 256, H = 224;
    *pw = W; *ph = H;
    int display = R[1] & 0x40;
    int pa = (R[2] & 0x38) << 10, pb = (R[4] & 7) << 13;
    int pw_ = (R[3] & (h40 ? 0x3C : 0x3E)) << 10;
    int sat = (R[5] & (h40 ? 0x7E : 0x7F)) << 9;
    int hsb = (R[13] & 0x3F) << 10;
    int hsmode = R[11] & 3, vsmode = (R[11] >> 2) & 1;
    static const int sz[4] = {32, 64, 32, 128};
    int cw = sz[R[16] & 3], ch = sz[(R[16] >> 4) & 3];
    int winh = R[17], winv = R[18];
    int wincw = h40 ? 64 : 32;
    int bg = R[7] & 0x3F;

    static uint8_t line[320];
    static uint8_t spr[320];
    for (int y = 0; y < H; y++) {
        /* layers: index = pal*16+col, plus priority flag in bit 6, 0 = transparent */
        uint8_t la[320], lb[320];
        int hsoff;
        if (hsmode == 0) hsoff = 0;
        else if (hsmode == 2) hsoff = (y & ~7) * 4;
        else hsoff = y * 4;
        int hsa = rw(V, (hsb + hsoff) & 0xFFFF) & 0x3FF, hsbv = rw(V, (hsb + hsoff + 2) & 0xFFFF) & 0x3FF;
        for (int pl = 0; pl < 2; pl++) {
            int base = pl ? pb : pa;
            int hs = pl ? hsbv : hsa;
            uint8_t *l = pl ? lb : la;
            for (int x = 0; x < W; x++) {
                int col = vsmode ? (x >> 4) : 0;
                int vs = rw(VS, (col * 4 + pl * 2) & 0x7F) & 0x3FF;
                int px = (x - hs) & (cw * 8 - 1);
                int py = (y + vs) & (ch * 8 - 1);
                int e = rw(V, (base + ((py >> 3) * cw + (px >> 3)) * 2) & 0xFFFF);
                int tx = px & 7, ty = py & 7;
                if (e & 0x800) tx = 7 - tx;
                if (e & 0x1000) ty = 7 - ty;
                int c = tilepix(e, tx, ty);
                l[x] = c ? (uint8_t)(((e >> 13) & 3) * 16 + c) | ((e & 0x8000) ? 0x80 : 0) : 0;
            }
        }
        /* window replaces plane A */
        int inwin_v = (winv & 0x80) ? (y >= (winv & 0x1F) * 8) : (y < (winv & 0x1F) * 8);
        for (int x = 0; x < W; x++) {
            int inwin_h = (winh & 0x80) ? (x >= (winh & 0x1F) * 16) : (x < (winh & 0x1F) * 16);
            if (inwin_v || inwin_h) {
                if (!(inwin_v) && !(winh & 0x1F) && !(winh & 0x80)) continue;
                int e = rw(V, (pw_ + ((y >> 3) * wincw + (x >> 3)) * 2) & 0xFFFF);
                int tx = x & 7, ty = y & 7;
                if (e & 0x800) tx = 7 - tx;
                if (e & 0x1000) ty = 7 - ty;
                int c = tilepix(e, tx, ty);
                la[x] = c ? (uint8_t)(((e >> 13) & 3) * 16 + c) | ((e & 0x8000) ? 0x80 : 0) : 0;
            }
        }
        /* sprites */
        memset(spr, 0, sizeof spr);
        int maxspr = h40 ? 80 : 64, n = 0, link = 0;
        do {
            int a = (sat + link * 8) & 0xFFFF;
            int sy = (rw(V, a) & 0x3FF) - 128;
            int s = V[a + 2];
            int hs_ = ((s >> 2) & 3) + 1, vs_ = (s & 3) + 1;
            int at = rw(V, a + 4);
            int sx = (rw(V, a + 6) & 0x1FF) - 128;
            link = V[a + 3] & 0x7F;
            if (y >= sy && y < sy + vs_ * 8) {
                int ry = y - sy;
                if (at & 0x1000) ry = vs_ * 8 - 1 - ry;
                for (int xx = 0; xx < hs_ * 8; xx++) {
                    int x = sx + xx;
                    if (x < 0 || x >= W || spr[x]) continue;
                    int rx = xx;
                    if (at & 0x800) rx = hs_ * 8 - 1 - rx;
                    int tile = (at & 0x7FF) + (rx >> 3) * vs_ + (ry >> 3);
                    int c = tilepix(tile, rx & 7, ry & 7);
                    if (c) spr[x] = (uint8_t)(((at >> 13) & 3) * 16 + c) | ((at & 0x8000) ? 0x80 : 0);
                }
            }
            n++;
        } while (link && n < maxspr);
        for (int x = 0; x < W; x++) {
            int c = bg, a = la[x], b = lb[x], s = spr[x];
            if (b && !(b & 0x80)) c = b;
            if (a && !(a & 0x80)) c = a;
            if (s && !(s & 0x80)) c = s;
            if (b & 0x80) c = b;
            if (a & 0x80) c = a;
            if (s & 0x80) c = s;
            line[x] = c & 0x3F;
        }
        for (int x = 0; x < W; x++) {
            int col = display ? rw(C, line[x] * 2) : 0;
            uint8_t *o = out + (y * W + x) * 3;
            o[0] = ((col >> 1) & 7) * 255 / 7;
            o[1] = ((col >> 5) & 7) * 255 / 7;
            o[2] = ((col >> 9) & 7) * 255 / 7;
        }
    }
    return 0;
}

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
    static uint8_t raw[(320 * 2 * 3 + 1) * 480], z[(320 * 2 * 3 + 1) * 480 + 1024];
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

int vdpref_png(const char *name, const uint8_t *regs, const uint8_t *vram, const uint8_t *cram,
               const uint8_t *vsram)
{
    static uint8_t rgb[320 * 240 * 3];
    int w, h;
    vdpref_render(rgb, &w, &h, regs, vram, cram, vsram);
    return png_write(name, rgb, w, h);
}

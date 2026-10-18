/*
 * nhlrun: run the Amiga build of NHL 94 on Linux for testing.
 *
 * A Musashi 68020 core runs the hunk executable with just enough of the Amiga around it for the
 * hardware layer: the CIA-B timer interrupt (the Genesis vblank, level 6), the beam counter and
 * the custom chip writes. The emulated VDP memories are drawn with a reference Genesis renderer
 * (vdpref.c) and saved as PNG, so screens can be checked without an Amiga emulator.
 *
 * nhlrun [options] nhl94.game
 *   -f N          run N frames (default 600)
 *   -s a,b,c      save shot_<frame>.png at these frames
 *   -S N          save a shot every N frames
 *   -p F:MASK,..  from frame F hold pad bits MASK (hex, pad2<<8|pad1, active high:
 *                 1 up 2 down 4 left 8 right 10 B 20 C 40 A 80 Start)
 *   -o DIR        output directory (default .)
 *   -c CYCLES     CPU cycles per frame (default 233000, a 14 MHz 68020 at 60 Hz)
 *   -r FILE       also dump the raw VDP state at the end (regs, vram, cram, vsram)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "m68k.h"
#include "vdpref.h"

#define MEMSIZE 0x1000000
static uint8_t *mem;
static int irq6_pending;
static long long cycles_total;
static int red_screen;
static uint32_t dbg;            /* debug block address */
static int frame;

static inline uint32_t rd8(uint32_t a) { a &= 0xFFFFFF; return mem[a]; }
static inline uint32_t rd16(uint32_t a) { a &= 0xFFFFFF; return (mem[a] << 8) | mem[a + 1]; }
static inline uint32_t rd32(uint32_t a) { return (rd16(a) << 16) | rd16(a + 2); }
static inline void wr8(uint32_t a, uint32_t v) { a &= 0xFFFFFF; mem[a] = v; }
static inline void wr16(uint32_t a, uint32_t v) { a &= 0xFFFFFF; mem[a] = v >> 8; mem[a + 1] = v; }
static inline void wr32(uint32_t a, uint32_t v) { wr16(a, v >> 16); wr16(a + 2, v); }

static uint32_t custom_read(uint32_t a, int size)
{
    uint32_t off = a & 0xFFE;
    if (off == 0x006) {             /* VHPOSR */
        long long c = cycles_total + m68k_cycles_run();
        uint32_t line = (c / 455) % 262, h = (c / 2) % 227;
        return ((line & 0xFF) << 8) | (h & 0xFF);
    }
    if (off == 0x004) return 0;    /* VPOSR */
    (void)size;
    return 0;
}

static void custom_write(uint32_t a, uint32_t v)
{
    uint32_t off = a & 0xFFE;
    if (off == 0x180 && v == 0xF00) red_screen = 1;
}

static uint32_t io_read(uint32_t a, int size)
{
    if ((a & 0xFFFFFF00) == 0xBFDD00 || (a & 0xFFFF00) == 0xBFDD00) {   /* CIA-B ICR */
        int v = irq6_pending ? 0x81 : 0;
        irq6_pending = 0;
        m68k_set_irq(0);
        return v;
    }
    if (a >= 0xDFF000 && a < 0xE00000) return custom_read(a, size);
    return 0;
}

static int is_io(uint32_t a) { a &= 0xFFFFFF; return (a >= 0xBF0000 && a < 0xC00000) || (a >= 0xDFF000 && a < 0xE00000); }

unsigned int m68k_read_memory_8(unsigned int a) { if (is_io(a)) return io_read(a & 0xFFFFFF, 1) & 0xFF; return rd8(a); }
unsigned int m68k_read_memory_16(unsigned int a) { if (is_io(a)) return io_read(a & 0xFFFFFF, 2) & 0xFFFF; return rd16(a); }
unsigned int m68k_read_memory_32(unsigned int a) { if (is_io(a)) return (io_read(a & 0xFFFFFF, 2) << 16) | io_read((a + 2) & 0xFFFFFF, 2); return rd32(a); }
unsigned int m68k_read_disassembler_8(unsigned int a) { return rd8(a); }
unsigned int m68k_read_disassembler_16(unsigned int a) { return rd16(a); }
unsigned int m68k_read_disassembler_32(unsigned int a) { return rd32(a); }
void m68k_write_memory_8(unsigned int a, unsigned int v) { if (is_io(a)) { if ((a & 0xFFFFFF) >= 0xDFF000) custom_write(a & 0xFFFFFF, v); return; } wr8(a, v); }
void m68k_write_memory_16(unsigned int a, unsigned int v) { if (is_io(a)) { if ((a & 0xFFFFFF) >= 0xDFF000) custom_write(a & 0xFFFFFF, v); return; } wr16(a, v); }
void m68k_write_memory_32(unsigned int a, unsigned int v) { if (is_io(a)) { m68k_write_memory_16(a, v >> 16); m68k_write_memory_16(a + 2, v & 0xFFFF); return; } wr32(a, v); }

/* ---- hunk loader ---- */
static uint32_t be32(const uint8_t *p) { return (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]; }

static uint32_t load_hunks(const char *path)
{
    FILE *f = fopen(path, "rb");
    if (!f) { perror(path); exit(1); }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *b = malloc(n);
    if (fread(b, 1, n, f) != (size_t)n) { perror("read"); exit(1); }
    fclose(f);
    const uint8_t *p = b;
    if (be32(p) != 0x3F3) { fprintf(stderr, "not a hunk executable\n"); exit(1); }
    p += 4;
    while (be32(p)) p += 4 + 4 * be32(p);        /* resident library names */
    p += 4;
    uint32_t table = be32(p), first = be32(p + 4), last = be32(p + 8);
    (void)table;
    p += 12;
    int nh = last - first + 1;
    uint32_t base[64], addr = 0x200000;
    for (int i = 0; i < nh; i++) {
        uint32_t sz = (be32(p) & 0x3FFFFFFF) * 4;
        base[i] = addr;
        addr = (addr + sz + 0x1000) & ~0xFFF;
        p += 4;
    }
    int h = 0;
    while (p < b + n && h < nh) {
        uint32_t t = be32(p) & 0x3FFFFFFF;
        p += 4;
        if (t == 0x3E9 || t == 0x3EA) {       /* CODE / DATA */
            uint32_t len = be32(p) * 4;
            p += 4;
            memcpy(mem + base[h], p, len);
            p += len;
        } else if (t == 0x3EB) {              /* BSS */
            p += 4;
        } else if (t == 0x3EC) {              /* RELOC32 */
            for (;;) {
                uint32_t cnt = be32(p);
                p += 4;
                if (!cnt) break;
                uint32_t target = be32(p);
                p += 4;
                for (uint32_t k = 0; k < cnt; k++) {
                    uint32_t off = be32(p);
                    p += 4;
                    wr32(base[h] + off, rd32(base[h] + off) + base[target]);
                }
            }
        } else if (t == 0x3F7 || t == 0x3FC) { /* RELOC32SHORT: 16-bit words, long aligned */
            const uint8_t *q = p;
            for (;;) {
                uint32_t cnt = (q[0] << 8) | q[1];
                q += 2;
                if (!cnt) break;
                uint32_t target = (q[0] << 8) | q[1];
                q += 2;
                for (uint32_t k = 0; k < cnt; k++) {
                    uint32_t off = (q[0] << 8) | q[1];
                    q += 2;
                    wr32(base[h] + off, rd32(base[h] + off) + base[target]);
                }
            }
            p = b + ((q - b + 3) & ~3);
        } else if (t == 0x3F0) {              /* SYMBOL */
            for (;;) {
                uint32_t l = be32(p);
                p += 4;
                if (!l) break;
                p += l * 4 + 4;
            }
        } else if (t == 0x3F1) {              /* DEBUG */
            p += 4 + be32(p) * 4;
        } else if (t == 0x3F2) {              /* END */
            h++;
        } else {
            fprintf(stderr, "unknown hunk type %x\n", t);
            exit(1);
        }
    }
    free(b);
    fprintf(stderr, "loaded %d hunks, code at %06x, top %06x\n", nh, base[0], addr);
    return base[0];
}

/* ---- pad schedule ---- */
static int npad;
static struct { int frame; int mask; } padsched[256];

static void parse_pads(const char *s)
{
    while (*s && npad < 256) {
        int f, m;
        if (sscanf(s, "%d:%x", &f, &m) != 2) break;
        padsched[npad].frame = f;
        padsched[npad].mask = m;
        npad++;
        s = strchr(s, ',');
        if (!s) break;
        s++;
    }
}

static int pad_at(int fr)
{
    int m = 0;
    for (int i = 0; i < npad; i++)
        if (padsched[i].frame <= fr) m = padsched[i].mask;
    return m;
}

static void dump_exception(void)
{
    uint32_t exc = rd32(dbg + 16);
    fprintf(stderr, "EXCEPTION at frame %d: sr/pc %08x %08x %08x %08x\n", frame,
            rd32(exc), rd32(exc + 4), rd32(exc + 8), rd32(exc + 12));
    uint32_t regs = exc + 16;
    for (int i = 0; i < 16; i++)
        fprintf(stderr, "%c%d=%08x%s", i < 8 ? 'd' : 'a', i & 7, rd32(regs + 4 * i), (i & 7) == 7 ? "\n" : " ");
}

int main(int argc, char **argv)
{
    int frames = 600, every = 0, ncyc = 233000;
    const char *outdir = ".", *exe = NULL, *rawfile = NULL;
    int shots[256], nshots = 0;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-f")) frames = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-S")) every = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-c")) ncyc = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-o")) outdir = argv[++i];
        else if (!strcmp(argv[i], "-r")) rawfile = argv[++i];
        else if (!strcmp(argv[i], "-p")) parse_pads(argv[++i]);
        else if (!strcmp(argv[i], "-s")) {
            char *s = argv[++i];
            while (*s && nshots < 256) {
                shots[nshots++] = atoi(s);
                s = strchr(s, ',');
                if (!s) break;
                s++;
            }
        } else exe = argv[i];
    }
    if (!exe) { fprintf(stderr, "usage: nhlrun [options] nhl94.game\n"); return 1; }
    mem = calloc(1, MEMSIZE + 16);
    uint32_t code = load_hunks(exe);
    if (rd32(code + 4) != 0x4E483934) { fprintf(stderr, "no NH94 header\n"); return 1; }
    uint32_t entry = rd32(code + 8);
    dbg = rd32(code + 12);
    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68020);
    wr32(0, 0x1000);
    wr32(4, entry);
    m68k_pulse_reset();
    m68k_set_reg(M68K_REG_PC, entry);
    m68k_set_reg(M68K_REG_SR, 0x2700);
    m68k_set_reg(M68K_REG_SP, 0x1000);
    uint32_t vdpregs = rd32(dbg), vram = rd32(dbg + 4), cram = rd32(dbg + 8), vsram = rd32(dbg + 12);
    uint32_t padstate = rd32(dbg + 24);
    for (frame = 1; frame <= frames; frame++) {
        wr16(padstate, pad_at(frame));
        cycles_total += m68k_execute(ncyc);
        if (red_screen) { dump_exception(); break; }
        irq6_pending = 1;
        m68k_set_irq(6);
        int shot = every && frame % every == 0;
        for (int k = 0; k < nshots; k++) if (shots[k] == frame) shot = 1;
        if (shot) {
            char name[512];
            snprintf(name, sizeof name, "%s/shot_%05d.png", outdir, frame);
            vdpref_png(name, mem + (vdpregs & 0xFFFFFF), mem + (vram & 0xFFFFFF), mem + (cram & 0xFFFFFF),
                       mem + (vsram & 0xFFFFFF));
        }
    }
    fprintf(stderr, "stopped at frame %d, pc=%06x sr=%04x\n", frame, m68k_get_reg(NULL, M68K_REG_PC),
            m68k_get_reg(NULL, M68K_REG_SR));
    if (rawfile) {
        FILE *f = fopen(rawfile, "wb");
        fwrite(mem + (vdpregs & 0xFFFFFF), 1, 32, f);
        fwrite(mem + (vram & 0xFFFFFF), 1, 0x10000, f);
        fwrite(mem + (cram & 0xFFFFFF), 1, 128, f);
        fwrite(mem + (vsram & 0xFFFFFF), 1, 80, f);
        fclose(f);
    }
    return red_screen ? 2 : 0;
}

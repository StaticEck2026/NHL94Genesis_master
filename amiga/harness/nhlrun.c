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
static int det;                         /* NHL_DETERM (below) */
static long long blit_busy_until;
static int intena, blit_irq, blit_end_pending, vb_irq;
static int intreq_lo;           /* INTREQ bits 0-4 (TBE, DSKBLK, SOFT, PORTS, COPER): set by the
                                   copper (the blit queue's state) and the CPU */
long long blitstat[4];   /* the blitter's level 3 interrupt */

static void update_irq(void)
{
    int level = 0;
    if (blit_irq && (intena & 0x4040) == 0x4040) level = 3;
    if (vb_irq && (intena & 0x4020) == 0x4020) level = 3;   /* vertical blank, once a frame */
    if ((intreq_lo & 0x10) && (intena & 0x4010) == 0x4010) level = 3;   /* COPER */
    if (irq6_pending && (intena & 0x6000) == 0x6000) level = 6;   /* EXTER (held while off) */
    m68k_set_irq(level);
}
static long long cycles_total;
static long long vb_cycles;     /* cycles_total at the last vertical blank */
static int red_screen;
static uint32_t dbg;            /* debug block address */
static int frame;

static inline uint32_t rd8(uint32_t a) { a &= 0xFFFFFF; return mem[a]; }
static inline uint32_t rd16(uint32_t a) { a &= 0xFFFFFF; return (mem[a] << 8) | mem[a + 1]; }
static inline uint32_t rd32(uint32_t a) { return (rd16(a) << 16) | rd16(a + 2); }
static uint32_t watch_addr = 0xFFFFFFFF;   /* NHL_WATCH=address: report changes of that word */
static int in_blit;
static void watch_hit(uint32_t a, uint32_t v);
static uint32_t vw_lo = 0xFFFFFFFF, vw_hi;     /* NHL_VWLOG=lo:hi (VRAM offsets): CPU writes there */
static struct { uint32_t pc, n, ch, lo, hi; } vw[64];
static int vwn;
static void vw_hit(uint32_t a, uint32_t v);
static inline void wr8(uint32_t a, uint32_t v)
{
    a &= 0xFFFFFF;
    if (a >= vw_lo && a < vw_hi) vw_hit(a, v);
    if ((a & ~1u) == watch_addr && mem[a] != (uint8_t)v) watch_hit(a, v);
    mem[a] = v;
}
static inline void wr16(uint32_t a, uint32_t v) { wr8(a, v >> 8); wr8(a + 1, v); }
static inline void wr32(uint32_t a, uint32_t v) { wr16(a, v >> 16); wr16(a + 2, v); }
/* NHL_HAZARD=n: report (up to n) blits that read a word the CPU wrote after the blit was queued
   (the copper's move that started it written): what a blit reads must stay as it was until it
   has run, a vertical blank's restart of the queue included */
static int hazard = -1, hazard_n;
static uint32_t *wtime, *wpc;           /* per word: the CPU's last write (cycles / 16), its pc */
static uint32_t cop_insn;               /* the copper's move being done */
static uint32_t pend_qtime, pend_qpc;   /* the blit's queue time, the pc that queued it */

static uint32_t custom_read(uint32_t a, int size)
{
    uint32_t off = a & 0xFFE;
    if (off == 0x006 && (det || getenv("NHL_FIXEDHV")) && dbg && m68k_get_reg(NULL, M68K_REG_PPC) >= rd32(dbg + 112) &&
        m68k_get_reg(NULL, M68K_REG_PPC) < rd32(dbg + 168)) {
        /* the game's reads (its "random" numbers): the same every run and every build, from
           the frame and the read's number in it (our own timing loops read the beam) */
        static uint32_t reads; static int rframe;
        if (rframe != frame) { rframe = frame; reads = 0; }
        reads++;
        uint32_t h = (uint32_t)frame * 2654435761u ^ reads * 40503u;
        h ^= h >> 13; h *= 2246822519u; h ^= h >> 16;
        return h & 0xFFFF;
    }
    if (off == 0x006 || off == 0x004) {     /* VHPOSR, VPOSR (V8): lines from the last vertical blank */
        long long c = cycles_total + m68k_cycles_run() - vb_cycles;
        uint32_t line = (c / 455) % 262, h = (c / 2) % 227;
        return off == 0x004 ? (line >> 8) & 1 : ((line & 0xFF) << 8) | (h & 0xFF);
    }
    if (off == 0x01C) return intena;
    if (off == 0x01E) return (blit_irq ? 0x40 : 0) | (vb_irq ? 0x20 : 0) | intreq_lo;
    if (off == 0x002) {             /* DMACONR: blitter busy while a blit runs */
        long long c = cycles_total + m68k_cycles_run();
        return c < blit_busy_until ? 0x4000 : 0;
    }
    (void)size;
    return 0;
}

static uint32_t cop1lc;
static uint16_t creg[0x100];
static uint32_t cop2lc, cop_pc;
static int cop_state;                   /* 0 stopped, 1 runs, 2 waits for the blitter */
static long long cop_cyc;               /* (cycles of moves since its last wait) */
static int in_copper;
static int cop_warn;
static long cop_restarts;
static long long blit_words;
static int blit_warn;

static void vw_hit(uint32_t a, uint32_t v)
{
    uint32_t pc = m68k_get_reg(NULL, M68K_REG_PPC);
    int i;
    if (getenv("NHL_VWSTACK")) {        /* the code addresses on the stack: who called */
        static int seen;
        if (frame >= atoi(getenv("NHL_VWSTACK")) && seen++ < 3) {
            uint32_t sp = m68k_get_reg(NULL, M68K_REG_SP);
            fprintf(stderr, "frame %d: write %06x pc %06x, stack:", frame, a, pc);
            for (int k = 0; k < 64; k += 2) { uint32_t v = rd32(sp + k); if (v >= 0x200000 && v < 0x300000 && !(v & 1)) fprintf(stderr, " %06x", v); }
            fprintf(stderr, "\n");
        }
    }
    for (i = 0; i < vwn && vw[i].pc != pc; i++) ;
    if (i == vwn) { if (vwn == 64) return; vwn++; vw[i].pc = pc; vw[i].n = vw[i].ch = 0; vw[i].lo = 0xFFFFFFFF; vw[i].hi = 0; }
    vw[i].n++;
    if (mem[a] != (uint8_t)v) vw[i].ch++;
    if (a < vw[i].lo) vw[i].lo = a;
    if (a > vw[i].hi) vw[i].hi = a;
}

static uint16_t pend_reg[0x38 / 2];
static int pend_h, pend_w;
static void watch_hit(uint32_t a, uint32_t v)
{
    fprintf(stderr, "frame %d: %06x = %02x (was %02x) %s pc=%06x\n", frame, a, v & 0xFF, mem[a],
            in_blit ? "blitter" : "cpu", m68k_get_reg(NULL, M68K_REG_PPC));
    if (in_blit) {
        uint16_t *r = pend_reg - 0x40 / 2;
        fprintf(stderr, "  blit con0 %04x con1 %04x A %06x B %06x C %06x D %06x mods A %d B %d C %d D %d, %d rows of %d words\n",
                r[0x40 / 2], r[0x42 / 2], (r[0x50 / 2] << 16) | r[0x52 / 2], (r[0x4C / 2] << 16) | r[0x4E / 2],
                (r[0x48 / 2] << 16) | r[0x4A / 2], (r[0x54 / 2] << 16) | r[0x56 / 2], (int16_t)r[0x64 / 2],
                (int16_t)r[0x62 / 2], (int16_t)r[0x60 / 2], (int16_t)r[0x66 / 2], pend_h, pend_w);
    }
}

/* The blitter, area mode, ascending and descending (no line mode). A blit's memory accesses are
   made when its time is up (the hardware makes them over that time), so a CPU write to what a
   pending blit reads or writes shows; NHL_EARLYBLIT=1 makes them at the start instead. */
static int pend_run;
static void blit_exec(void);

/* NHL_DETERM: every build plays the same game. The renderer's own work takes none of the
   game's time: a frame ends after the game (and interrupt level 6, its tick) has run its
   cycles, the renderer's cycles and the level 3 interrupt's (the blit queue) do not count, and
   when the CPU would wait (the renderer for a vertical blank, the blitter or room in its
   queue; the renderer giving way; the game waiting with nothing to draw) the frame ends at
   once. Blits are done at once. The game's beam position reads are fixed (as
   NHL_FIXEDHV) and the renderer is not given the game's time when the game runs long.
   NHL_DETBLIT=1: the blits take their time as without NHL_DETERM (the CPU's work and the
   blitter's overlap), a wait of the renderer for the blitter ending the blit at once. */
static long long det_free;              /* cycles that did not count */
static int det_prev_free, det_last_cyc, det_spin, det_loops, det_since, det_why;
static uint32_t det_endpc;
static uint32_t det_prev_pc, det_ctx, det_heads[4], det_yield, det_idle;
static long long det_calls;
static int det_blit;                    /* NHL_DETBLIT: blits take their time (below) */
static FILE *prof_f;                    /* NHL_PROF: a PC sample each 1000 cycles run: the */
static long long prof_next;             /* instruction that ran then */
static uint32_t prof_pc, prof_sr, prof_ret;
static uint32_t pcc_addr[8]; static long long pcc_n[8]; static int pcc_k; static int pcc_from;
/* NHL_BFCHK=1: a bit field instruction on memory whose offset is in a data register: report
   (each code address once) an offset of 2^20 bits or more either way, a register with
   something left in its top word (the offset is all 32 bits of it) */
static int bfchk = -1;
static void bf_check(unsigned int pc)
{
    static uint32_t seen[256]; static int nseen;
    pc &= 0xFFFFFF;
    uint32_t op = rd16(pc);
    if ((op & 0xF8C0) != 0xE8C0 || (op & 0x38) == 0) return;   /* bitfield, not on a register */
    uint32_t ext = rd16(pc + 2);
    if (!(ext & 0x0800)) return;                                  /* offset immediate */
    int32_t off = (int32_t)m68k_get_reg(NULL, M68K_REG_D0 + ((ext >> 6) & 7));
    if (off > -(1 << 20) && off < (1 << 20)) return;
    for (int i = 0; i < nseen; i++) if (seen[i] == pc) return;
    if (nseen < 256) seen[nseen++] = pc;
    fprintf(stderr, "bfchk: frame %d pc %06x offset d%d = %08x\n", frame, pc, (ext >> 6) & 7, (uint32_t)off);
}
static void det_hook(unsigned int pc)
{
    det_calls++;
    if (bfchk < 0) bfchk = getenv("NHL_BFCHK") ? 1 : 0;
    if (bfchk) bf_check(pc);
    for (int i = 0; i < pcc_k; i++) if ((pc & 0xFFFFFF) == pcc_addr[i] && frame >= pcc_from) pcc_n[i]++;
    if (prof_f) {
        long long now = cycles_total + m68k_cycles_run();
        if (!prof_next) prof_next = now;
        while (now >= prof_next) {
            fprintf(prof_f, "%06x %04x %06x %d\n", prof_pc, prof_sr, prof_ret, frame);
            prof_next += 1000;
        }
        prof_pc = pc & 0xFFFFFF;
        prof_sr = m68k_get_reg(NULL, M68K_REG_SR);
        prof_ret = rd32(m68k_get_reg(NULL, M68K_REG_SP)) & 0xFFFFFF;
    }
    if (!det) return;
    int c = m68k_cycles_run();
    if (det_prev_free) det_free += c - det_last_cyc;
    det_last_cyc = c;
    unsigned ipl = (m68k_get_reg(NULL, M68K_REG_SR) >> 8) & 7;
    int rend = mem[det_ctx] != 0;
    det_prev_free = ipl == 3 || (rend && ipl != 6);
    det_since++;
    pc &= 0xFFFFFF;
    /* the CPU has nothing to do until the next vertical blank: the renderer gives way (trap #1,
       not a tick's switch) or the game's wait finds nothing to draw. The frame ends: so each
       wait loop of the game goes round once a frame, whatever the renderer did */
    if ((pc == det_yield && ipl < 6) || pc == det_idle) { det_spin = 1; det_why = pc == det_idle ? 3 : 2; det_endpc = pc; m68k_end_timeslice(); }
    if (det_blit && rend && ipl != 6 && pc != det_heads[0] && blit_end_pending &&
        (pc == det_heads[1] || pc == det_heads[2] || pc == det_heads[3]) &&
        pc == det_prev_pc && det_since <= 8) {
        /* the renderer waits for the blitter (the queue, a blit, room in the queue: the second
           time round the loop): the blit is done now, the wait taking no time */
        blit_busy_until = cycles_total + c;
        m68k_end_timeslice();
        det_loops = 0;
        det_prev_pc = pc;
        det_since = 0;
        return;
    }
    if (rend && ipl != 6 && (pc == det_heads[0] || pc == det_heads[1] || pc == det_heads[2] || pc == det_heads[3])) {
        /* the renderer at the top of a wait loop: the second time round without leaving it,
           it waits */
        if (pc == det_prev_pc && det_since <= 8) { if (++det_loops >= 2) { det_spin = 1; det_why = 1; det_endpc = pc; m68k_end_timeslice(); } }
        else det_loops = 0;
        det_prev_pc = pc;
        det_since = 0;
    }
}
/* An interrupt is taken: the instruction before it counted as it was; the level 3 interrupt's
   own exception processing (the blit queue's, or the vertical blank's) does not count. */
static int det_int_ack(int level)
{
    if (det) {
        int c = m68k_cycles_run();
        if (det_prev_free) det_free += c - det_last_cyc;
        det_last_cyc = c;
        if (level == 3) det_prev_free = 1;
    }
    return M68K_INT_ACK_AUTOVECTOR;
}

/* NHL_BLITKINDS: the blitter's time from frame 1700 by kind, the kind being which of the
   renderer's chip buffers (the debug block from +80) each channel starts in */
static struct { char key[48]; long long time, words, n; } bk[64];
static int bkn;
static unsigned bk_frames0;
static uint32_t scx_lo, scx_hi;          /* the ring's second part (NHL_SCX) */
static char bk_region(uint32_t a)
{
    static const char names[] = "SBMcCOFhLH";     /* in their order in the chip section */
    uint32_t st[10];
    if (!a) return '-';
    if (a >= scx_lo && a < scx_hi) return 'c';
    st[0] = rd32(dbg + 80); st[1] = rd32(dbg + 36); st[2] = rd32(dbg + 84); st[3] = rd32(dbg + 100);
    st[4] = rd32(dbg + 88); st[5] = rd32(dbg + 60); st[6] = rd32(dbg + 92); st[7] = rd32(dbg + 104);
    st[8] = rd32(dbg + 64); st[9] = rd32(dbg + 96);
    for (int i = 9; i >= 0; i--)
        if (a >= st[i] && (i < 9 || a < st[9] + 288 * 224)) return names[i];
    return '?';
}
static void blitkind_add(uint16_t con0, uint32_t a, uint32_t b, uint32_t c, uint32_t d, long long words,
                         long long t)
{
    char key[48];
    snprintf(key, sizeof key, "A%c B%c C%c D%c %04x", bk_region(a), bk_region(b), bk_region(c), bk_region(d),
             con0 & 0x0FFF);
    int i;
    for (i = 0; i < bkn; i++) if (!strcmp(bk[i].key, key)) break;
    if (i == bkn) { if (bkn == 64) return; strcpy(bk[bkn++].key, key); }
    bk[i].time += t; bk[i].words += words; bk[i].n++;
}
static void blitkind_print(unsigned frames)
{
    long long tot = 0;
    for (int i = 0; i < bkn; i++) tot += bk[i].time;
    for (int i = 0; i < bkn; i++)       /* largest first */
        for (int j = i + 1; j < bkn; j++)
            if (bk[j].time > bk[i].time) { __typeof__(bk[0]) x = bk[i]; bk[i] = bk[j]; bk[j] = x; }
    fprintf(stderr, "blitter by kind (S screen B plane B bitmap M its mask c copper C sprite cache O overlay"
            " F fps H/L overlay masks), from frame 1700, %u frames drawn:\n", frames);
    for (int i = 0; i < bkn; i++)
        fprintf(stderr, "  %-22s %5.1f%%  %7.0f cycles a frame drawn, %6.1f blits, %7.0f words\n", bk[i].key,
                100.0 * bk[i].time / tot, (double)bk[i].time / frames, (double)bk[i].n / frames,
                (double)bk[i].words / frames);
}

/* The reference renderer's VRAM: the game's, with the tiles a DMA sent from the players' sprite
   tiles (planar in the program, not copied to VRAM: the debug block from +156) taken from the
   original data (Extracted/NHL94/Graphics/Spritetiles.bin). */
static uint8_t *ref_vram(uint32_t vram)
{
    static uint8_t v[0x10000], *orig; static long olen = -1;
    memcpy(v, mem + (vram & 0xFFFFFF), sizeof v);
    if (olen < 0) {
        FILE *f = fopen("Extracted/NHL94/Graphics/Spritetiles.bin", "rb");
        olen = 0;
        if (f) {
            fseek(f, 0, SEEK_END); olen = ftell(f); fseek(f, 0, SEEK_SET); orig = malloc(olen);
            if (fread(orig, 1, olen, f) != (size_t)olen) olen = 0;
            fclose(f);
        } else
            fprintf(stderr, "harness: no Spritetiles.bin: the reference sprites will be wrong\n");
    }
    uint32_t st = rd32(dbg + 156), sz = rd32(dbg + 160), ts = rd32(dbg + 164);
    int np = 0;
    for (int t = 0; t < 2048; t++) {
        uint32_t s = rd32(ts + 4 * t) - st;
        if (s < sz && (long)s + 32 <= olen) { memcpy(v + 32 * t, orig + s, 32); np++; }
    }
    if (getenv("NHL_REFLOG")) fprintf(stderr, "ref_vram: spritetiles %06x size %x tsrc %06x olen %ld: %d tiles\n", st, sz, ts, olen, np);
    return v;
}

static void do_blit(int h, int w)
{
    uint16_t con0 = creg[0x40 / 2];
    int n = !!(con0 & 0x800) + !!(con0 & 0x400) + !!(con0 & 0x200) + !!(con0 & 0x100);
    if (pend_run) blit_exec();             /* (a blit started while one runs: the old one first) */
    memcpy(pend_reg, &creg[0x40 / 2], sizeof pend_reg);
    if (hazard > 0)
    {
        pend_qtime = in_copper ? wtime[((cop_insn + 2) >> 1) & (MEMSIZE / 2 - 1)]
                               : (uint32_t)((cycles_total + m68k_cycles_run()) >> 4) + 1;
        pend_qpc = in_copper ? wpc[((cop_insn + 2) >> 1) & (MEMSIZE / 2 - 1)] : m68k_get_reg(NULL, M68K_REG_PPC);
    }
    pend_h = h;
    pend_w = w;
    pend_run = 1;
    blit_busy_until = cycles_total + m68k_cycles_run() + 20 + (long long)h * w * (2 * n + 2) +
                      (in_copper ? cop_cyc : 0);
    blit_end_pending = 1;
    if (getenv("NHL_EARLYBLIT")) blit_exec();
    if (det && !det_blit) {             /* (done at once) */
        blit_exec();
        blit_busy_until = cycles_total + m68k_cycles_run();
        blit_end_pending = 0;
        blit_irq = 1;
        update_irq();
    }
}

static void blit_exec(void)
{
    uint16_t *r = pend_reg - 0x40 / 2;     /* (indexed by register offset / 2 as creg is) */
    int h = pend_h, w = pend_w;
    pend_run = 0;
    uint16_t con0 = r[0x40 / 2], con1 = r[0x42 / 2];
    int ash = con0 >> 12, bsh = con1 >> 12, lf = con0 & 0xFF, desc = con1 & 2;
    int useA = con0 & 0x800, useB = con0 & 0x400, useC = con0 & 0x200, useD = con0 & 0x100;
    uint32_t apt = (r[0x50 / 2] << 16) | r[0x52 / 2], bpt = (r[0x4C / 2] << 16) | r[0x4E / 2];
    uint32_t cpt = (r[0x48 / 2] << 16) | r[0x4A / 2], dpt = (r[0x54 / 2] << 16) | r[0x56 / 2];
    int16_t amod = r[0x64 / 2], bmod = r[0x62 / 2], cmod = r[0x60 / 2], dmod = r[0x66 / 2];
    uint16_t afwm = r[0x44 / 2], alwm = r[0x46 / 2];
    int step = desc ? -2 : 2;
    long long blit_time = 20;
    /* the shifters take the bits shifted in from the data registers' last words, as the
       hardware does: what the previous blit (or a write to BLTxDAT) left there */
    uint32_t aold = r[0x74 / 2], bold = r[0x72 / 2];
    uint32_t a0 = apt, b0 = bpt, c0 = cpt, d0 = dpt;
    if (con1 & 1) { fprintf(stderr, "blitter line mode not emulated\n"); return; }
    in_blit = 1;
    int hz_blit = 0;
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            uint32_t a = useA ? rd16(apt) : r[0x74 / 2];
            uint32_t b = useB ? rd16(bpt) : r[0x72 / 2];
            uint32_t c = useC ? rd16(cpt) : r[0x70 / 2];
            if (hazard > 0 && hazard_n < hazard && pend_qtime && !hz_blit) {
                uint32_t src[3] = { useA ? apt : 0, useB ? bpt : 0, useC ? cpt : 0 };
                for (int k = 0; k < 3; k++) {
                    if (!src[k]) continue;
                    if (x == w - 1 && w > 1 && !alwm && useA && (con0 & 0xFF) == 0xCA && k < 2)
                        continue;       /* (a cut's shift word: its mask 0, what it reads unused) */
                    uint32_t wt = wtime[((src[k] & 0xFFFFFF) >> 1) & (MEMSIZE / 2 - 1)];
                    if (wt > pend_qtime) {
                        hazard_n++;
                        hz_blit = 1;
                        fprintf(stderr, "frame %d: hazard: blit con0 %04x (copper %06x) reads %c %06x, written %u cycles after it was queued (by pc %06x; queued by pc %06x)\n",
                                frame, con0, cop_insn, 'A' + k, src[k] & 0xFFFFFF, 16 * (wt - pend_qtime), wpc[((src[k] & 0xFFFFFF) >> 1) & (MEMSIZE / 2 - 1)], pend_qpc);
                        break;
                    }
                }
            }
            if (useA) apt += step;
            if (useB) bpt += step;
            if (useC) cpt += step;
            if (x == 0) a &= afwm;
            if (x == w - 1) a &= alwm;
            uint32_t as, bs;
            if (!desc) {
                as = (((aold << 16) | a) >> ash) & 0xFFFF;
                bs = (((bold << 16) | b) >> bsh) & 0xFFFF;
            } else {
                as = (((a << 16) | aold) >> (16 - ash)) & 0xFFFF;
                bs = (((b << 16) | bold) >> (16 - bsh)) & 0xFFFF;
                if (!ash) as = a;
                if (!bsh) bs = b;
            }
            aold = a;
            bold = b;
            if (useA) creg[0x74 / 2] = a;
            if (useB) creg[0x72 / 2] = b;
            uint32_t d = 0;
            for (int n = 0; n < 8; n++)
                if (lf & (1 << n))
                    d |= ((n & 4) ? as : ~as) & ((n & 2) ? bs : ~bs) & ((n & 1) ? c : ~c);
            if (useD) { wr16(dpt, d & 0xFFFF); dpt += step; }
            blit_words++;
            blit_time += 2 * ((useA != 0) + (useB != 0) + (useC != 0) + (useD != 0)) + 2;
        }
        if (useA) apt += desc ? -amod : amod;
        if (useB) bpt += desc ? -bmod : bmod;
        if (useC) cpt += desc ? -cmod : cmod;
        if (useD) dpt += desc ? -dmod : dmod;
    }
    in_blit = 0;
    if (frame >= 1700 && getenv("NHL_BLITKINDS"))   /* by the buffers it reads and writes */
        blitkind_add(con0, useA ? a0 : 0, useB ? b0 : 0, useC ? c0 : 0, useD ? d0 : 0, h * w, blit_time);
    if (getenv("NHL_BLITLOG")) {        /* every blit: the frame shown next, its registers, its time */
        static FILE *blf;
        extern int bf_shown;
        if (!blf) blf = fopen(getenv("NHL_BLITLOG"), "w");
        fprintf(blf, "%d %d %04x %04x %04x %04x %x %x %x %x %d %d %lld\n", bf_shown, frame, con0, con1, afwm, alwm,
                useA ? a0 : 0, useB ? b0 : 0, useC ? c0 : 0, useD ? d0 : 0, w, h, blit_time);
    }
    if (getenv("NHL_BLITFRAMES")) {     /* this frame's blitter time by kind (written at its show) */
        extern long long bf_t[4], bf_n[4];
        int k = (con0 & 0x0FFF) == 0x09F0 ? 0 : (con0 & 0x0FFF) == 0x0FCA ? 1 : (con0 & 0x0F00) == 0x0100 ? 2 : 3;
        bf_t[k] += blit_time; bf_n[k]++;
    }
    if (frame >= 1700) {                /* blitter time by kind (NHL_STATS) */
        extern long long blitstat[4];
        int kind = (con0 & 0x0FFF) == 0x0FCA ? (alwm ? 2 : 1) : (con0 == 0x07CA || con0 == 0x05C0 || con0 == 0x09F0) ? 0 : 3;
        blitstat[kind] += blit_time;
    }
}

/* ---- Paula: the four voices' DMA, mixed into a WAV (NHL_WAV=file) a frame at a time ---- */
#define WAVHZ 44100
static struct { uint32_t ptr, len, pos; double frac; int on; } aud[4];
static FILE *wavf;
static uint32_t wav_samples;

static void aud_latch(int i)
{
    aud[i].ptr = ((uint32_t)creg[(0xA0 + 16 * i) / 2] << 16) | creg[(0xA2 + 16 * i) / 2];
    aud[i].len = creg[(0xA4 + 16 * i) / 2] ? creg[(0xA4 + 16 * i) / 2] : 0x10000;
    aud[i].pos = 0;
    aud[i].frac = 0;
}

static void aud_dmacon(uint32_t v)
{
    for (int i = 0; i < 4; i++) {
        if (!(v & (1 << i))) continue;
        if (v & 0x8000) {
            if (!aud[i].on) aud_latch(i);
            aud[i].on = 1;
            if (getenv("NHL_AUDLOG"))
                fprintf(stderr, "frame %d: voice %d start %06x len %u per %u\n", frame, i, aud[i].ptr, aud[i].len,
                        creg[(0xA6 + 16 * i) / 2]);
        }
        else aud[i].on = 0;
    }
}

static void wav_header(void)
{
    uint32_t data = wav_samples * 4;
    uint8_t h[44] = "RIFF....WAVEfmt \x10\0\0\0\1\0\2\0....\0\0\0\0\4\0\x10\0data....";
    uint32_t vals[4][2] = {{4, 36 + data}, {24, WAVHZ}, {28, WAVHZ * 4}, {40, data}};
    for (int k = 0; k < 4; k++) for (int b = 0; b < 4; b++) h[vals[k][0] + b] = vals[k][1] >> (8 * b);
    fseek(wavf, 0, SEEK_SET);
    fwrite(h, 1, 44, wavf);
}

static void aud_frame(void)
{
    if (!wavf) {
        if (!getenv("NHL_WAV")) return;
        wavf = fopen(getenv("NHL_WAV"), "wb");
        wav_header();
    }
    for (int n = 0; n < WAVHZ / 60; n++) {
        int lr[2] = {0, 0};
        for (int i = 0; i < 4; i++) {
            if (!aud[i].on) continue;
            int per = creg[(0xA6 + 16 * i) / 2], vol = creg[(0xA8 + 16 * i) / 2] & 0x7F;
            if (per < 124) per = 124;
            if (vol > 64) vol = 64;
            lr[(i == 0 || i == 3) ? 0 : 1] += (int8_t)rd8(aud[i].ptr + aud[i].pos) * vol;
            aud[i].frac += 3546895.0 / per / WAVHZ;
            while (aud[i].frac >= 1) {
                aud[i].frac -= 1;
                if (++aud[i].pos >= 2 * aud[i].len) aud_latch(i);
            }
        }
        for (int c = 0; c < 2; c++) {
            int v = lr[c] * 2;
            if (v > 32767) v = 32767;
            if (v < -32768) v = -32768;
            fputc(v & 0xFF, wavf);
            fputc((v >> 8) & 0xFF, wavf);
        }
        wav_samples++;
    }
}

/* ---- The copper: each vertical blank the display list (COP1LC), which ends by jumping to
   COP2LC, the renderer's blit queue: blocks of moves to the blitter's registers, each after a
   wait for the blitter. Moves take no time but on the blitter's start (8 cycles each since its
   wait); a beam position wait is taken as reached, a wait for $FF,$FE (the queue's end) stops
   it until a jump (COPJMP2 from the CPU) or the next vertical blank. ---- */
static void custom_write(uint32_t a, uint32_t v);
static void copper_run(void)
{
    static int stress = -1; static uint32_t rnd = 12345;
    if (stress < 0) stress = getenv("NHL_COPSTRESS") ? atoi(getenv("NHL_COPSTRESS")) : 0;
    in_copper = 1;
    for (int n = 0; n < 1000000 && cop_state; n++) {
        if (stress) {               /* NHL_COPSTRESS=N: a vertical blank's restart (the display
                                       list, then its jump to COP2LC) at random instructions, one
                                       in N on average: the blit queue must survive it anywhere */
            rnd = rnd * 1103515245 + 12345;
            if ((rnd >> 8) % stress == 0 && cop1lc) { cop_pc = cop1lc; cop_restarts++; }
        }
        uint32_t w1 = rd16(cop_pc), w2 = rd16(cop_pc + 2);
        if (!(w1 & 1)) {                /* move */
            uint32_t r = w1 & 0x1FE;
            cop_pc += 4;
            cop_cyc += 8;
            if (r == 0x08A) { cop_pc = cop2lc; continue; }
            if (r == 0x088) { cop_pc = cop1lc; continue; }
            if (r < 0x040 || (r < 0x080 && !(creg[0x2E / 2] & 2))) {
                fprintf(stderr, "frame %d: copper move to %03x refused (COPCON)\n", frame, r);
                cop_state = 0;
                break;
            }
            if (!(r >= 0x040 && r <= 0x074) && !(r >= 0x08E && r <= 0x094) && r != 0x09C && r != 0x084 &&
                r != 0x086 && !(r >= 0x100 && r <= 0x10C) && !(r >= 0x120 && r < 0x140) &&
                !(r >= 0x180 && r < 0x1C0) && r != 0x1FC && r != 0x0E0 && !(r >= 0x0E0 && r < 0x100) && cop_warn < 20) {
                cop_warn++;
                fprintf(stderr, "frame %d: copper move to %03x = %04x at %06x (lost?)\n", frame, r, w2, cop_pc - 4);
            }
            cop_insn = cop_pc - 4;
            custom_write(0xDFF000 + r, w2);
            continue;
        }
        if (w2 & 1) { fprintf(stderr, "frame %d: copper skip not emulated\n", frame); cop_state = 0; break; }
        if ((w1 & 0xFF00) == 0xFF00 && (w1 & 0xFE) == 0xFE) { cop_state = 0; break; }   /* never */
        if ((w1 != 0x0001 || w2 != 0x7FFE) && cop_warn < 20) {
            cop_warn++;
            fprintf(stderr, "frame %d: copper wait %04x %04x at %06x (lost?)\n", frame, w1, w2, cop_pc);
        }
        if (!(w2 & 0x8000) && cycles_total + m68k_cycles_run() < blit_busy_until) { cop_state = 2; break; }
        cop_pc += 4;
        cop_cyc = 0;
    }
    in_copper = 0;
}

long long bf_t[4], bf_n[4];
int bf_shown;                           /* copper lists set so far (NHL_BLITLOG) */
static void blitframe_shown(void)
{                                       /* NHL_BLITFRAMES=file: a line a frame shown: the game
                                           frame, the blitter's cycles and blits by kind (copy A
                                           to D, cookie cut, D only, other) */
    static FILE *bff;
    if (!bff) bff = fopen(getenv("NHL_BLITFRAMES"), "w");
    fprintf(bff, "%d %lld %lld %lld %lld %lld %lld %lld %lld\n", frame, bf_t[0], bf_n[0], bf_t[1], bf_n[1],
            bf_t[2], bf_n[2], bf_t[3], bf_n[3]);
    memset(bf_t, 0, sizeof bf_t); memset(bf_n, 0, sizeof bf_n);
}
static void custom_write(uint32_t a, uint32_t v)
{
    uint32_t off = a & 0xFFE;
    if (off == 0x096) aud_dmacon(v);
    if (off >= 0x040 && off <= 0x074 && cycles_total + m68k_cycles_run() < blit_busy_until && blit_warn < 20) {
        blit_warn++;
        fprintf(stderr, "frame %d: blitter register %03x written while busy, pc=%06x\n", frame, off,
                m68k_get_reg(NULL, M68K_REG_PPC));
    }
    if (off == 0x1F0 && getenv("NHL_DBGPORT")) {      /* a renderer debug log (SPRLOG builds) */
        if (v == 0x8000) fprintf(stderr, "\ndbg %d", frame);
        else fprintf(stderr, " %d", (int16_t)v);
        return;
    }
    creg[off / 2] = v;
    if (off == 0x09A) { if (v & 0x8000) intena |= v & 0x7FFF; else intena &= ~v; update_irq(); }
    if (off == 0x09C && (v & 0x40)) { blit_irq = (v & 0x8000) != 0; update_irq(); }
    if (off == 0x09C && (v & 0x20)) { vb_irq = (v & 0x8000) != 0; update_irq(); }
    if (off == 0x09C && (v & 0xA000) == 0xA000) { irq6_pending = 1; update_irq(); }   /* EXTER set: level 6 */
    if (off == 0x09C && (v & 0x1F)) { if (v & 0x8000) intreq_lo |= v & 0x1F; else intreq_lo &= ~v & 0x1F; update_irq(); }
    if (off == 0x084) cop2lc = (cop2lc & 0xFFFF) | (v << 16);
    if (off == 0x086) cop2lc = (cop2lc & 0xFFFF0000) | (v & 0xFFFF);
    if (off == 0x08A && !in_copper) { cop_pc = cop2lc; cop_state = 1; copper_run(); }
    if (off == 0x088 && !in_copper) { cop_pc = cop1lc; cop_state = 1; copper_run(); }
    if (off == 0x058) do_blit((v >> 6) ? (v >> 6) : 1024, (v & 63) ? (v & 63) : 64);
    if (off == 0x05E) do_blit(creg[0x5C / 2] & 0x7FFF ? creg[0x5C / 2] & 0x7FFF : 0x8000, (v & 0x7FF) ? (v & 0x7FF) : 0x800);
    if (off == 0x180 && v == 0xF00) red_screen = 1;
    if (off == 0x082 && getenv("NHL_BLITFRAMES")) blitframe_shown();
    if (off == 0x082) bf_shown++;
    if (off == 0x080) cop1lc = (cop1lc & 0xFFFF) | (v << 16);
    if (off == 0x082) cop1lc = (cop1lc & 0xFFFF0000) | (v & 0xFFFF);
}

/* Show what the Amiga would: follow the copper list for bitplane pointers, width and colours. */
static void amiga_png(const char *name)
{
    uint32_t bpl[8] = {0}, pal[256] = {0};
    int bank = 0, loct = 0, ddf = 0x38, ddfstop = 0xC8, delay = 0, nplanes = 0, mod = 0, ham = 0, killehb = 0, fmode = 0;
    uint32_t spr[8] = {0};
    int sprbank = 1, diwv = 0x2C;
    uint32_t pc = cop1lc;
    for (int i = 0; i < 400 && pc; i++) {
        uint32_t w1 = rd16(pc), w2 = rd16(pc + 2);
        pc += 4;
        if (w1 == 0xFFFF && w2 == 0xFFFE) break;
        if (w1 == 0x08A || w1 == 0x088) break;
        if (w1 & 1) continue;
        uint32_t r = w1 & 0x1FE;
        if (r >= 0xE0 && r < 0x100) {
            int n = (r - 0xE0) / 4;
            if (r & 2) bpl[n] = (bpl[n] & 0xFFFF0000) | w2; else bpl[n] = (bpl[n] & 0xFFFF) | (w2 << 16);
        } else if (r == 0x106) { bank = w2 >> 13; loct = (w2 >> 9) & 1; }
        else if (r >= 0x180 && r < 0x1C0) {
            /* AGA: a write sets the high nibbles (and copies them to the low ones), a write
               with BPLCON3 LOCT the low nibbles */
            int c = bank * 32 + (r - 0x180) / 2;
            uint32_t n = ((w2 >> 8) & 15) << 16 | ((w2 >> 4) & 15) << 8 | (w2 & 15);
            if (!loct) pal[c] = n << 4 | n;
            else pal[c] = (pal[c] & 0xF0F0F0) | n;
        } else if (r == 0x092) ddf = w2;
        else if (r == 0x094) ddfstop = w2;
        else if (r == 0x102) delay = (w2 & 15) | ((w2 >> 10) & 3) << 4;   /* playfield 1, lores pixels */
        else if (r == 0x100) { nplanes = (w2 >> 12) & 7; ham = (w2 >> 11) & 1; }
        else if (r == 0x104) killehb = (w2 >> 9) & 1;
        else if (r == 0x108) mod = w2;
        else if (r == 0x1FC) fmode = w2 & 15;
        else if (r == 0x10C) sprbank = w2 & 15;              /* BPLCON4 OSPRM (the HUD sets both) */
        else if (r >= 0x120 && r < 0x140) {
            int n = (r - 0x120) / 4;
            if (r & 2) spr[n] = (spr[n] & 0xFFFF0000) | w2; else spr[n] = (spr[n] & 0xFFFF) | (w2 << 16);
        }
    }
    int diwh = 0x81, diwstop = 0xC1;
    {
        uint32_t q = cop1lc;
        for (int i = 0; i < 400 && q; i++, q += 4) {
            uint32_t r = rd16(q), v = rd16(q + 2);
            if (r == 0xFFFF || r == 0x8A || r == 0x88) break;
            if (r == 0x8E) { diwh = v & 0xFF; diwv = v >> 8; }
            if (r == 0x90) diwstop = v & 0xFF;
        }
    }
    /* lores fetches of 16 / 32 / 64 pixels (FMODE 0 / 1 / 3) in 8 / 16 / 32 colour clocks;
       DDFSTRT $38 puts the first pixel fetched at the window position $81, BPLCON1 delays it */
    int unit = (fmode & 3) == 0 ? 8 : (fmode & 3) == 3 ? 32 : 16;
    int fetch = ((ddfstop - ddf) / unit + 1) * unit / 4;
    int w = (diwstop | 0x100) - diwh, skip = diwh - 0x81 + (0x38 - ddf) * 2 - delay, h = 224, bpr = fetch + mod;
    static uint8_t rgb[320 * 240 * 3];
    for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
            int c = 0, xx = x + skip;
            if (xx < 0 || xx >= fetch * 8) xx = -1;   /* not fetched: colour 0 */
            for (int p = 0; p < nplanes; p++)
                if (xx >= 0 && (rd8(bpl[p] + y * bpr + xx / 8) & (0x80 >> (xx & 7)))) c |= 1 << p;
            uint32_t col = pal[c];
            if (nplanes == 6 && !ham && !killehb)   /* Extra Half-Brite: colours 32-63 halve 0-31 */
                col = c >= 32 ? (pal[c - 32] >> 1) & 0x7F7F7F : pal[c];
            uint8_t *o = rgb + (y * w + x) * 3;
            o[0] = col >> 16; o[1] = col >> 8; o[2] = col;
        }
    /* hardware sprites: attached pairs of 64 pixel sprites (FMODE sprite bits 3), in front of
       the playfield, sprite 0 on top; HSTART = window start - 1 is screen x 0 */
    if (((fmode >> 2) & 3) == 3)
        for (int pr = 3; pr >= 0; pr--) {
            uint32_t ev = spr[2 * pr], od = spr[2 * pr + 1];
            if (!ev || !od) continue;
            uint32_t pos = rd16(ev), ctl = rd16(ev + 8), octl = rd16(od + 8);
            if (!pos && !ctl) continue;
            if (!(octl & 0x80)) continue;                  /* (only attached pairs are used) */
            int vs = (pos >> 8) | ((ctl & 4) << 6), ve = (ctl >> 8) | ((ctl & 2) << 7);
            int hs = ((pos & 0xFF) << 1) | (ctl & 1);
            for (int ln = vs; ln < ve; ln++) {
                int y = ln - diwv;
                if (y < 0 || y >= h) continue;
                uint32_t e = ev + 16 + (ln - vs) * 16, o2 = od + 16 + (ln - vs) * 16;
                for (int px = 0; px < 64; px++) {
                    int x = hs + px - (diwh - 1);
                    if (x < 0 || x >= w) continue;
                    int b = px >> 3, m = 0x80 >> (px & 7);
                    int c = ((rd8(e + b) & m) ? 1 : 0) | ((rd8(e + 8 + b) & m) ? 2 : 0) |
                            ((rd8(o2 + b) & m) ? 4 : 0) | ((rd8(o2 + 8 + b) & m) ? 8 : 0);
                    if (!c) continue;
                    uint32_t col = pal[sprbank * 16 + c];
                    uint8_t *o = rgb + (y * w + x) * 3;
                    o[0] = col >> 16; o[1] = col >> 8; o[2] = col;
                }
            }
        }
    png_write(name, rgb, w, h);
}

static int harness_ncyc = 233000;      /* -c: CPU cycles a frame */
static uint32_t io_read(uint32_t a, int size)
{
    if (a == 0xBFD800 || a == 0xBFD900 || a == 0xBFDA00) {    /* CIA-B TOD: horizontal syncs, as
        many a frame as NTSC lines of 227.5 colour clocks take Paula's 60th of a second */
        static uint32_t latch; static int held;
        if (!held) {
            double t = (frame - 1) + (double)(cycles_total + m68k_cycles_run() - vb_cycles) / harness_ncyc;
            latch = (uint32_t)(t * (3546895.0 / 60 / 227.5)) & 0xFFFFFF;
        }
        if (a == 0xBFDA00) held = 1;          /* reading the high byte holds it until the low one */
        if (a == 0xBFD800) held = 0;
        return a == 0xBFD800 ? latch & 0xFF : a == 0xBFD900 ? (latch >> 8) & 0xFF : (latch >> 16) & 0xFF;
    }
    if ((a & 0xFFFFFF00) == 0xBFDD00 || (a & 0xFFFF00) == 0xBFDD00) {   /* CIA-B ICR */
        int v = irq6_pending ? 0x81 : 0;
        irq6_pending = 0;
        update_irq();
        return v;
    }
    if (a >= 0xDFF000 && a < 0xE00000) return custom_read(a, size);
    return 0;
}

static int is_io(uint32_t a) { a &= 0xFFFFFF; return (a >= 0xBF0000 && a < 0xC00000) || (a >= 0xDFF000 && a < 0xE00000); }

/* NHL_CHIPWAIT=n: n more cycles for each CPU access to a chip memory hunk or a custom register
   (the chip bus is slow, slower still while the blitter runs: so a change that writes less to
   chip memory shows in the renderer's cycles as on the Amiga) */
extern int m68ki_remaining_cycles;
static uint32_t chip_lo[8], chip_hi[8]; static int nchip, chipwait = -1;
static inline void chip_access(uint32_t a)
{
    if (chipwait < 0) chipwait = getenv("NHL_CHIPWAIT") ? atoi(getenv("NHL_CHIPWAIT")) : 0;
    if (!chipwait || in_copper || in_blit) return;
    a &= 0xFFFFFF;
    int c = a >= 0xDFF000 && a < 0xE00000;
    for (int i = 0; i < nchip && !c; i++) c = a >= chip_lo[i] && a < chip_hi[i];
    if (c) m68ki_remaining_cycles -= chipwait;   /* (as the core's own USE_CYCLES) */
}

/* NHL_A32=1: report accesses whose address has a top byte (a 68EC020, as in a stock A1200, has 24
   address lines and ignores it, but a 68030 or later with fast RAM at 32 bit addresses does not):
   each code address once, with the address it used */
static int a32 = -1;
static void a32_check(uint32_t a, int w)
{
    static uint32_t seen[256]; static int nseen;
    if (a32 < 0) a32 = getenv("NHL_A32") ? 1 : 0;
    if (!a32 || !(a >> 24) || in_copper || in_blit) return;
    uint32_t pc = m68k_get_reg(NULL, M68K_REG_PPC);
    for (int i = 0; i < nseen; i++) if (seen[i] == pc) return;
    if (nseen < 256) seen[nseen++] = pc;
    fprintf(stderr, "a32: frame %d pc %06x %s %08x\n", frame, pc, w ? "writes" : "reads", a);
}
unsigned int m68k_read_memory_8(unsigned int a)
{
    a32_check(a, 0);
    chip_access(a);
    if (is_io(a)) {
        uint32_t aa = a & 0xFFFFFF;
        if (aa >= 0xDFF000) { uint32_t v = io_read(aa & ~1, 2); return (aa & 1) ? v & 0xFF : (v >> 8) & 0xFF; }
        return io_read(aa, 1) & 0xFF;
    }
    return rd8(a);
}
unsigned int m68k_read_memory_16(unsigned int a) { a32_check(a, 0); chip_access(a); if (is_io(a)) return io_read(a & 0xFFFFFF, 2) & 0xFFFF; return rd16(a); }
unsigned int m68k_read_memory_32(unsigned int a) { a32_check(a, 0); chip_access(a); if (is_io(a)) return (io_read(a & 0xFFFFFF, 2) << 16) | io_read((a + 2) & 0xFFFFFF, 2); return rd32(a); }
unsigned int m68k_read_disassembler_8(unsigned int a) { return rd8(a); }
unsigned int m68k_read_disassembler_16(unsigned int a) { return rd16(a); }
unsigned int m68k_read_disassembler_32(unsigned int a) { return rd32(a); }
static void hz_mark(uint32_t a, int words)
{
    if (hazard < 0) {
        hazard = getenv("NHL_HAZARD") ? atoi(getenv("NHL_HAZARD")) : 0;
        if (hazard) { wtime = calloc(MEMSIZE / 2, sizeof *wtime); wpc = calloc(MEMSIZE / 2, sizeof *wpc); }
    }
    if (!hazard) return;
    uint32_t t = (uint32_t)((cycles_total + m68k_cycles_run()) >> 4) + 1;   /* (0: never) */
    a &= 0xFFFFFE;
    uint32_t pc = m68k_get_reg(NULL, M68K_REG_PPC);
    for (int i = 0; i < words; i++) { wtime[((a >> 1) + i) & (MEMSIZE / 2 - 1)] = t; wpc[((a >> 1) + i) & (MEMSIZE / 2 - 1)] = pc; }
}
void m68k_write_memory_8(unsigned int a, unsigned int v) { a32_check(a, 1); chip_access(a); if (is_io(a)) { if ((a & 0xFFFFFF) >= 0xDFF000) custom_write(a & 0xFFFFFF, v); return; } wr8(a, v); hz_mark(a, 1); }
void m68k_write_memory_16(unsigned int a, unsigned int v) { a32_check(a, 1); chip_access(a); if (is_io(a)) { if ((a & 0xFFFFFF) >= 0xDFF000) custom_write(a & 0xFFFFFF, v); return; } wr16(a, v); hz_mark(a, 1); }
void m68k_write_memory_32(unsigned int a, unsigned int v) { a32_check(a, 1); chip_access(a); if (is_io(a)) { m68k_write_memory_16(a, v >> 16); m68k_write_memory_16(a + 2, v & 0xFFFF); return; } wr32(a, v); hz_mark(a, (a & 1) ? 3 : 2); }

/* Run n cycles in slices, raising the blitter interrupt when a blit's time is up. */
static int run_cycles(int n)
{
    int done = 0;
    while (done < n) {
        int slice = n - done < 500 ? n - done : 500;
        if (blit_end_pending && blit_busy_until > cycles_total && blit_busy_until - cycles_total < slice)
            slice = blit_busy_until - cycles_total;
        if (slice < 1) slice = 1;
        long long f0 = det_free;
        det_last_cyc = 0;
        int c = m68k_execute(slice);
        if (det && det_prev_free) det_free += c - det_last_cyc;
        det_last_cyc = c;
        cycles_total += c;
        done += c - (int)(det_free - f0);
        if (det_spin) {                 /* nothing to do until the vertical blank: the frame ends */
            det_spin = 0; det_loops = 0; done = n;
            if (getenv("NHL_DETLOG")) fprintf(stderr, "det frame %d: ends (%s) at %06x\n", frame,
                det_why == 1 ? "renderer waits" : det_why == 2 ? "renderer gives way" : "game idle", det_endpc);
            det_why = 0;
        }
        if (blit_end_pending && cycles_total >= blit_busy_until) {
            blit_end_pending = 0;
            if (pend_run) blit_exec();
            blit_irq = 1;
            update_irq();
        }
        if (cop_state == 2 && cycles_total >= blit_busy_until) { cop_state = 1; copper_run(); }
    }
    return done;
}

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
        if ((be32(p) & 0xC0000000) == 0x40000000 && nchip < 8) {     /* MEMF_CHIP */
            chip_lo[nchip] = addr; chip_hi[nchip] = addr + sz; nchip++;
        }
        if (getenv("NHL_AUDLOG")) fprintf(stderr, "hunk %d at %06x\n", i, addr);
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
    if (getenv("NHL_WATCH")) watch_addr = strtoul(getenv("NHL_WATCH"), NULL, 16) & 0xFFFFFE;
    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-f")) frames = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-S")) every = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-c")) harness_ncyc = ncyc = atoi(argv[++i]);
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
    if (getenv("NHL_POKE")) {           /* NHL_POKE=addr:word,..: words written once loaded (hex) */
        char *q = getenv("NHL_POKE");
        while (*q) {
            uint32_t a = strtoul(q, &q, 16), v = 0;
            if (*q == ':') v = strtoul(q + 1, &q, 16);
            wr16(a, v);
            if (*q == ',') q++; else break;
        }
    }
    dbg = rd32(code + 12);
    /* 'ERL1': game ticks run before their vertical blank when the game waits and the renderer
       is done (hal_tick_early) only with NHL_EARLY=1: the reference picture is the VDP at the
       frame's end, which is then part way through the next game frame at times */
    if (rd32(dbg + 180) == 0x45524C31 && !(getenv("NHL_EARLY") && atoi(getenv("NHL_EARLY"))))
        wr8(rd32(dbg + 184), 0);
    if (rd32(dbg + 172) == 0x53435831) {  /* 'SCX1': the sprite image ring's second part, as the
                                             launcher takes it from the chip memory left
                                             (NHL_SCX=bytes, default 256K; 0: none) */
        uint32_t sz = getenv("NHL_SCX") ? strtoul(getenv("NHL_SCX"), NULL, 0) : 0x40000;
        if (sz && nchip < 8) {
            scx_lo = 0xE00000; scx_hi = scx_lo + sz;
            chip_lo[nchip] = scx_lo; chip_hi[nchip] = scx_hi; nchip++;
            wr32(rd32(dbg + 176), scx_lo);
            wr32(rd32(dbg + 176) + 4, sz);
        }
    }
    if (getenv("NHL_DETERM")) {
        det = 1;
        det_blit = getenv("NHL_DETBLIT") != NULL;
        det_ctx = rd32(dbg + 128) & 0xFFFFFF;
        for (int k = 0; k < 4; k++) det_heads[k] = rd32(dbg + 132 + 4 * k) & 0xFFFFFF;
        det_yield = rd32(dbg + 148) & 0xFFFFFF;
        det_idle = rd32(dbg + 152) & 0xFFFFFF;
        if (getenv("NHL_DETLOG")) fprintf(stderr, "det: ctx %06x heads %06x %06x %06x %06x yield %06x idle %06x\n",
            det_ctx, det_heads[0], det_heads[1], det_heads[2], det_heads[3], det_yield, det_idle);
    }
    m68k_init();
    m68k_set_cpu_type(M68K_CPU_TYPE_68020);
    wr32(0, 0x1000);
    wr32(4, entry);
    m68k_pulse_reset();
    m68k_set_instr_hook_callback(det_hook);         /* (after init, which clears it) */
    if (getenv("NHL_PCCOUNT")) {        /* NHL_PCCOUNT=from:addr,addr...: how often each runs from frame from */
        char *q = getenv("NHL_PCCOUNT");
        pcc_from = strtol(q, &q, 10);
        while (*q && pcc_k < 8) { q++; pcc_addr[pcc_k++] = strtoul(q, &q, 16); }
    }
    m68k_set_int_ack_callback(det_int_ack);
    m68k_set_reg(M68K_REG_PC, entry);
    m68k_set_reg(M68K_REG_SR, 0x2700);
    m68k_set_reg(M68K_REG_SP, 0x1000);
    uint32_t vdpregs = rd32(dbg), vram = rd32(dbg + 4), cram = rd32(dbg + 8), vsram = rd32(dbg + 12);
    uint32_t padstate = rd32(dbg + 24);
    if (getenv("NHL_VWLOG")) {
        unsigned lo, hi;
        if (sscanf(getenv("NHL_VWLOG"), "%x:%x", &lo, &hi) == 2) { vw_lo = (vram & 0xFFFFFF) + lo; vw_hi = (vram & 0xFFFFFF) + hi; }
    }
    for (frame = 1; frame <= frames; frame++) {
        if (frame == 1700) bk_frames0 = rd32(rd32(dbg + 28));
        if (getenv("NHL_PHASE") && frame >= 1900 && frame < 2000 && !rd8(rd32(dbg + 120))) {
            /* the game frames the renderer draws (every second one): odd or even ones, as
               NHL_PHASE says, from frame 2000 (the work differs between the two) */
            uint32_t gf = rd32(rd32(dbg + 20)), want = atoi(getenv("NHL_PHASE")) & 1;
            if ((gf & 1) != want) wr32(rd32(dbg + 116), gf - 1);
        }
        if (getenv("NHL_DRAWLOG")) {        /* frames drawn so far, each frame (which ticks are drawn) */
            static FILE *df;
            if (!df) df = fopen(getenv("NHL_DRAWLOG"), "w");
            fprintf(df, "%d %u %u\n", frame, rd32(rd32(dbg + 28)), rd32(rd32(dbg + 20)));
        }
        if (getenv("NHL_RAMDUMP")) {        /* NHL_RAMDUMP=file:from:to: the Genesis RAM, each frame */
            static FILE *rf; char fn[256]; int f0 = 0, f1 = 0;
            if (sscanf(getenv("NHL_RAMDUMP"), "%255[^:]:%d:%d", fn, &f0, &f1) == 3 && frame >= f0 && frame <= f1) {
                if (!rf) rf = fopen(fn, "wb");
                fwrite(mem + (rd32(dbg + 108) & 0xFFFFFF), 1, 0x10000, rf);
            }
        }
        wr16(padstate, pad_at(frame));
        if (getenv("NHL_PROF") && frame >= (getenv("NHL_PROF_FROM") ? atoi(getenv("NHL_PROF_FROM")) : 0)) {
            if (!prof_f) prof_f = fopen(getenv("NHL_PROF"), "w");
        }
        long long free0 = det_free;
        run_cycles(ncyc);
        if (getenv("NHL_FREELOG")) {        /* NHL_FREELOG=file: the renderer's (and level 3's)
                                               cycles each frame, NHL_DETERM */
            static FILE *ff;
            if (!ff) ff = fopen(getenv("NHL_FREELOG"), "w");
            fprintf(ff, "%d %lld %u\n", frame, det_free - free0, rd32(rd32(dbg + 28)));
        }
        if (red_screen) { dump_exception(); break; }
        if (vwn) {
            for (int i = 0; i < vwn; i++)
                printf("frame %d: vram writes pc %06x: %u bytes (%u changed) %04x-%04x\n", frame, vw[i].pc, vw[i].n, vw[i].ch,
                       vw[i].lo - (vram & 0xFFFFFF), vw[i].hi - (vram & 0xFFFFFF));
            vwn = 0;
        }
        aud_frame();
        if (getenv("NHL_VDPLOG")) {         /* mode, plane size, plane B scroll */
            uint8_t *r = mem + (vdpregs & 0xFFFFFF);
            uint32_t hs = (r[13] & 0x3F) << 10;
            {   /* sprites by x: on the 256 screen, in a 32 pixel margin, further out */
                uint32_t sat = (r[5] & 0x7F) << 9;
                int on = 0, margin = 0, far = 0, n = 0, link = 0;
                do {
                    uint32_t e = vram + sat + link * 8;
                    int y = rd16(e) & 0x3FF, x = rd16(e + 6) & 0x1FF, w = ((rd8(e + 2) >> 2) & 3) * 8 + 8;
                    if (y >= 128 - 32 && y < 128 + 224) {
                        if (x + w > 128 && x < 128 + 256) on++;
                        else if (x + w > 128 - 32 && x < 128 + 288) margin++;
                        else far++;
                    }
                    link = rd8(e + 3) & 0x7F;
                } while (link && ++n < 80);
                if (getenv("NHL_SPRLOG")) printf("frame %d: sprites on %d margin %d far %d\n", frame, on, margin, far);
            }
            int black = 1;
            for (int c = 0; c < 64; c++) if (rd16(cram + 2 * c) & 0xEEE) black = 0;
            printf("frame %d: black %d r1 %02x r2 %02x r3 %02x r4 %02x r5 %02x r13 %02x r11 %02x r12 %02x r16 %02x r17 %02x r18 %02x hscrollB %d vscrollB %d\n", frame, black, r[1], r[2], r[3], r[4], r[5], r[13], r[11], r[12], r[16], r[17], r[18],
                   (int16_t)rd16(vram + hs + 2), (int16_t)rd16(vsram + 2));
        }
        if (det || getenv("NHL_FIXEDHV")) { /* (the same game every build: no vertical blank lost
                                               while one before it waits, interrupts off; and the
                                               renderer not given the game's time when the game
                                               runs long, hal_starve: its length would count) */
            int k;
            for (k = 0; k < 400 && (vb_irq || irq6_pending); k++) run_cycles(1000);
            if (k && getenv("NHL_DETLOG")) fprintf(stderr, "det frame %d: %d k cycles more for the interrupts\n", frame, k);
            wr16(rd32(dbg + 124), 0);
        }
        if (irq6_pending && getenv("NHL_TICKLOSS"))   /* the last tick still waits: this one is lost */
            fprintf(stderr, "tickloss: frame %d pc %06x sr %04x intena %04x\n", frame,
                    m68k_get_reg(NULL, M68K_REG_PC) & 0xFFFFFF, m68k_get_reg(NULL, M68K_REG_SR), intena);
        irq6_pending = 1;
        vb_irq = 1;
        update_irq();
        vb_cycles = cycles_total;
        if (cop1lc) { cop_pc = cop1lc; cop_state = 1; copper_run(); }
        int shot = every && frame % every == 0;
        for (int k = 0; k < nshots; k++) if (shots[k] == frame) shot = 1;
        if (shot) {
            char name[512];
            snprintf(name, sizeof name, "%s/shot_%05d.png", outdir, frame);
            vdpref_png(name, mem + (vdpregs & 0xFFFFFF), ref_vram(vram), mem + (cram & 0xFFFFFF),
                       mem + (vsram & 0xFFFFFF));
            if (getenv("NHL_DIFF")) {
                static uint8_t idx[320 * 240];
                static int pairs[256][256];
                memset(pairs, 0, sizeof pairs);
                vdpref_index = idx;
                static uint8_t tmp[320 * 240 * 3];
                int w, h;
                vdpref_render(tmp, &w, &h, mem + (vdpregs & 0xFFFFFF), ref_vram(vram),
                              mem + (cram & 0xFFFFFF), mem + (vsram & 0xFFFFFF));
                vdpref_index = NULL;
                uint32_t ch = rd32(dbg + 32);
                int bad = 0;
                for (int y = 0; y < h; y++)
                    for (int x = 0; x < w; x++) {
                        int r = idx[y * w + x] & 0x3F, a = rd8(ch + y * 384 + 32 + x);
                        int a6 = a & 0x3F;
                        if ((r & 15) == 0) r &= 0x30;
                        if ((a6 & 15) == 0) a6 &= 0x30;
                        if (r != a6 && !((r & 15) == 0 && (a6 & 15) == 0)) { bad++; pairs[r][a]++; }
                    }
                printf("frame %d: %d pixels differ\n", frame, bad);
                for (int i = 0; i < 64; i++)
                    for (int j = 0; j < 256; j++)
                        if (pairs[i][j] > 20) printf("  ref %02x ami %02x x%d\n", i, j, pairs[i][j]);
            }
            if (getenv("NHL_BMB")) {
                uint32_t bm = rd32(dbg + 36), cw = rd16(rd32(dbg + 40)), chh = rd16(rd32(dbg + 40) + 2);
                uint32_t cols = rd32(dbg + 44);
                static uint8_t img[1024 * 512 * 3];
                int W = cw * 8, H = chh * 8;
                if (W * H <= 1024 * 512) {
                    for (int y = 0; y < H; y++)
                        for (int x = 0; x < W; x++) {
                            int c = 0;
                            for (int p = 0; p < 6; p++)
                                if (rd8(bm + y * cw * 6 + p * cw + x / 8) & (0x80 >> (x & 7))) c |= 1 << p;
                            int col = rd16(cols + c * 2);
                            uint8_t *o = img + (y * W + x) * 3;
                            o[0] = ((col >> 8) & 15) * 17; o[1] = ((col >> 4) & 15) * 17; o[2] = (col & 15) * 17;
                        }
                    snprintf(name, sizeof name, "%s/bmb_%05d.png", outdir, frame);
                    png_write(name, img, W, H);
                }
            }
            snprintf(name, sizeof name, "%s/ami_%05d.png", outdir, frame);
            if (cop1lc) amiga_png(name);
            if (getenv("NHL_STATS"))
                vdpref_stats(frame, mem + (vdpregs & 0xFFFFFF), mem + (vram & 0xFFFFFF), mem + (vsram & 0xFFFFFF));
        }
    }
    if (cop_restarts) fprintf(stderr, "copper restarts (NHL_COPSTRESS): %ld\n", cop_restarts);
    if (wavf) { wav_header(); fclose(wavf); }
    if (getenv("NHL_DETLOG")) fprintf(stderr, "det: hook calls %lld, free cycles %lld\n", det_calls, det_free);
    fprintf(stderr, "stopped at frame %d, pc=%06x sr=%04x, %u frames drawn, %u game ticks\n", frame,
            m68k_get_reg(NULL, M68K_REG_PC), m68k_get_reg(NULL, M68K_REG_SR), rd32(rd32(dbg + 28)), rd32(rd32(dbg + 20)));
    if (getenv("NHL_BLITKINDS")) blitkind_print(rd32(rd32(dbg + 28)) - bk_frames0);
    if (getenv("NHL_STATS"))
        fprintf(stderr, "blitter from frame 1700: plane B %.1f M cycles, overlay %.1f M, sprites %.1f M, other %.1f M\n",
                blitstat[0] / 1e6, blitstat[1] / 1e6, blitstat[2] / 1e6, blitstat[3] / 1e6);
    if (getenv("NHL_STATS")) {   /* build with VASMFLAGS=-DSTATS=1 */
        uint32_t k = rd32(dbg + 72);
        fprintf(stderr, "renderer: sprites built %u, sprite lines %u, ntW %u tiles %u\n", rd32(k), rd32(k + 4), rd32(k + 8), rd32(k + 12));
        fprintf(stderr, "renderer: plane B tile scans %u, cells %u, high lists %u; A rebuilds %u, overlay redraws %u, cell updates %u\n",
                rd32(k + 16), rd32(k + 20), rd32(k + 24), rd32(k + 28), rd32(k + 32), rd32(k + 36));
        fprintf(stderr, "renderer: sprite cache waits (an image in use written over) %u, HUD sprite builds %u\n",
                rd32(k + 56), rd32(k + 60));
        fprintf(stderr, "renderer: plane B restored: %u words, %u blits, %u groups of rows; HUD cells made again %u\n",
                rd32(k + 68), rd32(k + 64), rd32(k + 84), rd32(k + 88));
        fprintf(stderr, "renderer: DMA words %u, of them sprite tiles %u\n", rd32(k + 92), rd32(k + 96));
        fprintf(stderr, "renderer: objects drawn as one image %u, their images built %u\n", rd32(k + 100), rd32(k + 104));
        fprintf(stderr, "renderer: blits listed %u, drawn %u; listings ended half way %u; objects as in the frame before %u\n",
                rd32(k + 112), rd32(k + 116), rd32(k + 108), rd32(k + 120));
        fprintf(stderr, "renderer: object images built again (the ring came round) %u\n", rd32(k + 124));
        fprintf(stderr, "renderer: sprite images built: not in the table %u, the ring came round %u, a tile converted %u\n",
                rd32(k + 72), rd32(k + 76), rd32(k + 80));
        fprintf(stderr, "renderer: name table hits: tiles %u (last block %x), data port %u (last %x)\n",
                rd32(k + 40), rd32(k + 44), rd32(k + 48), rd32(k + 52));
    }
    {                                   /* VERIFY builds: the scroll buffers' self-check */
        uint32_t v = rd32(rd32(dbg + 76));
        if (v) fprintf(stderr, "renderer self-check failed: frame drawn %u, map row %u, column %u\n",
                       v >> 16, (v >> 8) & 255, v & 255);
    }
    for (int i = 0; i < pcc_k; i++) fprintf(stderr, "pc %06x ran %lld times\n", pcc_addr[i], pcc_n[i]);
    if (getenv("NHL_PEEK")) {           /* NHL_PEEK=address: a word there at the end */
        uint32_t a = strtoul(getenv("NHL_PEEK"), NULL, 16);
        fprintf(stderr, "peek %06x: %04x\n", a, rd16(a));
    }
    if (getenv("NHL_MEM")) {            /* NHL_MEM=address:length:file (hex address, length) */
        uint32_t ad = 0, ln = 0; char fn[256];
        if (sscanf(getenv("NHL_MEM"), "%x:%x:%255s", &ad, &ln, fn) == 3) {
            FILE *f = fopen(fn, "wb");
            fwrite(mem + (ad & 0xFFFFFF), 1, ln, f);
            fclose(f);
        }
    }
    if (getenv("NHL_DUMP")) {
        FILE *f = fopen(getenv("NHL_DUMP"), "wb");
        fwrite(mem + (rd32(dbg + 48) & 0xFFFFFF), 1, 4096 * 32, f);
        fwrite(mem + (rd32(dbg + 52) & 0xFFFFFF), 1, 4096 * 8, f);
        fwrite(mem + (rd32(dbg + 56) & 0xFFFFFF), 1, 4096, f);
        fwrite(mem + (vram & 0xFFFFFF), 1, 0x10000, f);
        fwrite(mem + (rd32(dbg + 36) & 0xFFFFFF), 1, 2048 * 48, f);
        fwrite(mem + (vdpregs & 0xFFFFFF), 1, 32, f);
        fwrite(mem + (rd32(dbg + 60) & 0xFFFFFF), 1, 288 * 224, f);
        fwrite(mem + (rd32(dbg + 64) & 0xFFFFFF), 1, 48 * 224 * 2, f);
        fwrite(mem + (rd32(dbg + 68) & 0xFFFFFF), 1, 256, f);
        fclose(f);
    }
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

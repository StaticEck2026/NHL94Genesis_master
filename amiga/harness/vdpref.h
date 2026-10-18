#ifndef VDPREF_H
#define VDPREF_H
#include <stdint.h>
int vdpref_render(uint8_t *out, int *w, int *h, const uint8_t *regs, const uint8_t *vram,
                  const uint8_t *cram, const uint8_t *vsram);
int vdpref_png(const char *name, const uint8_t *regs, const uint8_t *vram, const uint8_t *cram,
               const uint8_t *vsram);
int png_write(const char *name, const uint8_t *rgb, int w, int h);
#endif

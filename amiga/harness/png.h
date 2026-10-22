#ifndef NHL_PNG_H
#define NHL_PNG_H
#include <stdint.h>
int png_write(const char *name, const uint8_t *rgb, int w, int h);
#endif

# Test harness: build with  make MUSASHI=/path/to/Musashi  (objects built there with its Makefile)
MUSASHI ?= /opt/amiga/musashi
CFLAGS = -O2 -g -Wall -I$(MUSASHI)
OBJS = $(MUSASHI)/m68kcpu.o $(MUSASHI)/m68kops.o $(MUSASHI)/m68kdasm.o $(MUSASHI)/softfloat/softfloat.o

nhlrun: nhlrun.c vdpref.c vdpref.h
	$(CC) $(CFLAGS) -o $@ nhlrun.c vdpref.c $(OBJS) -lz -lm

clean:
	rm -f nhlrun

# make MUSASHI=/path/to/Musashi (the core is built with its instruction hook and interrupt acknowledge callback)
MUSASHI ?= /opt/amiga/musashi
CFLAGS = -O2 -g -Wall -I$(MUSASHI)
CORE = -DM68K_INSTRUCTION_HOOK=M68K_OPT_ON -DM68K_EMULATE_INT_ACK=M68K_OPT_ON -O2 -I$(MUSASHI) -w
OBJS = m68kcpu.o m68kops.o m68kdasm.o softfloat.o

nhlrun: nhlrun.c png.c png.h $(OBJS)
	$(CC) $(CFLAGS) -DNHL_HOOK -o $@ nhlrun.c png.c $(OBJS) -lz -lm

m68kcpu.o: $(MUSASHI)/m68kcpu.c
	$(CC) $(CORE) -c -o $@ $<
m68kops.o: $(MUSASHI)/m68kops.c
	$(CC) $(CORE) -c -o $@ $<
m68kdasm.o: $(MUSASHI)/m68kdasm.c
	$(CC) $(CORE) -c -o $@ $<
softfloat.o: $(MUSASHI)/softfloat/softfloat.c
	$(CC) $(CORE) -c -o $@ $<

clean:
	rm -f nhlrun $(OBJS)

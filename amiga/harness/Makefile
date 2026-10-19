# Test harness: build with  make MUSASHI=/path/to/Musashi  (its sources: the CPU core is built
# here with the instruction hook and the interrupt acknowledge callback on, for NHL_DETERM)
MUSASHI ?= /opt/amiga/musashi
CFLAGS = -O2 -g -Wall -I$(MUSASHI)
CORE = -DM68K_INSTRUCTION_HOOK=M68K_OPT_ON -DM68K_EMULATE_INT_ACK=M68K_OPT_ON -O2 -I$(MUSASHI) -w
OBJS = m68kcpu.o m68kops.o m68kdasm.o softfloat.o

nhlrun: nhlrun.c vdpref.c vdpref.h $(OBJS)
	$(CC) $(CFLAGS) -DNHL_HOOK -o $@ nhlrun.c vdpref.c $(OBJS) -lz -lm

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

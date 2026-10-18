#!/bin/sh
# Build the Amiga 1200 version: convert src/ into output/amiga/src, then assemble with vasm.
set -e
cd "$(dirname "$0")/.."
VASM=${VASM:-vasmm68k_mot}
command -v "$VASM" >/dev/null 2>&1 || VASM=/opt/amiga/vasm/vasmm68k_mot
node tools/prebuild.js retail >/dev/null
rm -rf output/amiga/src
mkdir -p output/amiga
python3 amiga/tools/convert.py output/amiga/src
cp amiga/src/*.asm amiga/src/*.i output/amiga/src/
# The FM patches as samples (kept: they only change with the patches or the renderer)
FMI=output/amiga/fm_patches.i
if [ ! -f $FMI ] || [ amiga/tools/fmrender.py -nt $FMI ] || [ Extracted/NHL94/Sound/fm_instrument_patches.bin -nt $FMI ]; then
  python3 -c 'import numpy' 2>/dev/null || { echo "build.sh: fmrender.py needs numpy (pip install numpy)"; exit 1; }
  python3 amiga/tools/fmrender.py Extracted/NHL94/Sound $FMI
fi
cp $FMI output/amiga/src/fm_patches.i
cd output/amiga/src
# Twice: the second time with the list of the places that hold RAM window addresses, which
# ramrel.py takes from the first (its hunk is the last, so the others do not move).
HUNKS="hal_header bss_start chip_start sndchip_start RAMBASE ram_relocs"
printf 'ram_relocs\n\tdc.l\t0\n' > ramrel.i
"$VASM" -Fhunkexe -m68020 -nocase -quiet $VASMFLAGS -o ../nhl94.game nhl94_amiga.asm
python3 ../../../amiga/tools/ramrel.py ../nhl94.game 4 ramrel.i $HUNKS
"$VASM" -Fhunkexe -m68020 -nocase -quiet $VASMFLAGS -o ../nhl94.game -L ../nhl94.lst nhl94_amiga.asm
python3 ../../../amiga/tools/ramrel.py ../nhl94.game 4 ramrel2.i $HUNKS >/dev/null
cmp -s ramrel.i ramrel2.i || { echo "build.sh: the RAM window places moved between the passes"; exit 1; }
ls -l ../nhl94.game
"$VASM" -Fhunkexe -m68000 -nocase -quiet -o ../NHL94 stub.asm
ls -l ../NHL94
python3 ../../../amiga/tools/mkicon.py ../NHL94.info
# A bootable hard drive image (one FFS partition, no RDB) for emulators: needs xdftool
# (pip install amitools). Its startup-sequence starts the game.
XDFTOOL=${XDFTOOL:-xdftool}
if command -v "$XDFTOOL" >/dev/null 2>&1; then
  printf 'NHL94\n' > startup-sequence
  rm -f ../nhl94.hdf
  "$XDFTOOL" ../nhl94.hdf create size=2Mi + format NHL94 ffs + makedir S \
    + write startup-sequence S/startup-sequence + write ../NHL94 NHL94 + write ../NHL94.info NHL94.info \
    + write ../nhl94.game NHL94.game >/dev/null
  ls -l ../nhl94.hdf
else
  echo "(no xdftool: nhl94.hdf not made; pip install amitools)"
fi

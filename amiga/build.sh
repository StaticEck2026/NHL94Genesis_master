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
python3 amiga/tools/fmrender.py Extracted/NHL94/Sound output/amiga/src/fm_patches.i
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
"$VASM" -Fhunkexe -m68020 -nocase -quiet -o ../NHL94 stub.asm
ls -l ../NHL94
python3 ../../../amiga/tools/mkicon.py ../NHL94.info

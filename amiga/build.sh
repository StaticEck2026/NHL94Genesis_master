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
cd output/amiga/src
"$VASM" -Fhunkexe -m68020 -nocase -quiet -o ../nhl94.game -L ../nhl94.lst nhl94_amiga.asm
ls -l ../nhl94.game

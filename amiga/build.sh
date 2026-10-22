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
# The build number: the commits on this branch (and the commit, + if the sources differ from
# it). It names the disk images and their volumes and is in the launcher's version string.
BUILDNO=$(git rev-list --count HEAD 2>/dev/null || echo 0)
BUILDID=$(git rev-parse --short HEAD 2>/dev/null || echo none)
git diff --quiet HEAD -- amiga src tools 2>/dev/null || BUILDID="$BUILDID+"
printf 'BUILDNO\tequ\t%s\nbuildver\tdc.b\t"$VER: NHL94 b%s (%s)",0\n' "$BUILDNO" "$BUILDNO" "$BUILDID" \
  > output/amiga/src/build.i
# The FM patches and the PCM sounds as samples (kept: they only change with their sources or
# the tools)
FMI=output/amiga/fm_patches.i
if [ ! -f $FMI ] || [ amiga/tools/fmrender.py -nt $FMI ] || [ Extracted/NHL94/Sound/fm_instrument_patches.bin -nt $FMI ]; then
  python3 -c 'import numpy' 2>/dev/null || { echo "build.sh: fmrender.py needs numpy (pip install numpy)"; exit 1; }
  python3 amiga/tools/fmrender.py Extracted/NHL94/Sound $FMI
fi
cp $FMI output/amiga/src/fm_patches.i
PCMI=output/amiga/pcm.i
if [ ! -f $PCMI ] || [ amiga/tools/pcmrender.py -nt $PCMI ] || [ src/sound94.asm -nt $PCMI ]; then
  python3 amiga/tools/pcmrender.py src/sound94.asm Extracted/NHL94/Sound $PCMI
fi
cp $PCMI output/amiga/src/pcm.i
# The pictures of the EA Sports, title and game setup screens, deflated (inflated into a window
# only while their screen is shown: fe_open)
python3 amiga/tools/fepack.py Extracted/NHL94/Graphics output/amiga/src/fe.i
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
  rm -f ../nhl94.hdf ../nhl94-b*.hdf ../nhl94-b*.adf
  "$XDFTOOL" ../nhl94.hdf create size=2Mi + format NHL94-b$BUILDNO ffs + makedir S \
    + write startup-sequence S/startup-sequence + write ../NHL94 NHL94 + write ../NHL94.info NHL94.info \
    + write ../nhl94.game NHL94.game >/dev/null
  cp ../nhl94.hdf ../nhl94-b$BUILDNO.hdf
  ls -l ../nhl94.hdf ../nhl94-b$BUILDNO.hdf
  # A bootable 880 KB floppy: the game packed (pack.py), the launcher loads it
  python3 ../../../amiga/tools/pack.py ../nhl94.game ../NHL94.pak
  rm -f ../nhl94.adf
  "$XDFTOOL" ../nhl94.adf create + format NHL94-b$BUILDNO ffs + boot install + makedir S \
    + write startup-sequence S/startup-sequence + write ../NHL94 NHL94 + write ../NHL94.info NHL94.info \
    + write ../NHL94.pak NHL94.pak >/dev/null
  cp ../nhl94.adf ../nhl94-b$BUILDNO.adf
  ls -l ../nhl94.adf ../nhl94-b$BUILDNO.adf
else
  echo "(no xdftool: nhl94.hdf and nhl94.adf not made; pip install amitools)"
fi
# An LHA archive to unpack onto a hard drive: a drawer NHL94 (the launcher, its icon and the
# game) and the drawer's icon, level 1 headers, -lh5-. Needs an lha that makes archives, as LHa
# for UNIX does (LHA=its path: the lha of lhasa only unpacks).
LHA=${LHA:-lha}
rm -rf lhastage ../nhl94.lha ../nhl94-b*.lha
mkdir -p lhastage/NHL94
cp ../NHL94 ../NHL94.info ../nhl94.game lhastage/NHL94/
chmod 755 lhastage/NHL94/NHL94 lhastage/NHL94/nhl94.game
chmod 644 lhastage/NHL94/NHL94.info
python3 ../../../amiga/tools/mkicon.py lhastage/NHL94.info drawer
if (cd lhastage && "$LHA" -ao51q2 ../../nhl94.lha NHL94.info NHL94/NHL94 NHL94/NHL94.info NHL94/nhl94.game) \
    >/dev/null 2>&1 && [ -f ../nhl94.lha ]; then
  cp ../nhl94.lha ../nhl94-b$BUILDNO.lha
  ls -l ../nhl94.lha ../nhl94-b$BUILDNO.lha
else
  rm -f ../nhl94.lha
  echo "(no lha that makes archives: nhl94.lha not made; LHA=the path of LHa for UNIX)"
fi
rm -rf lhastage

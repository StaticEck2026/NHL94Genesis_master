#!/bin/sh
# Run the Amiga build in FS-UAE (A1200, AROS ROM unless KICK is set) on a virtual X display and
# take screenshots.  uaerun.sh <seconds> <outdir> [key events: "t:key" pairs, t in seconds]
# Needs: fs-uae, Xvfb, ImageMagick (import), xdotool.
set -e
SECS=${1:-30}; OUT=${2:-/tmp/uae-shots}; shift 2 || true
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
W=${UAEWORK:-/tmp/uaework}
mkdir -p "$W/hd/S" "$W/base" "$W/logs" "$OUT"
cp "$ROOT/output/amiga/nhl94.game" "$W/hd/NHL94.game"
cp "$ROOT/output/amiga/NHL94" "$W/hd/NHL94"
printf 'NHL94\n' > "$W/hd/S/startup-sequence"
KICK=${KICK:-/opt/amiga/aros-amiga-m68k-rom.bin}
KEXT=${KEXT:-/opt/amiga/aros-amiga-m68k-ext.bin}
cat > "$W/run.fs-uae" <<CFG
[fs-uae]
amiga_model = ${MODEL:-A1200}
kickstart_file = $KICK
kickstart_ext_file = $KEXT
hard_drive_0 = $W/hd
hard_drive_0_label = NHL94
fullscreen = 0
window_width = 768
window_height = 576
audio_driver = null
base_dir = $W/base
logs_dir = $W/logs
${UAEEXTRA:-}
CFG
DISP=${UAEDISP:-:78}
if ! xdpyinfo -display $DISP >/dev/null 2>&1; then
  Xvfb $DISP -screen 0 1024x768x24 -nolisten tcp >/dev/null 2>&1 &
  sleep 2
fi
DISPLAY=$DISP fs-uae "$W/run.fs-uae" > "$W/fsuae.out" 2>&1 &
PID=$!
t=0
while [ $t -lt $SECS ]; do
  sleep 1; t=$((t+1))
  for ev in "$@"; do
    et=${ev%%:*}; key=${ev#*:}
    if [ "$et" = "$t" ]; then DISPLAY=$DISP xdotool search --class fs-uae windowactivate --sync key --delay 120 $key 2>/dev/null || DISPLAY=$DISP xdotool key $key; fi
  done
  if [ $((t % ${EVERY:-5})) -eq 0 ]; then DISPLAY=$DISP import -window root "$OUT/uae_$(printf %03d $t).png"; fi
done
kill $PID 2>/dev/null || true
sleep 1
echo "screenshots in $OUT"

#!/bin/sh
# golden.sh record|check GAME DIR [SESSION...]: scripted sessions of the game in the harness's
# deterministic mode (NHL_DETERM: every build plays the same game and draws every frame whole),
# with the Amiga screen saved at many frames. "record" keeps them in DIR as the reference;
# "check" plays them again and reports each frame whose screen is not the same, pixel for pixel.
# Sessions: attract (no input), menus (Start every 120 frames: title, setup, into a game, pauses),
# game (Start until the game begins, then play), tour (in a game, each item of the pause menu),
# playoffs (the setup screen set to the playoffs: the playoff tree, paged, then the matchups).
MODE=$1; GAME=$2; DIR=$3; shift 3
SESSIONS=${*:-attract menus game tour playoffs}
cd "$(dirname "$0")/../.." || exit 1
pads() {    # "from step to": Start pressed for 10 frames every step frames
    P=""; for f in $(seq "$1" "$2" "$3"); do P="$P$f:80,$((f+10)):0,"; done; echo "${P%,}"
}
tour() {    # into a game, then each item of the pause menu in turn: down to it, C, C back, Start
    P=$(pads 700 120 1180); t=2000
    for i in $(seq 1 13); do
        P="$P,$t:80,$((t+10)):0"; u=$((t+150))
        for k in $(seq 1 "$i"); do P="$P,$u:2,$((u+6)):0"; u=$((u+20)); done
        v=$((u+310)); w=$((v+150))
        P="$P,$((u+10)):20,$((u+16)):0,$v:20,$((v+6)):0,$w:80,$((w+10)):0"; t=$((w+150))
    done
    echo "$P"
}
session() { # name: frames, shot step, pads
    case $1 in
    attract) echo "9000 30 0:0" ;;
    menus)   echo "6000 20 $(pads 700 120 3000)" ;;
    game)    echo "16000 40 $(pads 700 120 1180)" ;;
    tour)    echo "14200 20 $(tour)" ;;
    playoffs) echo "5200 10 700:80,710:0,2000:8,2006:0,2300:80,2310:0,2900:8,2906:0,3400:80,3410:0,3800:8,3806:0,4000:8,4006:0,4300:4,4306:0,4700:80,4710:0" ;;
    *)       echo "" ;;
    esac
}
bad=0
for S in $SESSIONS; do
    set -- $(session "$S")
    [ -n "$1" ] || { echo "no session $S"; exit 2; }
    F=$1; STEP=$2; P=$3
    OUT=$DIR/$S
    [ "$MODE" = check ] && OUT=$DIR/check_$S
    mkdir -p "${OUT:?}"
    rm -f "${OUT:?}"/*.png
    NHL_DETERM=1 amiga/harness/nhlrun -c 8000000 -f "$F" -S "$STEP" -p "$P" -o "$OUT" "$GAME" \
        > "$OUT/run.txt" 2>&1 || { echo "$S: the run failed"; tail -3 "$OUT/run.txt"; bad=1; continue; }
    rm -f "${OUT:?}"/shot_*.png         # (the reference renderer's: only the Amiga screens count)
    if [ "$MODE" = check ]; then
        python3 - "$DIR/$S" "$OUT" "$S" <<'EOF' || bad=1
import sys, glob, os
from PIL import Image, ImageChops
ref, new, name = sys.argv[1:4]
n = diff = 0
for f in sorted(glob.glob(os.path.join(ref, 'ami_*.png'))):
    g = os.path.join(new, os.path.basename(f))
    n += 1
    if not os.path.exists(g):
        print('%s: %s missing' % (name, os.path.basename(f))); diff += 1; continue
    a, b = Image.open(f).convert('RGB'), Image.open(g).convert('RGB')
    if a.size != b.size or ImageChops.difference(a, b).getbbox():
        if diff < 20: print('%s: %s differs' % (name, os.path.basename(f)))
        diff += 1
print('%s: %d screens, %d differ' % (name, n, diff))
sys.exit(1 if diff else 0)
EOF
    else
        echo "$S: $(ls "$OUT"/ami_*.png | wc -l) screens recorded"
    fi
done
exit $bad

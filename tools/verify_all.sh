#!/bin/bash
# verify_all.sh: top ROM + all segments under wine. Usage: tools/verify_all.sh
set -- "$(cd "$(dirname "$0")/.." && pwd)" build94.bat nhl94 lst/nhl94.bin
export WINEDEBUG=-all
cd "$1"; bat=$2; top=$3; ref=$4
# tools/prebuild.js runs here with Linux node (fresh extract, ROM check); the .bat files skip it (no node under wine).
export NHL_PREBUILD_DONE=1
rm -rf Extracted; node tools/prebuild.js retail >/tmp/x94.log 2>&1 || { echo "PREBUILD FAIL"; cat /tmp/x94.log; exit 1; }
fail=0
rm -f output/$top.bin output/modified_$top.bin
wine cmd /c "set rev=0&& set checksum=1&& $bat" >/tmp/top.log 2>&1
log=$(ls -t output/Build*.log | head -1)
grep -qP '^[1-9]\d* error' "$log" && { echo "TOP ERRORS in $log"; fail=1; }
if [ -s output/$top.bin ]; then
  node tools/fixopcodes.js "output/$top .lst" output/$top.bin >/dev/null 2>&1
  node tools/fixrom.js "output/$top .lst" output/modified_$top.bin || fail=1
  topr=$(node tools/verifyRom.js output/modified_$top.bin $ref 2>&1 | grep -iE 'match|differ' | head -2)
  echo "$topr"
  case "$topr" in
    MATCH:*) ;;
    *) fail=1 ;;
  esac
else
  echo "TOP NO BIN"
  fail=1
fi
for s in $(node -e 'for(const k in require("./package.json").scripts) if(/^seg:/.test(k)&&!/-data$/.test(k)) console.log(k)'); do
  cmd=$(node -e "console.log(require('./package.json').scripts['$s'])")
  seg=$(echo "$cmd" | grep -oP 'buildseg.bat \K\S+' | sed 's/.*\\//')
  rm -f output/$seg.bin
  ok=1
  IFS=$'\n'; for part in $(echo "$cmd" | sed 's/ && /\n/g'); do
    part=$(echo "$part" | sed -E 's/^(set [A-Za-z_]+=[^&]*&& )+//')
    case "$part" in
      npm*) ;;
      buildseg*) wine cmd /c "$part" >/tmp/seg.log 2>&1; [ -s output/$seg.bin ] || { echo "$s: NO BIN"; ok=0; fail=1; } ;;
      node\ tools/verifySegment*) r=$(eval "$(echo "$part" | tr '\\' '/')" 2>&1 | grep -iE 'match|differ|fail' | head -1); echo "$s: $r"; case "$r" in MATCH:*) ;; *) fail=1 ;; esac ;;
      node*) eval "$(echo "$part" | tr '\\' '/')" >/dev/null 2>&1 ;;
    esac
  done; unset IFS
  grep -qP '^[1-9]\d* error' output/Build_$seg.log 2>/dev/null && { echo "$s: ASM ERRORS"; fail=1; }
done
if [ "$fail" = 1 ]; then
  echo "VERIFY FAILED"
  exit 1
fi
echo "ALL MATCH"
exit 0

#!/bin/bash
# verify_all.sh: top ROM + all segments under wine. Usage: tools/verify_all.sh
export WINEDEBUG=-all
cd "$(dirname "$0")/.."
# Fresh extract, then tools/build.js for the full ROM and every segment in tools/segments.json.
rm -rf Extracted; node tools/prebuild.js retail >/tmp/x94.log 2>&1 || { echo "PREBUILD FAIL"; cat /tmp/x94.log; exit 1; }
fail=0
node tools/build.js retail | tee /tmp/top.log
grep -q '^\[5/5\] verify     MATCH' /tmp/top.log || fail=1
for s in $(node -e 'console.log(Object.keys(require("./tools/segments.json")).join("\n"))'); do
  r=$(node tools/build.js --seg $s)
  last=$(echo "$r" | tail -1)
  case "$last" in
    "[5/5] verify     MATCH"*) echo "$s: ${last#*(}" | sed 's/)$//' ;;
    *) echo "$s: FAILED"; echo "$r"; fail=1 ;;
  esac
done
if [ "$fail" = 1 ]; then
  echo "VERIFY FAILED"
  exit 1
fi
echo "ALL MATCH"
exit 0

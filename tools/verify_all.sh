#!/bin/bash
# verify_all.sh: top ROM + all segments under wine. Usage: tools/verify_all.sh [-q|--quiet]
# -q: print only failures and the final ALL MATCH / VERIFY FAILED line.
export WINEDEBUG=-all
cd "$(dirname "$0")/.."
quiet=0; case "$1" in -q|--quiet) quiet=1;; esac
# Fresh extract, then tools/build.js for the full ROM and every segment in tools/segments.json.
rm -rf Extracted; node tools/prebuild.js retail >/tmp/x94.log 2>&1 || { echo "PREBUILD FAIL"; cat /tmp/x94.log; exit 1; }
fail=0
node tools/build.js retail >/tmp/top.log
[ $quiet = 1 ] || cat /tmp/top.log
grep -qE '^ +MATCH ' /tmp/top.log || { fail=1; [ $quiet = 1 ] && cat /tmp/top.log; }
for s in $(node -e 'console.log(Object.keys(require("./tools/segments.json")).join("\n"))'); do
  r=$(node tools/build.js --seg $s)
  last=$(echo "$r" | grep -E "^ +MATCH ")
  case "$last" in
    *MATCH*) [ $quiet = 1 ] || { echo "$s: ${last#*(}" | sed 's/)$//'; } ;;
    *) echo "$s: FAILED"; echo "$r"; fail=1 ;;
  esac
done
if [ "$fail" = 1 ]; then
  echo "VERIFY FAILED"
  exit 1
fi
echo "ALL MATCH"
exit 0

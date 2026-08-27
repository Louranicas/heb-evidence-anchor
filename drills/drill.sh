#!/usr/bin/env bash
# Live enforcement drill against the OFF-HOST anchor remote.
# Mirrors r68's local file:// drill, but against a real remote over HTTPS.
# Every mutation attempt must be REFUSED SERVER-SIDE; the tip must not move.

set -uo pipefail
R=https://github.com/Louranicas/heb-evidence-anchor.git
W=$(mktemp -d /tmp/anchor-drill.XXXXXX)
cd "$W" || exit 1

say() { printf '\n========== %s ==========\n' "$1"; }

say "PROVISION"
git clone -q "$R" repo && cd repo || exit 1
git config user.name Louranicas; git config user.email lukeomahoney@gmail.com
BASE=$(git rev-parse HEAD)
echo "cloned tip: $BASE"

say "STEP 1 (append / fast-forward)  [expect GREEN]"
echo "drill $(date -u +%FT%TZ)" > .drill-probe
git add .drill-probe && git commit -q -m "drill: append probe"
git push origin main 2>&1 | tail -3
APPEND=$(git rev-parse HEAD)
echo "server tip now: $(git ls-remote origin main | cut -f1)"

say "STEP 2 (force-push / history rewrite)  [expect RED]"
git commit -q --amend -m "drill: REWRITTEN history (must be refused)"
git push --force origin main 2>&1 | tail -6
echo "server tip after: $(git ls-remote origin main | cut -f1)"
echo "unchanged vs append? $([ "$(git ls-remote origin main | cut -f1)" = "$APPEND" ] && echo YES || echo NO)"

say "STEP 3 (branch deletion)  [expect RED]"
git push origin --delete main 2>&1 | tail -6
echo "server tip after: $(git ls-remote origin main | cut -f1)"
echo "branch still present? $([ -n "$(git ls-remote origin main)" ] && echo YES || echo NO)"

say "STEP 4 (non-linear history / merge commit)  [expect RED]"
git reset -q --hard "$APPEND"
git checkout -q -b side "$BASE"
echo side > .side && git add .side && git commit -q -m "drill: side branch"
git checkout -q main
git merge -q --no-ff side -m "drill: merge commit (must be refused)" 2>/dev/null
git push origin main 2>&1 | tail -6
echo "server tip after: $(git ls-remote origin main | cut -f1)"
echo "unchanged vs append? $([ "$(git ls-remote origin main | cut -f1)" = "$APPEND" ] && echo YES || echo NO)"

say "STEP 5 (cold clone read-back)  [expect GREEN]"
cd "$W" && git clone -q "$R" cold
echo "cold tip:  $(git -C cold rev-parse HEAD)"
echo "append tip:$APPEND"
echo "byte-match: $([ "$(git -C cold rev-parse HEAD)" = "$APPEND" ] && echo YES || echo NO)"
echo "anchor record intact: $(ls cold/anchors/ | wc -l) record(s)"

say "DRILL COMPLETE"
rm -rf "$W"

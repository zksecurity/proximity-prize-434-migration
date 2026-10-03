#!/usr/bin/env bash
# Verify a migrated production submission inside the v20 release image, at the
# score it held before the upgrade. The claim is parsed and the challenge
# rendered by the image's own worker, so this is the trusted path, not a
# transcription of it.
set -uo pipefail
export HOME=/home/runner
export PATH=/home/runner/.elan/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CH="${CH:?set CH}"; FIX="${FIX:?set FIX}"
SUBDIR=$(python3 -c "
import sys; sys.path.insert(0,'/opt/zkgolf-proximity')
import worker; print(next(x for x in worker.PROFILES if x.name=='$CH').submission_dir)")
P=/tmp/mig-$CH
rm -rf "$P"; cp -r /opt/zkgolf-proximity/project "$P"; chmod -R u+w "$P"
mkdir -p "$P/ProximityPrize/$SUBDIR"
cp "$FIX"/*.lean "$P/ProximityPrize/$SUBDIR/"
echo "submission files: $(ls "$P/ProximityPrize/$SUBDIR" | wc -l)"
python3 - "$CH" "$FIX" > "$P/ProximityPrize/Benchmark/Challenge.lean" <<'PY'
import pathlib, sys
sys.path.insert(0, '/opt/zkgolf-proximity')
import worker
sel, fix = sys.argv[1], pathlib.Path(sys.argv[2])
p = next(x for x in worker.PROFILES if x.name == sel)
arg = (fix / p.claim_argument.file).read_bytes() if p.claim_argument else None
claim = worker.parse_claim_files(p, (fix / 'score.txt').read_bytes(), arg)
sys.stdout.write(worker.render_challenge(p, claim))
PY
echo "--- rendered claim ---"; grep -A2 "^theorem candidate" "$P/ProximityPrize/Benchmark/Challenge.lean"
cd "$P"
export COMPARATOR_LEAN4EXPORT=/opt/lean-checker/bin/lean4export
export COMPARATOR_LANDRUN=/opt/lean-checker/bin/landrun-wrap
echo "--- build $(date -u +%H:%M:%S) ---"
LEAN_NUM_THREADS=8 lake build ProximityPrize.Benchmark.Challenge "ProximityPrize.$SUBDIR.Solution" 2>&1 | tail -3
echo "--- comparator $(date -u +%H:%M:%S) ---"
OUT=$(lake env /opt/lean-checker/bin/comparator /opt/zkgolf-proximity/comparator.json 2>&1)
echo "$OUT" | tail -6
if echo "$OUT" | grep -q "Your solution is okay!"; then V=ACCEPTED; else V=REJECTED; fi
echo "MIGRATION-RESULT $CH: $V at score $(cat "$FIX"/score.txt) $(date -u +%H:%M:%S)"

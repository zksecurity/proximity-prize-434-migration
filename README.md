# Proximity Prize submissions, migrated to Lean 4.34.0

Production's two leading submissions as they stood before the 4.34 upgrade, ported
to Lean 4.34.0 with the new ArkLib and CompPoly pins and re-verified at the scores
they already held. The upgrade moves the toolchain, ArkLib and CompPoly together and
so invalidated both; without this the version bump would have shipped an empty
leaderboard.

| track | claim | score |
|---|---|---|
| `proximity-prize-reduction-lower` | `ProtocolClaim 6815 331366399 1073741824` | 68.15 bits |
| `proximity-prize-reduction-upper` | `ProtocolClaimUpper 11613 122369` | 116.13 bits |

The proofs are the entrants', unchanged in substance. The edits are confined to what
the new Mathlib and ArkLib renamed or re-stated underneath them, plus raised
elaboration budgets on five declarations; `git log` has the detail.

## Verifying

These are submission source trees, not a buildable project: the verifier composes
them with its own trusted template, which is where `ProximityPrize/Benchmark/` comes
from. `verify.sh` runs one track inside a release challenge image, letting the
image's own `worker.parse_claim_files` and `worker.render_challenge` read the claim
files and generate the challenge, so the claim is checked by the trusted path rather
than by a transcription of it.

```sh
docker run --rm -u 0:0 -v "$PWD:/dbg" \
  -e CH=reduction-lower -e FIX=/dbg/ProximityPrize/SubmissionLower \
  --entrypoint bash proximity-reduction-lower:434 /dbg/verify.sh
```

## Result

Run in the live `irs-reduction-threshold-v20` images (`sha256:b528d9d4…` and
`sha256:b65eeb89…`); logs in `evidence/`.

```
MIGRATION-RESULT reduction-lower: ACCEPTED at score 6815
MIGRATION-RESULT reduction-upper: ACCEPTED at score 11613
```

Each is a full cold kernel replay on the unpatched upstream Comparator `d03acab1`
with no `replay_exempt`, and `candidate` depends on exactly the three permitted
axioms `propext`, `Classical.choice` and `Quot.sound`. The lower track takes 2h25m
of CPU at a 2.9 GiB peak against the challenge's `timeout_seconds: 14400`.

These images pin `zksecurity/CompPoly@411708c`, whose KoalaBear Rabin certificates
are replay-safe. At the upstream revision the same replay does not terminate — see
[Verified-zkEVM/CompPoly#396](https://github.com/Verified-zkEVM/CompPoly/pull/396).

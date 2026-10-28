# Review — 20261028-area-personality

- **Track:** Area Personality Pass (cave & sunset deco) (`20261028-area-personality`)
- **Type:** feature — **Branch:** `feat/20261028-area-personality`
- **Range:** `7b56793..HEAD` (per-phase: `73a5253..1b3df58`, `c76c91a..804726a`; code only, `conductor/` excluded: 11 files, +572/−5)
- **Date:** 2026-10-28 — **Reviewer:** conductor-reviewer (read-only subagent) + primary validation
- **Verdict:** PASS WITH FINDINGS (strict mode: the single Low finding is fixed in R1 before PR)

## Summary

Cave/sunset personality pass is correct, fully tested, and preserves gameplay.
8 palette-bound deco assets (Phase 1) + 8 hand-placed validated bg props per
dressed area at `z_index = -10` with zero added collision (Phase 2). Meadow
byte-identical; tuning/audio/save/economy untouched. One Low finding only:
a stale asset-count comment.

## Verification

| Layer | Command | Result |
| --- | --- | --- |
| unit+coverage | `gd-tools test --coverage --min 80` | exit 0 — 404/404 pass; 94.7% lines, 94.0% branches (gate 80); 12 snapshots matched |
| lint | `gd-tools lint` | exit 0 — no issues |
| format | `gd-tools format --check` | exit 0 — all 73 files formatted |
| build | `godot --headless --import --path .` | exit 0 |
| visual | live editor session, per-area screenshots, smoke run, session stopped | distinct cave/sunset identity; HUD/gems/keys/door legible |
| typecheck | retired by workflow (editor LSP covers it) | n/a |

Evidence: `verification/phase-1.md`, `verification/phase-2.md`,
`verification/integrated.md`, `verification/screenshots/phase-2-*.png`.

## Requirements

Every FR/NFR/AC is covered by plan tasks + tests/evidence (reviewer confirmed,
no gaps):

| Req | Plan | Evidence | Status |
| --- | --- | --- | --- |
| FR-1 cave props | P2.T1 | placement tests + cave screenshot | covered |
| FR-2 sunset props | P2.T2 | placement tests + sunset screenshot | covered |
| FR-3 validated data | P2.T1.2/P2.T2.2 | `validate()` bounds/seating/determinism tests | covered |
| FR-4 decorative-only | P2.T3.1 | bg-layer + zero-collision tests | covered |
| FR-5 factory/spec | P1.T1–T4 | asset factory/spec/snapshot tests | covered |
| FR-6 no occlusion | P2.T4.1 | 24px halo tests + screenshots | covered |
| FR-7 preserve game | P2.T3.2 | meadow-empty + full suite (playthrough/goal/save) | covered |
| NFR-1 perf | design | static cached sprites, no per-frame cost | covered |
| NFR-2/3/4/5 | design | pixel-DSL only, snapshot-pinned, no tuning/text changes | covered |
| AC-1/AC-2 | P2.T4.2 | cave/sunset screenshots | covered |
| AC-3 | P2.T1–T3 | richness + meadow-empty tests | covered |
| AC-4 | P2.T4.1 | reachability/key-tier suite green | covered |
| AC-5 | P1.T4 | snapshot + spec-completeness tests | covered |
| AC-6 | P2.T4.1 | halo tests + screenshots | covered |
| AC-7 | integrated | full gate + live evidence, session stopped | covered |

## Findings

### F1 (Low) — stale asset-count comments

- **File:** `src/factory/asset_spec.gd:22` (and `tests/test_asset_spec.gd:7`)
- **What:** header comment still says `world tiles (8)` after Phase 1 brought
  the section to 16 entries; test docstring still says `(8 tiles, ...)`.
- **Why:** stale count misleads readers; code and tests already use 16.
- **Fix:** update both comments to the true counts.
- **Disposition:** fix in Phase R1 (mechanical, in scope; strict mode allows no deferral).

## Plan compliance

Compliant. Every `[x]` task implemented; no dropped tasks; diff stays within
the union of phase `Touches` (plus evidence/screenshots); no deviations.

## Out of scope

Screenshots reviewed as visual evidence only. Pre-existing notes carried, not
findings: cave/sunset spawn-adjacent key auto-collect (key count 1 at spawn;
data untouched, gameplay identical); `.import` sidecars of evidence PNGs
removed from worktree (regenerable editor cache, untracked).

## Debt

None. No deferred findings, no follow-up issues proposed.

## History

| Round | Verdict | Findings | Fixed |
| --- | --- | --- | --- |
| 1 | PASS WITH FINDINGS | 1 Low (F1) | R1 checkpoint `27a98b2` — F1 resolved, re-verified (lint/format/targeted suite green) |

## Doc sync

`pending` at review time → `none`: no product/tech-stack/guideline changes
required (purely additive decoration inside existing art direction).

## Overrides

None.

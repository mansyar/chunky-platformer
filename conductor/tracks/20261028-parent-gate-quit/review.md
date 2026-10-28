# Review: Parent Gate + Hold-to-Quit

- **Track:** `20261028-parent-gate-quit`
- **Type:** `feature`
- **Branch:** `feat/20261028-parent-gate-quit`
- **Range:** `3fe7534..797c3fa`
- **Date:** `2026-10-28`
- **Verdict:** `PASS`

## Summary

The hidden hold-to-quit parent gate fully meets FR-1..6 / NFR-1..4 /
AC-1..6 with 45 headless tests, a live ring screenshot, and clean gates.
The diff is purely additive (8 files, 853 insertions, zero deletions) and
stays inside the phases' Touches. No findings. Ready for completion and PR.

## Verification

| Layer | Command | Result | Evidence |
| --- | --- | --- | --- |
| test | `gd-tools test --coverage --min 80` | pass* | integrated.md: 433/434 twice, single pre-existing wall-clock flake in untouched audio code, 1/1 isolated in 0.03s |
| coverage | `gd-tools test --coverage --min 80` | pass | 94.1% lines / 92.7% branches ≥ 80 gate |
| lint | `gd-tools lint` | pass | clean |
| format | `gd-tools format --check` | pass | 76/76 formatted |
| typecheck | n/a (retired per workflow.md; editor LSP + suite) | n/a | — |
| build | `godot --headless --import --path .` | pass | clean import |
| visual | live screenshot | pass | `.conductor/evidence/phase-2-hold-ring.png` viewed by primary: white partial arc top-right, Meadow intact |
| smoke | `project_run` via godot-ai MCP | pass | started and stopped; completion path observed end-to-end (reported phase-2.md) |

\* "pass" with the documented flake: phase gates ran 434/434 and 419/419
green; integrated runs trip only the known
`test_pregeneration_at_startup_is_fast` timing assertion also seen on
earlier tracks. Not a regression; recorded, not silenced.

## Requirements

| ID | Implemented by | Verified by | Status |
| --- | --- | --- | --- |
| FR-1 | P1.T1 | `test_zone_is_top_right_corner_of_live_viewport`, `test_zone_tracks_resize_including_non_16_9` | covered |
| FR-2 | P1.T2, P1.T3 | `test_full_hold_fires_flush_then_quit_exactly_once`, `test_flush_failure_still_quits` | covered |
| FR-3 | P2.T1 | `test_ring_sweep_grows_with_progress`, `test_ticks_fire_each_interval_and_chime_completes`, ring screenshot | covered |
| FR-4 | P1.T2 | `test_release_before_hold_resets_silently`, `test_drift_outside_zone_resets`, `test_ring_clears_on_early_release` | covered |
| FR-5 | P1.T4 | `test_gameplay_only_traffic_never_starts_or_fires`, `test_gameplay_traffic_during_hold_neither_resets_nor_fires` | covered |
| FR-6 | P1.T3 | `test_esc_is_inert`, `test_mouse_hold_quits_and_cursor_drift_resets` | covered |
| NFR-1 | P1.T2 | ring-only feedback, no text anywhere in the flow | covered |
| NFR-2 | P2.T1 | constant alphas, sweep-only fill, no flashes | covered |
| NFR-3 | P2.T1 | smoke run clean; redraw only while holding (2 arcs) | covered |
| NFR-4 | P2.T1 | `"gem"` tick / `"door"` chime via AudioFactory, no new assets | covered |
| AC-1 | P1.T2, P1.T3 | `test_full_hold_fires_flush_then_quit_exactly_once` | covered |
| AC-2 | P1.T2 | release/drift reset tests | covered |
| AC-3 | P1.T4 | gameplay-traffic isolation tests | covered |
| AC-4 | P1.T1 | viewport + non-16:9 + mid-hold resize tests | covered |
| AC-5 | P2.T3 | full gate green + ring screenshot + smoke run stopped | covered |
| AC-6 | P1.T3 | `test_esc_is_inert` | covered |

## Findings

### Critical

- <none>

### High

- <none>

### Medium

- <none>

### Low

- <none>

## Overrides

- <none>

## Plan compliance

Both phases verified with Result/Checkpoint/Evidence; all 19 tasks `[x]`
and implemented (45 tests across two suites). Final diff stays within the
union of Touches (`src/input/quit_hold.gd`, `src/tuning/tuning.gd`,
`src/levels/game.gd` wire-up, `tests/test_quit_hold*.gd`) plus Godot
`.uid` companions. Accepted deviations: 1-line full-rect anchor fix;
`audio_manager.gd` untouched though wiring-only was allowed (smaller blast
radius — endorsed). Reviewer `needs` (diff stat) satisfied by primary:
8 files, 853 insertions, zero deletions — matches the reviewed scope.

## Out of scope

- Real-tablet long-press feel check: human-only follow-up per spec (filed as
  follow-up, not a finding).
- `TouchControls` 1280×720 hardcode and celebration polish remain with their
  own future tracks.

## Debt

- <none>

## Doc sync

`none` — user-approved: product.md v1.1 line left untouched (celebration
polish still pending), no tech-stack or guideline change.

## History

| Round | Verdict | Critical | High | Medium | Low | Fixed |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | PASS | 0 | 0 | 0 | 0 | 0 |

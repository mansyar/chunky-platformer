## Summary

Gives grown-ups a way out of the game that a 4-year-old will never trip: a
hidden top-right corner zone where a sustained 3-second stationary hold shows
a filling progress ring with soft synth ticks, then flushes the save and
exits the app. Gameplay input is never consumed and Esc stays inert.

## Track

- **ID:** `20261028-parent-gate-quit`
- **Type:** `feature`
- **Spec:** [`conductor/archive/20261028-parent-gate-quit/spec.md`](conductor/archive/20261028-parent-gate-quit/spec.md)
- **Plan:** [`conductor/archive/20261028-parent-gate-quit/plan.md`](conductor/archive/20261028-parent-gate-quit/plan.md)
- **Review:** [`conductor/archive/20261028-parent-gate-quit/review.md`](conductor/archive/20261028-parent-gate-quit/review.md)

## What happened

| Phase | Goal | Result | Checkpoint | Notes |
| --- | --- | --- | --- | --- |
| 1: Quit-hold core | 3s stationary in-zone hold flushes save and quits; release/drift resets silently | verified | `4ebd732` | 30 tests; test-first held |
| 2: Hold feedback + live proof | Filling ring + soft ticks + chime; live-editor proof | verified | `c22cef1` | 15 tests; 1-line full-rect anchor fix; ring screenshot + smoke run |

## Requirements

- [x] `FR-1` — invisible hold zone, extreme top-right, live viewport rect (test: `tests/test_quit_hold.gd`)
- [x] `FR-2` — 3s stationary hold fires save-flush then quit, exactly once (test: `tests/test_quit_hold.gd`)
- [x] `FR-3` — progress ring + soft ticks during hold, door-chime on completion (test: `tests/test_quit_hold_feedback.gd`)
- [x] `FR-4` — early release / drift resets silently, no residue (test: `tests/test_quit_hold.gd`)
- [x] `FR-5` — gameplay input never stolen, second finger neither resets nor fires (test: both suites)
- [x] `FR-6` — desktop mouse-hold quits; Esc inert (test: `tests/test_quit_hold.gd`)
- [x] `NFR-1` — zero text in the flow
- [x] `NFR-2` — gradual ring fill only, no flashes
- [x] `NFR-3` — redraw only while holding; negligible overlay cost
- [x] `NFR-4` — existing `"gem"` tick / `"door"` chime via AudioFactory, no new assets
- [x] `AC-1..AC-4, AC-6` — headless suite (see `verification/phase-1.md`)
- [x] `AC-5` — full gate green + ring screenshot + smoke run stopped

## Verification

| Layer | Command | Result | Evidence |
| --- | --- | --- | --- |
| unit | `gd-tools test --coverage --min 80` | pass* | `conductor/archive/20261028-parent-gate-quit/verification/integrated.md` |
| coverage | `gd-tools test --coverage --min 80` | pass | 94.1% lines / 92.7% branches ≥ 80 gate |
| lint | `gd-tools lint` | pass | clean |
| format | `gd-tools format --check` | pass | 76/76 formatted |
| build | `godot --headless --import --path .` | pass | clean import |
| visual | live `editor_screenshot` | pass | ring arc top-right over intact Meadow (see Media) |

\* Phase gates ran 434/434 and 419/419 green. Integrated runs show 433/434
with a single trip of the known pre-existing wall-clock flake
`test_pregeneration_at_startup_is_fast` (untouched audio code; 1/1 isolated
in 0.03s). Recorded in `integrated.md`, not silenced.

## Media

![Hold ring mid-fill at the top-right corner](https://github.com/user-attachments/assets/dd70f63f-c7fc-4f9a-aee1-07f7b41537f6)
Captured live from the running game at Phase 2 checkpoint `c22cef1` (source
tree unchanged since; camera zoomed to 0.5 for framing, restored after).

## Review

- **Verdict:** `PASS`
- **Rounds:** 1
- **Fixed:** 0 findings
- **Accepted/deferred:** 0

## Deviations and risks

- `quit_hold.gd` `_ready`: `set_anchors_preset` → full-rect preset (1 line;
  overlay was 0×0 live; tests already assumed full-rect). No risk.
- `audio_manager.gd` untouched though wiring-only was allowed — ticks/chime
  reuse AudioFactory directly (smaller blast radius, review-endorsed).
- Risk: zone feel on a real tablet (thumb reach, 64px radius) is untested —
  constants `QUIT_ZONE_RADIUS` / `QUIT_HOLD_SECONDS` are tunables; tablet
  long-press check is the planned human-only follow-up.

## Follow-ups

- Tablet long-press feel check (human-only, planned with device testing) — no issue filed (not a review finding)

## Rollback

```bash
# Squash commit
git revert --no-edit <squash-commit>
```

Purely additive (853 insertions, zero deletions); no migration, no feature
flag, no save-format change. Reverting restores the no-quit-path behavior.


# Phase 1 evidence — Quit-hold core (logic, headless-testable)

- Track: 20261028-parent-gate-quit — Parent Gate + Hold-to-Quit
- Phase: 1 (P1.T1 viewport zone, P1.T2 hold state machine, P1.T3 app wiring, P1.T4 input non-interference)
- Date: 2026-10-28
- Branch: feat/20261028-parent-gate-quit
- Base: 9a5fb2a5dc5a886cff11441a4876a2c3722e11d1
- Head: df7664b (commits: 1cbb1c4 feat, df7664b test)
- Result: **verified** (test + lint + format gates green; session-live check done, deeper live proof is Phase 2 scope)

## Commands

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| test | `gd-tools test --coverage --min 80` | 0 | 419/419 passed (404 existing + 15 new), 94.0% lines / 92.7% branches ≥ 80% gate |
| lint | `gd-tools lint` | 0 | No lint issues found |
| format | `gd-tools format --check` | 0 | All 75 files formatted (after one formatter pass on the new test file) |
| live | editor session check via godot-ai `session_manage` list | 0 | Session `chunky-platformer@4a3d57e57dfc27d7` live, Godot 4.7.2, readiness `ready`, play stopped; editor logs showed no errors from the new files. Beyond-session-live proof (screenshot, smoke) belongs to Phase 2 per the brief |

## Acceptance criteria

| ID | Criterion | Evidence | Status |
| --- | --- | --- | --- |
| AC-1 | 3s stationary in-zone hold fires save-flush then quit, unit-tested with a quit double | `test_full_hold_fires_flush_then_quit_exactly_once` (order `["flush","quit"]`, exactly once, no refire); `test_flush_failure_still_quits` (false return still quits) | pass |
| AC-2 | Early release / drift-outside resets silently: no quit, no residue | `test_release_before_hold_resets_silently`, `test_drift_outside_zone_resets`, progress back to 0, no calls | pass |
| AC-3 | Walk-hold + jump-tap traffic during/around a hold never fires and gameplay stays intact | `test_gameplay_only_traffic_never_starts_or_fires`, `test_gameplay_traffic_during_hold_neither_resets_nor_fires` (second finger ignored, hold completes) | pass |
| AC-4 | Zone = extreme top-right circle of the live viewport rect, incl. non-16:9 resizes | `test_zone_is_top_right_corner_of_live_viewport`, `test_zone_tracks_resize_including_non_16_9` (720p, portrait 720×1280, ultrawide 2560×1080), `test_resize_mid_hold_resets_when_holder_leaves_zone` | pass |
| AC-5 | Full gate green + live-editor screenshot + smoke proof | Out of scope: ring UI, audio, and live proof are Phase 2 (brief) | deferred to Phase 2 |
| AC-6 | Esc is inert: never quits, never disturbs a hold | `test_esc_is_inert_alone_and_mid_hold` | pass |

Tunables pinned: `Tuning.QUIT_ZONE_RADIUS` = 64.0, `Tuning.QUIT_HOLD_SECONDS` = 3.0
(`test_zone_defaults_come_from_tuning`). Production wiring pinned:
`test_game_wires_quit_hold_with_save_flush` (Game owns `QuitHold`, `save_flush`
bound to `Game._save`, `quit_call` unbound → `get_tree().quit()` path).

## Evidence paths

- `tests/test_quit_hold.gd` (15 tests) + `tests/test_quit_hold.gd.uid`
- `src/input/quit_hold.gd` (+ `.uid`), `src/tuning/tuning.gd`, `src/levels/game.gd` (wire-up only)
- Latest green run artifacts: `.gd-tools/artifacts/0681a10900d446649391ed67ce034346/artifacts.json`
- This report: `conductor/tracks/20261028-parent-gate-quit/verification/phase-1.md`

## Deviations

- Ran `gd-tools format` (write mode) once to satisfy the `format --check` gate; it touched
  only the new `tests/test_quit_hold.gd`. It is a configured project command but outside the
  brief's exact verification list, so it is recorded here.
- `git branch --show-current` was denied by the sandbox; the branch name above is taken from
  the phase brief (commit output confirms `feat/20261028-parent-gate-quit`).
- Stray untracked `.import` files under `conductor/archive/.../screenshots/` (editor-generated,
  pre-existing) were left untouched — outside Touches.

## Notes

- The gate never consumes input: `_input` only observes, Esc/keys/joypad/second-finger are
  explicitly ignored, and no `set_input_as_handled` call exists anywhere in the new code.
- Test-first held: the suite was written first and failed to load until the implementation
  landed. One engine quirk found on the way: a `Key`-typed helper parameter rejects `KEY_*`
  constants at parse time ("Value of type Key cannot be assigned to a variable of type Key"),
  so the suite simulates keys with an untyped `int` parameter assigned to `keycode`, matching
  the existing `test_input_layer.gd` pattern. Worth knowing for Phase 2 tests.
- `get_tree().quit()` is never called in tests: the quit path is always a recording spy;
  production default (`_default_quit`) is only reached when `quit_call` is unbound (Game wiring).

## Primary verification

- Working tree clean (3 regenerable editor `.import` sidecars under
  `conductor/archive/` screenshots removed; untracked, never committed).
- Diff `9a5fb2a..HEAD` = exactly the 3 reported commits
  (`1cbb1c4`, `df7664b`, `8df2061`); 7 files, all inside Touches
  (+ Godot `.uid` companions + this evidence file). No merge/foreign commits.
- Independent runs on the unchanged tree: `gd-tools test --coverage --min 80`
  → 419/419 passed, 94.0% lines / 92.7% branches ≥ 80 gate, 12 snapshots
  matched (61.36s, no flake); `gd-tools lint` → exit 0; `gd-tools format
  --check` → 75/75 formatted.
- AC-1/2/3/4/6 evidenced by named tests in the table above; AC-5 correctly
  deferred to Phase 2 per the plan. Format write-mode deviation accepted
  (smallest necessary change, new file only).
- Result: Phase 1 **verified**.

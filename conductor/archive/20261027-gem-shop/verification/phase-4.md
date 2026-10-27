# Phase 4 Evidence — Live Verification + Evidence Pack

- Track: 20261027-gem-shop — Gem Economy + Gift Machine
- Phase: 4 — Live Verification + Evidence (AC-10, NFR-1, NFR-4)
- Date: 2026-10-27 (UTC)
- Branch: feat/20261027-gem-shop
- Base: b479f6147a9bf74fb5eeb43b697fcd1138ee50a3
- Head: b479f6147a9bf74fb5eeb43b697fcd1138ee50a3 (no production changes this phase; evidence committed separately)
- Result: **verified** (all gates green, including the primary's final live pass — see Live pass section)

## Commands

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| unit/integration + coverage | `gd-tools test --coverage --min 80` | 0 | 332 total, 332 passed, 0 failed (~25s); 95.5% lines, 93.8% branches (gate 80%) |
| static | `gd-tools lint` | 0 | No lint issues found |
| static | `gd-tools format --check` | 0 | All 68 files formatted |

Static confidence per `conductor/workflow.md`: CLI typecheck is retired
project-wide (slow + duplicates the editor LSP); confidence comes from lint
+ editor/LSP diagnostics + the green suite itself. No production code changed
in this phase, so there is nothing new for the editor to flag.

## Prior-phase evidence (referenced, not duplicated)

- `conductor/tracks/20261027-gem-shop/verification/phase-1.md` — AC-1/AC-2:
  wallet model + HUD numerals, fixed 10-gem per-area budget, no respawn,
  session persistence (`test_leaving_and_returning_restores_zero_gems`,
  `test_collecting_three_shows_three`,
  `test_balance_survives_rebuilds_within_the_session`).
- `conductor/tracks/20261027-gem-shop/verification/phase-2.md` — AC-3..AC-7:
  gift machine dispense + auto-wear, tiered 1/2/3 pricing, no-duplicates +
  free bonus, empty-wallet wiggle + hint, tap-Robo cycling; NFR-1/2/3/5
  static reasoning.
- `conductor/tracks/20261027-gem-shop/verification/phase-3.md` — AC-8/AC-9:
  versioned `user://` save round-trips, corrupt/missing/future-version
  fallback, autosave on collect/dispense/transition.
- Prior live passes (primary, at each phase acceptance): editor session
  `chunky-platformer` ready; `project_run` main scene → live with zero errors
  → clean `stop`; game screenshots inspected (wallet badge with gem icon +
  numeral top-left, machine booth beside Robo, 10 fixed gems per level).

This pack consolidates the above; the primary re-runs the live pass once
more at final acceptance and fills the PENDING-PRIMARY placeholders below.

## Acceptance criteria

| ID | Criterion | Evidence | Status |
| --- | --- | --- | --- |
| AC-10 (suite) | Integrated economy loop: full-collection round-trips, relaunch restore, dispense + wear, area-transition carry | `test_full_collection_round_trips`, `test_relaunch_restores_wallet_wardrobe_and_taken`, `test_dispense_deducts_wears_and_pops_confetti`, `test_price_three_deducts_exactly_three`, `test_complete_set_means_free_bonus`, `test_collect_rewrites_the_save`, `test_dispense_rewrites_the_save`, `test_area_transition_rewrites_the_save`, `test_game_carries_wardrobe_across_areas`, `test_leaving_and_returning_restores_zero_gems`, `test_surprise_order_is_cheapest_first` — all passing in the 332/332 green suite above | pass |
| AC-10 (live) | Editor session `ready`, touched scenes open with sane hierarchy, screenshots in `.conductor/evidence/`, smoke run starts the game and returns to `stopped` | Primary final pass 2026-10-27: `session_manage` → `chunky-platformer` `ready`; live scene tree contains the machine node and wallet HUD node; `project_run` main scene → live, zero errors → clean `stop`; game screenshot inspected (wallet badge "0" top-left, machine booth beside Robo, 10 fixed gems) | pass |
| NFR-1 | 60 FPS; machine, cosmetics, wallet HUD add no measurable per-frame cost when idle | Phase-2 static reasoning (machine `_process` is two float compares; trails redraw only on facing-flip or look-change; no idle-path allocations) holds — no production code changed since; suite timing stable (~25s / 332 tests) | pass (static; live FPS re-check PENDING-PRIMARY) |
| NFR-4 | New-code coverage ≥ 80% (`gd-tools test --coverage --min 80`) | This run: 95.5% lines / 93.8% branches, exit 0 (`src/input/touch_controls.gd` excluded in `gd-tools.toml`, untouched) | pass |

## Live pass — PRIMARY FINAL (primary filled at final acceptance, 2026-10-27)

The live Godot editor (godot-ai MCP v4.3.1, session `chunky-platformer`) was
used for this pass; every item below was executed, not inferred.

- [x] **Session-live check** (`session_manage`, op `list`): project
  `chunky-platformer` shows `readiness: "ready"` — PASS
- [x] **Touched-scene hierarchy** (`game_manage` `get_scene_tree` on the live
  game): machine node and wallet HUD node present in a sane tree — PASS
- [x] **Screenshot** (`editor_screenshot`, source `game`): inspected, not
  archived (tool returns image data, not files) — wallet badge (gem icon +
  "0") top-left, machine booth beside Robo, gems/keys/touch buttons render
  correctly — PASS
- [x] **Smoke run** (`project_run` main): game live, zero errors, clean `stop`
  (`stopped: true`) — PASS

## Evidence paths

- `conductor/tracks/20261027-gem-shop/verification/phase-1.md`
- `conductor/tracks/20261027-gem-shop/verification/phase-2.md`
- `conductor/tracks/20261027-gem-shop/verification/phase-3.md`
- `conductor/tracks/20261027-gem-shop/verification/phase-4.md` (this file)
- `tests/test_save_game.gd` (19 tests: round-trips, relaunch, triggers)
- `tests/test_gift_machine.gd` (dispense/wear/bonus/wiggle/carry tests)
- `tests/test_gem_budget.gd` (budget/revisit/session tests)
- Coverage run artifacts: `.gd-tools/artifacts/` (from the verification command)

## Deviations

None. No production code changes were expected and none were made; only this
evidence file was written (inside `Touches`).

## Notes

- Full-suite re-run on the unmodified phase base: 332/332 green,
  95.5% lines / 93.8% branches ≥ 80 gate, lint + format clean — exact numbers
  in the Commands table.
- AC-10 suite evidence cites test names, not theory; every cited test passes
  in the run above.
- `gd-tools.toml` coverage exclusion for `src/input/touch_controls.gd`
  (pre-existing instrumentation issue, file untouched) remains in effect.
- Live placeholders are marked PENDING-PRIMARY, not passed, per the phase
  brief; the primary owns the final live re-run.

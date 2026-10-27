# Phase 3 — Minimal Save/Load: verification report

- Track: 20261027-gem-shop — Gem Economy + Gift Machine
- Phase: 3 — Minimal Save/Load
- Date: 2026-10-27 (UTC)
- Branch: feat/20261027-gem-shop
- Base: 7eca98992312de9cdb8b32914eb4ed333a8f2121
- Head: 9fd71473e0ba6ed48c3fac16cca752a69e888c39 (code; evidence committed separately)
- Result: **verified**

## What was built

- `src/systems/save_game.gd` (new): versioned `user://save_game.json`
  (`{"version": 1, "wallet", "owned", "worn", "taken"}`). `load_game()` boots
  fresh (warning only, never UI text) on missing/unreadable/empty/non-object/
  version-mismatched saves, and repairs shabby inner fields field-by-field.
  `save_game()` returns false with a warning when the file cannot be written.
  Reads use the `JSON` instance parser so corrupt text never logs an engine
  ERROR.
- `src/levels/game.gd`: `_ready()` restores wallet/wardrobe/taken via
  `_restore_save()` before building area 0; `_save()` rewrites the file on
  every `wallet.changed` / `wardrobe.changed` emission (covers gem collect
  and gift dispense) and at the end of `_build_area()` (covers area
  transitions, pulling live builder flags first so a force-quit keeps the
  current area's collects).
- `tests/test_save_game.gd` (new, 19 tests): round-trips, version-field
  checks, missing/garbage/empty/non-object/future-version/missing-version
  fixtures, field-repair cases, Game boot-with-garbage, full relaunch
  restore, and collect/dispense/transition rewrite-the-file trigger tests.

## Commands

| Layer | Command | Exit | Summary |
| ----- | ------- | ---- | ------- |
| Style | `gd-tools format` | 0 | All 68 files already formatted |
| Style | `gd-tools lint` | 0 | No lint issues found |
| Suite | `gd-tools test --coverage --min 80` | 0 | 332/332 passed; 95.5% lines, 93.8% branches (threshold 80%) |

## Acceptance criteria

| ID | Criterion | Evidence | Status |
| -- | --------- | -------- | ------ |
| FR-8 | Wallet, owned/worn cosmetics, per-area gem-taken flags persist in a versioned `user://` JSON file | `test_save_file_is_versioned_json`, `test_round_trip_preserves_wallet_wardrobe_and_taken`, `test_full_collection_round_trips`, `test_relaunch_restores_wallet_wardrobe_and_taken` | Pass |
| FR-9 | Save on gem collect, on gift dispense, on area transition (boot loads once) | `test_collect_rewrites_the_save`, `test_dispense_rewrites_the_save`, `test_area_transition_rewrites_the_save` (file-content assertions) | Pass |
| AC-8 | Relaunch restores progress; corrupt saves boot fresh with no crash and no on-screen text | `test_relaunch_restores_wallet_wardrobe_and_taken`, `test_game_boots_fresh_with_garbage_save`, `test_missing_file_boots_fresh`, `test_garbage_file_boots_fresh`, `test_empty_file_boots_fresh`, `test_json_array_boots_fresh`, `test_future_version_boots_fresh`, `test_missing_or_wrong_shaped_version_boots_fresh`, `test_shabby_fields_repair_instead_of_wiping` | Pass |
| AC-9 | Autosave triggers verified by file content | Collect/dispense/transition tests read `user://save_game.json` back and assert wallet/owned/worn/taken values | Pass |

## Evidence paths

- `tests/test_save_game.gd` (+ `.uid`) — 19 tests for this phase
- `src/systems/save_game.gd` (+ `.uid`) — save/load implementation
- `src/levels/game.gd` — `_restore_save()` / `_save()` wiring

## Deviations

- `tests/test_game_transition.gd`, `tests/test_gem_budget.gd`,
  `tests/test_gift_machine.gd` (outside Touches): added one `SaveGame.clear()`
  line each where a `Game` is constructed. Required because persistent saves
  make Game-booting suites order-dependent — without a clean slate, a wallet
  saved by one suite breaks exact-count assertions in the next. Smallest
  change that keeps the whole suite green; no production code affected.
- No changes to `src/systems/wallet.gd` / `src/systems/wardrobe.gd` were
  needed (restore works through the existing `add` / `own` / `wear` API).

## Notes

- Two-tier recovery is deliberate and pinned by tests: top-level problems
  (unparseable, non-object, wrong version) boot fully fresh; inner-field
  problems repair in place (bad wallet → 0, unknown/duplicate gifts dropped,
  unowned worn → newest owned gift, junk flags → uncollected) so one bad
  field never wipes real progress.
- `entry is bool and entry` is used for flag coercion because GDScript
  raises a script error comparing non-bool operands with `==` (found during
  verification, fixed, suite re-run green).
- Worn-look edge: a save with owned gifts but an empty/invalid `worn` field
  (unrepresentable via `to_dict`) repairs to the newest owned gift.
- Live Godot editor checks were not run (MCP unavailable in this
  environment); the primary runs the session-live + screenshot + smoke pass
  at acceptance — see below.

## Primary verification (primary agent, 2026-10-27)

- **Working tree:** clean after phase commits; only intended files changed.
- **Files changed** (`7eca989..HEAD`): new `src/systems/save_game.gd` (+ `.uid`, 133 lines) and `tests/test_save_game.gd` (19 tests); wiring in `src/levels/game.gd` (load-at-boot, save on wallet/wardrobe change + area transition); test-only `SaveGame.clear()` additions in three Game-booting suites. Deviations reviewed and accepted: test-only, smallest change keeping the suite order-independent. No production code outside Touches.
- **Verification (rerun by primary):** `gd-tools test --coverage --min 80` → exit 0, 332/332 passed, 95.5% lines / 93.8% branches ≥ 80 gate.
- **Static:** `gd-tools lint` → no issues (68 files); `gd-tools format --check` → all formatted.
- **Acceptance criteria:** spot-checked test names exist and pass in the green run (`test_relaunch_restores_wallet_wardrobe_and_taken`, `test_collect_rewrites_the_save`, `test_garbage_file_boots_fresh`, `test_shabby_fields_repair_instead_of_wiping`).
- **Live (godot-ai MCP, session ready):** `project_run` main scene → live, zero errors → clean `stop` (nothing visible changed this phase, so no new screenshot; boot-with-save path exercised). Subagent's "live checks unavailable" note is superseded by this pass.
- **Result:** verified.

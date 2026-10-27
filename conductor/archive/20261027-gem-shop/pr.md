## Summary

Gems become a limited, spendable resource: fixed 10-per-area budgets with no
respawn feed a persistent wallet, and a gift machine in each area dispenses
surprise cosmetic gifts (3 hats, 2 trails, 1 color) with auto-wear, plus a
versioned `user://save_game.json` that survives restarts. All 317 tests pass
(95.3% lines / 93.7% branches); review `PASS` after one fix round.

## Track

- **ID:** `20261027-gem-shop`
- **Type:** `feature`
- **Spec:** [`conductor/archive/20261027-gem-shop/spec.md`](conductor/archive/20261027-gem-shop/spec.md)
- **Plan:** [`conductor/archive/20261027-gem-shop/plan.md`](conductor/archive/20261027-gem-shop/plan.md)
- **Review:** [`conductor/archive/20261027-gem-shop/review.md`](conductor/archive/20261027-gem-shop/review.md)

## What happened

| Phase | Goal | Result | Checkpoint | Notes |
| --- | --- | --- | --- | --- |
| 1: Wallet + Fixed Gem Budget | Wallet model + HUD, no-respawn budgets | verified | `eea1e1e` | Coverage-injector workaround: `src/input/touch_controls.gd` excluded in `gd-tools.toml` (user-ordered; upstream bug) |
| 2: Gift Machine + Cosmetics | Machine, tiers, 6 cosmetics, tap-cycle | verified | `2f0c7ae` | Accepted deviations: tap-cycle lives in `robot.gd`, wardrobe ownership in `game.gd`, machine spots in `area_layout` |
| 3: Minimal Save/Load | Versioned JSON save + autosave triggers | verified | `f0818fd` | Deviation: test-only `SaveGame.clear()` helpers (×3) |
| 4: Live Verification + Evidence | Evidence pack + live editor smoke | verified | `d0e615f` | Live: session ready, zero-error run, screenshots inspected |
| R1: Review Fixes | Resolve F1 (High) + F2/F3 (Low) | verified | `4d4e433` | Removed legacy `GemCounter`; `WalletHud` is the sole badge; + post-spend HUD test |

## Requirements

- [x] `FR-1` — Fixed ~10-gem budgets, no respawn (test: `tests/test_gem_budget.gd`)
- [x] `FR-2` — Persistent wallet + numeral HUD (test: `tests/test_wallet.gd`)
- [x] `FR-3` — Machine dispenses with pop + confetti + auto-wear (test: `tests/test_gift_machine.gd`)
- [x] `FR-4` — Tiered prices 1/2/3 as numerals + pips (test: `tests/test_gift_machine.gd`)
- [x] `FR-5` — No duplicates; free bonus celebration when complete (test: `tests/test_gift_machine.gd`)
- [x] `FR-6` — Empty-wallet wiggle + hint sparkle, never scolds (test: `tests/test_gift_machine.gd`)
- [x] `FR-7` — Tap-Robo cycles owned looks (test: `tests/test_gift_machine.gd`)
- [x] `FR-8` — Versioned save, corrupt boots fresh (test: `tests/test_save_game.gd`)
- [x] `FR-9` — Autosave on collect/dispense/transition (test: `tests/test_save_game.gd`)
- [x] `NFR-1` — 60 FPS, no per-frame cost when idle (static reasoning, phase-2.md)
- [x] `NFR-2` — Zero-failure tone (no-words test, wiggle/hint paths)
- [x] `NFR-3` — Numerals + icons only, ≥64px targets (tests in `test_gift_machine.gd`)
- [x] `NFR-4` — Coverage ≥ 80% (`gd-tools test --coverage --min 80`)
- [x] `NFR-5` — All art code-generated (tests in `test_asset_snapshots.gd`)
- [x] `AC-1` — Fixed budgets survive revisit (test: `test_leaving_and_returning_restores_zero_gems`)
- [x] `AC-2` — Wallet numerals + single badge incl. post-spend (test: `test_post_spend_hud_matches_wallet_and_stays_single`)
- [x] `AC-3` — Dispense deducts + wears within 1s (test: `test_dispense_deducts_wears_and_pops_confetti`)
- [x] `AC-4` — Price-3 deducts exactly 3 (test: `test_price_three_deducts_exactly_three`)
- [x] `AC-5` — Complete set → free bonus (order + bonus tests)
- [x] `AC-6` — Empty tap → wiggle + hint (wiggle/hint/no-hint tests)
- [x] `AC-7` — Tap cycles wrap (cycle tests)
- [x] `AC-8` — Collect → force-quit → relaunch intact; corrupt boots fresh (relaunch + corrupt-fixture tests)
- [x] `AC-9` — All three triggers rewrite the save (collect/dispense/transition tests)
- [x] `AC-10` — Live editor smoke (phase-4.md)

## Verification

| Layer | Command | Result | Evidence |
| --- | --- | --- | --- |
| unit | `gd-tools test --coverage --min 80` | pass (317/317, 95.3%/93.7%) | `conductor/archive/20261027-gem-shop/verification/integrated.md` |
| lint | `gd-tools lint` | pass | phase-R1 primary verification |
| format | `gd-tools format --check` | pass | phase-R1 primary verification |
| build | `godot --headless --import --path .` | pass | review round-1 verification |
| live | godot-ai MCP session + `project_run` + screenshots | pass (zero errors) | `verification/phase-4.md` |

## Review

- **Verdict:** `PASS`
- **Rounds:** 2
- **Fixed:** 3 findings (F1 High dual-badge divergence, F2 pip clamp, F3 icon palette)
- **Accepted/deferred:** 0

## Deviations and risks

- `gd-tools.toml` excludes `src/input/touch_controls.gd` from coverage: the
  coverage injector emits unparseable code for that file (Godot error 43),
  failing the whole run despite a 94.8% measured gate pass. Untouched glue
  code; re-include after the upstream gd-tools fix. Risk: low.
- Phase deviations (all accepted, minimal): wardrobe ownership in `game.gd`,
  tap-cycle in `robot.gd`, machine spots in `area_layout`, test-only
  `SaveGame.clear()` helpers, `test_gem_integration.gd` GUT→GdToolsTest
  migration (pre-existing breakage), two extra test files reworked in R1 so
  the suite compiles after the `GemCounter` deletion.
- `typecheck` retired project-wide mid-track (editor LSP instead); not
  track-specific. Risk: none for this diff.

## Follow-ups

- File the gd-tools coverage-injector bug upstream (repro + suspect file
  documented in `verification/phase-1.md`).
- Audio for the machine stays silent per spec (future Audio track).

## Rollback

```bash
# Merge commit
git revert --no-edit -m 1 <merge-commit>

# Squash commit
git revert --no-edit <squash-commit>
```

No migrations or flags. Rolling back deletes `user://save_game.json`
meaning: old builds ignore the file; reinstalling the old build starts fresh.
The save schema carries a version field for future migration.

# Review: Gem Economy + Gift Machine

- **Track:** `20261027-gem-shop`
- **Type:** `feature`
- **Branch:** `feat/20261027-gem-shop`
- **Range:** `c6cf38f..552ee29`
- **Date:** `2026-10-27T08:35:00Z`
- **Verdict:** `BLOCK`

## Summary

Four verified phases deliver the full economy loop (wallet, fixed gem budget,
gift machine, versioned save) with 332 passing tests and a clean live smoke
run. The reviewer found one real High-severity defect: the legacy `GemCounter`
badge is still built alongside the new `WalletHud` at the same screen position
and diverges after any spend, breaking FR-2/AC-2. Two Low nits ride along.
Strict mode applies — all three must be fixed before the PR.

## Verification

| Layer | Command | Result | Evidence |
| --- | --- | --- | --- |
| test | `gd-tools test` | pass (332/332) | `verification/integrated.md` (identical code; only `conductor/` changed since) |
| coverage | `gd-tools test --coverage --min 80` | pass (95.5% lines / 93.8% branches, gate 80) | `verification/integrated.md` |
| lint | `gd-tools lint` | pass (clean) | Phase-4 acceptance run |
| format | `gd-tools format --check` | pass | Phase-4 acceptance run |
| typecheck | retired project-wide (editor LSP :6005) | n/a | `conductor/workflow.md` |
| build | `godot --headless --import --path .` | pass (import DONE, no errors) | background shell `sh_17c795cde001dXC4Nd8QBoFQdJ` |

## Requirements

| ID | Implemented by | Verified by | Status |
| --- | --- | --- | --- |
| FR-1 | P1.T2 | `tests/test_gem_budget.gd` (budget/revisit) | covered |
| FR-2 | P1.T1 | `tests/test_wallet.gd`, `test_gem_budget.gd` | partial (see F1) |
| FR-3 | P2.T1 | `tests/test_gift_machine.gd` (dispense) | covered |
| FR-4 | P2.T2 | `tests/test_gift_machine.gd` (prices) | covered |
| FR-5 | P2.T3 | `tests/test_gift_machine.gd` (no-dup, bonus) | covered |
| FR-6 | P2.T1 | `tests/test_gift_machine.gd` (wiggle/hint/no-words) | covered |
| FR-7 | P2.T3 | `tests/test_gift_machine.gd` (cycle) | covered |
| FR-8 | P3.T1 | `tests/test_save_game.gd` (round-trip, corrupt fixtures) | covered |
| FR-9 | P3.T2 | `tests/test_save_game.gd` (mtime/content triggers) | covered |
| NFR-1 | P2/P4 | static reasoning (phase-2.md, phase-4.md) | covered |
| NFR-2 | P2 | no-words test, wiggle/hint paths | covered |
| NFR-3 | P1/P2 | numerals+pips, tap-target tests | covered |
| NFR-4 | all | coverage gate runs | covered |
| NFR-5 | P2 | `test_asset_*` (machine + hats generated) | covered |
| AC-1 | P1.T2 | `test_leaving_and_returning_restores_zero_gems` | covered |
| AC-2 | P1.T1 | collect-3/rebuild tests | partial (see F1 — no post-spend HUD assertion) |
| AC-3 | P2.T1 | `test_dispense_deducts_wears_and_pops_confetti` | covered |
| AC-4 | P2.T2 | `test_price_three_deducts_exactly_three` | covered |
| AC-5 | P2.T3 | order + bonus tests | covered |
| AC-6 | P2.T1 | wiggle/hint/no-hint tests | covered |
| AC-7 | P2.T3 | cycle tests | covered |
| AC-8 | P3.T1 | relaunch + corrupt-fixture tests | covered |
| AC-9 | P3.T2 | collect/dispense/transition rewrite tests | covered |
| AC-10 | P4.T1 | suite + live pass (phase-4.md) | covered |

## Findings

### Critical

- <none>

### High

- **F1 — Legacy gem counter overlaps and diverges from the wallet HUD**
  - **File:** `src/levels/area_builder.gd:94-105` (build), `:305` (`_on_gem_collected`)
  - **What:** The builder adds both the legacy `GemCounter` and the new
    `WalletHud` at the same top-left position and feeds both on collect, but
    only the wallet decreases on spend (`GemCounter.set_count` is monotonic).
    After any dispense the two badges show different numbers on top of each
    other. Phase 1 comment says the legacy badge would be replaced in Phase 2;
    it never was.
  - **Why:** Breaks FR-2/AC-2 — the HUD no longer reads the wallet balance
    after the first purchase. Repro: collect 3 (both show 3) → dispense a
    price-1 gift (wallet 2, legacy still 3, overlapping digits).
  - **Fix:** Remove the legacy `GemCounter` from `AreaBuilder` (var, build,
    collect wiring) so `WalletHud` is the sole badge; retire
    `src/ui/gem_counter.gd` + `tests/test_gem_counter.gd` (dead after removal);
    rework `tests/test_gem_integration.gd` to look up `WalletHud`; update
    counter assertions in `test_gem_budget.gd`, `test_game_transition.gd`,
    `test_area_builder.gd` to assert `wallet_hud.balance()`.
  - **Requirement:** FR-2/AC-2
  - **Test gap:** Add post-spend HUD test: collect N, dispense once, assert
    `wallet_hud.balance() == N - cost` and only one top-left badge remains.

### Medium

- <none>

### Low

- **F2 — Price clamp range exceeds pip capacity**
  - **File:** `src/ui/machine_tag.gd:33`
  - **What:** `set_price` clamps to `0..9` but only 3 pips exist, so prices
    above 3 would show a wrong pip row.
  - **Why:** Dead today (prices only 0..3) but misleading contract.
  - **Fix:** Clamp to `0..MAX_PIPS` in `set_price` (or document pip capping).
  - **Requirement:** none
  - **Test gap:** none (add a clamp assertion with the fix if cheap)
- **F3 — Wallet icon size measured from the wrong palette**
  - **File:** `src/ui/wallet_hud.gd:83-85`
  - **What:** `_icon_size()` samples the `"meadow"` gem texture while `_icon`
    uses the area palette.
  - **Why:** Fragile if palettes ever differ in size (identical today, no
    visual defect).
  - **Fix:** Use the same palette lookup in `_icon_size()` as for `_icon`.
  - **Requirement:** none
  - **Test gap:** none

## Overrides

- <none>

## Plan compliance

Phases 1–4 all `verified` with checkpoints (`eea1e1e`, `2f0c7ae`, `f0818fd`,
`d0e615f`) and evidence files. Tasks match implementation; deviations at each
phase were minimal and accepted. No task silently dropped. `Touches`
respected. No review-fix phase yet — appended below.

## Out of scope

- `gd-tools.toml` `touch_controls.gd` coverage exclusion (user-ordered
  workaround for a gd-tools injector bug; separately being reported upstream).
- Machine silence (spec Out of Scope; future audio track).
- `.uid` sidecars and untouched `src/input/touch_controls.gd`.

## Debt

- <none yet — unresolved findings go to the fix phase, not debt, under strict mode>

## Doc sync

`pending` — post-review sync after the fix phase.

## History

| Round | Verdict | Critical | High | Medium | Low | Fixed |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | BLOCK | 0 | 1 | 0 | 2 | 0 |

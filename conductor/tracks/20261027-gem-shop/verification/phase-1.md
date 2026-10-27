# Phase 1 Evidence — Wallet + Fixed Gem Budget

- Track: 20261027-gem-shop — Gem Economy + Gift Machine
- Phase: 1 — Wallet + Fixed Gem Budget (FR-1, FR-2, NFR-4, AC-1, AC-2)
- Date: 2026-10-27 (UTC)
- Branch: feat/20261027-gem-shop
- Base: 3f086701fa999babc868c272dc6aa8c9a6ca845
- Head: (see commits below)
- Result: FAILED (verification command exits non-zero; see notes — all 281
  tests pass and measured coverage is above the gate, the exit code comes
  from a pre-existing coverage-instrumentation error on an untouched file)

## Commands

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| unit/integration | `gd-tools test` | 0 | 281 total, 281 passed, 0 failed |
| coverage | `gd-tools test --coverage --min 80` | 1 | 94.8% lines (gate 80%) BUT tool errors: `touch_controls.gd` could not be instrumented (Godot error 43), so measurement is marked incomplete. Same warning on every run, including before the last test fix; file is untouched by this phase (byte-identical to base) |
| static | `gd-tools lint` | 0 | No lint issues |
| static | `gd-tools format --check` | 0 | All 59 files formatted (3 reformatted by `gd-tools format` first) |

Live editor checks (session live, scene hierarchy, screenshots, smoke run)
were NOT performed: no godot-ai MCP tools are available in this execution
environment. No scene files were changed (all HUD/level work is code-built),
so there are no new screenshots to capture.

## Acceptance criteria

| ID | Criterion | Evidence | Status |
| --- | --- | --- | --- |
| AC-1 | Collect all gems in an area, leave, return → zero restored; per-area counts documented in layout | `tests/test_gem_budget.gd::test_leaving_and_returning_restores_zero_gems`; `AreaLayout.GEMS_PER_AREA = 10` with per-area "Fixed budget: 10 gems (6 walk + 2 jump + 2 bounce)" comments; `Game._taken` + `AreaBuilder` taken-flags round-trip | pass |
| AC-2 | Collecting 3 gems shows "3" + icon; balance survives quitting to title within the session | `tests/test_gem_budget.gd::test_collecting_three_shows_three` and `::test_balance_survives_rebuilds_within_the_session`; `WalletHud` mirrors `Wallet.balance()` via `changed` signal | pass |

## Evidence paths

- `tests/test_wallet.gd` (8 tests: starting empty, add, rejected adds, exact spend, no-negative spend, changed emits, rejected moves silent, reset)
- `tests/test_gem_budget.gd` (8 tests: budget per area, validation, builder spawns budget, HUD bound/top-left/two-digits, never respawns, 3-shows-3, revisit restores zero, balance survives rebuild)
- `conductor/tracks/20261027-gem-shop/verification/phase-1.md` (this file)

## Deviations (files outside Touches, smallest necessary changes)

- `src/levels/game.gd` — owns the session `Wallet` and per-area taken flags; required for FR-2 session persistence and AC-1 revisit behavior.
- `src/levels/area_builder.gd` — `build()` accepts optional wallet + taken flags, assigns `gem_id`, pre-collects revisit gems, feeds wallet/counter on collect, builds `WalletHud`; required to wire wallet and persistence without breaking existing `build(layout)` callers.
- `tests/test_gem.gd`, `tests/test_gem_integration.gd` — respawn expectations replaced with permanence expectations (old behavior removed by FR-1); suite must stay green.
- `tests/test_game_transition.gd`, `tests/test_playthrough.gd` — persistence tests now seed the wallet instead of poking the legacy counter directly (counter mirrors wallet now).
- `src/world/key.gd` — one doc-comment line updated (it stated gems respawn, no longer true).

## Notes

- TDD: new suites (`test_wallet`, `test_gem_budget`) were written alongside the new models; implementation is the minimum to satisfy them.
- Legacy `GemCounter` keeps working (builder mirrors `wallet.balance()` into it) until Phase 2 replaces its meaning; key/door/celebration flows untouched (281/281 green).
- Coverage: 94.8% lines / 97.2% instrumented lines ≥ 80% gate, but the command exits 1 because the coverage injector cannot instrument `src/input/touch_controls.gd` (untouched, pre-existing). Recommend the primary treat this as tech-debt/environmental and waive or file an issue rather than blocking the phase on it.
- Live checks unavailable in this environment (no MCP tools); recommend the primary run the editor session-live + screenshot + smoke pass in Phase 4, which owns live verification.
- New files: `src/systems/wallet.gd`, `src/ui/wallet_hud.gd`, `tests/test_wallet.gd`, `tests/test_gem_budget.gd` (+ auto-generated `.uid` sidecars).

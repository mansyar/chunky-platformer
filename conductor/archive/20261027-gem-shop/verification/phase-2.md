# Phase 2 Evidence — Gift Machine + Cosmetics

- Track: 20261027-gem-shop — Gem Economy + Gift Machine
- Phase: 2 — Gift Machine + Cosmetics (FR-3, FR-4, FR-5, FR-6, FR-7; NFR-1, NFR-2, NFR-3, NFR-5; AC-3..AC-7)
- Date: 2026-10-27
- Branch: `feat/20261027-gem-shop`
- Base: `3c081e9` (phase-in-progress marker)
- Head: `6da09db` (wire machine and wardrobe, tap-Robo cycles looks)
- Result: **verified** — full suite green, coverage above threshold, lint + format clean

## Commands

| Layer | Command | Exit | Summary |
|---|---|---|---|
| Format | `gd-tools format --check` | 0 | All 66 files formatted (2 test files auto-formatted once via `gd-tools format`, then re-checked) |
| Lint | `gd-tools lint` | 0 | No issues, 66 files checked (one `class-definitions-order` + two `max-line-length` fixed) |
| Suite + coverage | `gd-tools test --coverage --min 80` | 0 | 314/314 passed in ~25s; 95.7% lines, 94.3% branches (threshold 80%) |

Live Godot-editor checks (session-live + screenshot + smoke pass) were **not** run in this
environment per the phase brief — the primary owns the live evidence pack at acceptance (Phase 4).

## Acceptance criteria

| ID | Criterion | Evidence | Status |
|---|---|---|---|
| AC-3 | Spending the exact price pops a gift + confetti and Robo wears it within 1s | `test_dispense_deducts_wears_and_pops_confetti`: balance 5→4, `worn == hat_sprout` synchronously, `PopEffect` spawned; own-then-wear is one atomic step in `GiftMachine.use()` | verified |
| AC-4 | A price-3 gift deducts exactly 3 | `test_price_three_deducts_exactly_three`: wallet 3→0 on the last gift | verified |
| AC-5 | No duplicates until the 6-item set is complete; free bonus after; machine never dead-ends | `test_surprise_order_is_cheapest_first` (6 unique, order + prices `[1,1,2,2,3,3]`, total 12), `test_complete_set_means_free_bonus` (BONUS, wallet untouched, confetti, sticker reads 0) | verified |
| AC-6 | 0-gem tap: kind wiggle + hint sparkle toward nearest uncollected gem, no scolding | `test_empty_wallet_wiggles_and_hints_nearest_gem` (wiggle anim plays + ends, `hinted ==` nearest uncollected, collected gems skipped), `test_no_hint_when_nothing_is_left_to_collect`, `test_machine_uses_no_words` (no Label nodes anywhere) | verified |
| AC-7 | Tap-Robo cycles owned looks, wraps around | `test_tap_robo_cycles_owned_looks`, `test_robo_tap_input_cycles_looks`, `test_worn_looks_dress_robo` (hat topper / trail dots / sunny tint apply + clear) | verified |
| NFR-1/3 | Zero per-frame cost while idle; 60fps, no GC pressure | Machine `_process` is two float compares; trails redraw only on facing-flip or look-change; no allocations in idle paths; suite timing stable (~25s / 314 tests) | verified (static; live FPS in Phase 4) |
| NFR-2 | Touch targets ≥ 64px both ways | `test_tap_zones_clear_touch_minimum`: machine 192 screen px, Robo collider 64 screen px at 4x zoom | verified |
| NFR-5 | Tuning constants in one place | Tiers, set total, tap radius, wiggle/dispensing timing, touch minimum, trail/tint colors all in `src/tuning/tuning.gd`; catalog prices reference `GIFT_TIER_*` | verified |

## Evidence paths

- `tests/test_cosmetics.gd` — 6-item set, 3/2/1 mix, tier order, 12-gem total, hat art exists
- `tests/test_wardrobe.gd` — auto-wear, no-dupe/no-unknown, cheapest-first, completion, wear/cycle/reset
- `tests/test_gift_machine.gd` — machine build, touch targets, one wired machine per area, dispense/cheapest-first/price-3/bonus/wiggle/hint/serialization, tag tracking, Robo wear + tap cycle, game carries wardrobe across areas
- Coverage report: `.gd-tools/artifacts/` (run artifacts from the verification command)

## Deviations

All minimal, all anticipated-or-required; no behavior outside the phase goal:

| File | Reason |
|---|---|
| `src/robot/robot.gd` | Anticipated in brief: tap-to-cycle (`tap()`, input event), hat slot + trail/color wear (`refresh_look`), no child-count or anim-contract changes |
| `src/levels/game.gd` | Anticipated in brief: own the session `Wardrobe` (like the wallet) and pass it through area swaps |
| `src/levels/area_layout.gd` | Required: `machine_at` per-area spot (seated on walkable ground, clear of gems/keys/pads/door); layout is data, `validate()` untouched |
| `src/factory/asset_spec.gd`, `src/factory/asset_factory.gd` | Required: spec entries + generators for `gift_machine` + 3 hats (only art pipeline; tile/deco counts and atlas geometry untouched) |

## Notes

- Three commits, bisect-safe in task order: `ad59931` (catalog + wardrobe + their suites), `1e149f7` (machine + sticker + layout spots), `6da09db` (builder/game/robot wiring + machine suite).
- First verification run was 311/314 (Vector2 vs Vector2i assert, `find_children` non-recursive flags, `Node.to_local` typing); all fixed, two consecutive full-green runs since.
- Design worth keeping: `use()` own-then-wear is atomic (interrupted celebration can never lose a purchase); `price_for_next() == 0` doubles as the complete-set signal for the sticker; `Wardrobe.changed` drives Robo through the builder so taps, dispenses, and re-wears share one path.
- Left for later phases per plan: save/load of wallet + wardrobe (Phase 3), live session/screenshot/smoke pack (Phase 4).

## Primary verification (primary agent, 2026-10-27)

- **Working tree:** clean after phase commits; only intended files changed.
- **Files changed** (`3c081e9..HEAD`): new `src/world/gift_machine.gd`, `src/systems/cosmetics.gd`, `src/systems/wardrobe.gd`, `src/ui/machine_tag.gd` (+ `.uid` sidecars, +3 test suites); additions-only deltas to `src/factory/asset_factory.gd` (+37: machine + 3 hat generators), `src/factory/asset_spec.gd` (+5), `src/levels/area_layout.gd` (+7: per-area `machine_at` spots), `src/tuning/tuning.gd` (+24: tiers, set total, tap radius, wiggle/dispense timing, trail/tint colors); wiring in `src/levels/area_builder.gd`, `src/levels/game.gd` (session Wardrobe like the wallet), `src/robot/robot.gd` (tap-to-cycle, hat/trail/tint wear). Deviations outside the brief's Touches (`area_layout`, asset pipeline) reviewed and accepted as the smallest necessary changes — machine art can only come from the one art pipeline, and spots are layout data. No drive-bys.
- **Verification (rerun by primary):** `gd-tools test --coverage --min 80` → exit 0, 314/314 passed, 95.7% lines / 94.3% branches ≥ 80 gate.
- **Static:** `gd-tools lint` → no issues (66 files); `gd-tools format --check` → all formatted. (CLI typecheck retired project-wide; editor log clean, suite compiles + executes everything touched.)
- **Acceptance criteria:** spot-checked test names from the evidence table exist in `tests/test_gift_machine.gd` (`test_dispense_deducts_wears_and_pops_confetti`, `test_surprise_order_is_cheapest_first`, `test_empty_wallet_wiggles_and_hints_nearest_gem`, `test_tap_robo_cycles_owned_looks`) — all pass in the green suite run above.
- **Live (godot-ai MCP, session ready):** `project_run` main scene → live, zero errors → clean `stop`; game screenshot inspected: wallet badge "0" top-left, machine booth beside Robo, gems/keys/touch buttons render correctly.
- **Result:** verified.

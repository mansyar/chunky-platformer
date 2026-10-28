# Phase 2 evidence — Boot restore + finale (20261028-resume-mid-adventure)

- Branch: `feat/20261028-resume-mid-adventure`
- Phase base: `20a6380`
- Commits: `4343689` (P2 feat, game.gd), `38b3146` (P2 tests, game-transition),
  `cbe10c1` (test-only isolation fix, playthrough — deviation D1)
- Touched: `src/levels/game.gd`, `tests/test_game_transition.gd`,
  `tests/test_playthrough.gd` (D1, test-only one-liner)

## What changed

- `Game._restore_save` now also resumes `area_index` from the loaded state
  (already clamped to a valid index by Phase 1 `SaveGame.sanitize`; corrupt
  saves still boot fresh meadow).
- `Game._ready` builds `_build_area(area_index)` instead of always `_build_area(0)`,
  so boot lands in the saved area at the layout's default spawn — never exact XY.
- `Game._save` commits the live index:
  `SaveGame.save_game(wallet, wardrobe, _taken, SaveGame.SAVE_PATH, area_index)`.
  Since `_build_area` saves at its end, every door swap persists the NEW index
  and the finale loop-home (rebuild of area 0) persists 0. Wallet/wardrobe
  change saves ride along with the current index.
- Keys stay fresh with zero extra work: each `_build_area` constructs a new
  `GoalState` (0/3) — FR-7 means NO key-state persistence, and none was added.
- No per-frame cost: restore is one boot-time load; `_process` untouched (NFR-1).
  No menus/prompts added (NFR-4).

## Tests (TDD)

Red run (before fix, `gd-tools test --coverage --min 80`): 3 failures —
`test_boot_restores_saved_cave_at_spawn_with_collections` (boot built meadow at
300,498 instead of cave at 240,498), `test_resumed_area_starts_with_fresh_keys`
(boot built meadow), `test_door_transition_persists_the_new_area_index`
(save held 0 after swaps). Green after fix.

New tests in `tests/test_game_transition.gd` (4):

- `test_boot_restores_saved_cave_at_spawn_with_collections` — save at index 1
  (wallet 5, sprout hat worn) → boot builds cave at `AreaLayout.cave().robot_spawn`,
  wallet/wardrobe intact. (FR-2, FR-7, AC-1)
- `test_resumed_area_starts_with_fresh_keys` — save at index 1 with gem-taken
  flags → boot builds cave with `goal_state` 0/3 and empty badge. (FR-6/FR-7)
- `test_door_transition_persists_the_new_area_index` — meadow→cave saves 1,
  cave→sunset saves 2. (FR-5)
- `test_finale_saves_meadow_and_reboot_starts_meadow` — finale commits 0;
  a fresh `Game` without clearing boots meadow. (FR-5, AC-4)

## Verification

| Command | Exit | Result |
|---|---|---|
| `gd-tools test --coverage --min 80` | 0 | 383/383 passed, 12 snapshots matched, 95.1% lines / 94.0% branches (gate 80) |
| `gd-tools lint` | 0 | no issues |
| `gd-tools format --check` | 0 | 71/71 formatted (one gdformat reflow applied to the new tests) |

## Live checks (AC-7, godot-ai MCP)

| Tool | Target | Result |
|---|---|---|
| `session_manage` list | project | 1 session `chunky-platformer`, `readiness: ready`, Godot 4.7.2 |
| `scene_get_hierarchy` | game.tscn (stopped) | sane: single `/Game` root — children are runtime-built by `AreaBuilder`, nothing missing |
| `editor_screenshot` source=game | running main scene | meadow boot rendered (Robo, gems, key badge 0, wallet 0, machine, touch controls); after writing a live index-1 save + reboot, cave rendered (cave palette, wallet 5, sprout hat worn, badge 1 — Robo auto-grabbed the spawn-adjacent walk key during live seconds, consistent with fresh keys) |
| `project_run` main + `game_eval` | smoke + AC-1 live | run reached `live`/`playing`; `current_scene` reported `[0, meadow, 0, 0]`; after live-writing save index 1 and relaunching, reported `[1, cave, 5, …]`; `project_manage` stop returned to `ready`/`stopped`; test save cleared afterwards |
| screenshot persistence | `.conductor/evidence/` | NOT persisted: `editor_screenshot` returns image data with no filepath param and this phase has no binary-write tool — frames are recorded in the run transcript above instead (limitation, not a product gap) |

## AC check

- AC-1 (cave resume intact, keys 0/3): PASS — new boot tests + live reboot proof.
- AC-4 (finale saves 0, next boot meadow): PASS — `test_finale_saves_meadow_and_reboot_starts_meadow`.
- AC-6 (product.md): untouched — Phase 3 scope, per brief.
- AC-7 (live): PASS with the noted screenshot-persistence limitation.

## Deviations

- D1 (minimal + necessary, test-only): `tests/test_playthrough.gd::_open_game`
  now calls `SaveGame.clear()` before boot — outside the phase `Touches` glob
  (`test_game*`). Required because boot now (correctly) resumes the on-disk area,
  and this was the only `Game`-booting helper without the clean-slate convention
  every other suite already follows; without it a leftover `area_index` 1 from
  `test_game_transition` breaks the suite's meadow-open assumption. No game-code
  impact.

## Follow-ups for the primary

- None functional. Screenshot binaries could not be written to
  `.conductor/evidence/` from this phase's toolset; capture them during review
  if the track wants files on disk.
- `tests/test_game_transition.gd` now holds 12 test methods (lint cap is 20) —
  fine, no split needed.

## Primary verification (2026-10-28)

- **Touches diff vs phase base `20a6380`:** `src/levels/game.gd` (in glob),
  `tests/test_game_transition.gd` (matches `test_game*` glob),
  `tests/test_playthrough.gd` (OUTSIDE glob — ACCEPTED as D1: test-only one-liner
  adding the `SaveGame.clear()` clean-slate convention every other Game-booting
  suite already follows; mirrors the authorized Phase 1 R1 test-only precedent),
  `verification/phase-2.md` (evidence, always allowed). No changes to
  `save_game.gd` (frozen Phase 1 API), `product.md` (Phase 3), or other phases.
  Game diff is 3 minimal edits: `_restore_save` resumes `area_index`,
  `_ready` builds `_build_area(area_index)`, `_save` commits the live index
  (`save_game(wallet, wardrobe, _taken, SAVE_PATH, area_index)`).
- **Rerun (primary, full gate):** `gd-tools test --coverage --min 80` → exit 0,
  383/383 passed, 12 snapshots matched, 95.1% lines / 94.0% branches (gate 80).
  `gd-tools lint` → exit 0, no issues. `gd-tools format --check` → exit 0,
  71/71 formatted. Matches the subagent's report exactly.
- **AC:** AC-1 PASS (boot-to-cave test + live reboot proof), AC-4 PASS
  (finale-saves-0 + reboot-starts-meadow test), AC-6 untouched per scope,
  AC-7 PASS with the noted screenshot-persistence limitation.
- **Verdict: Phase 2 VERIFIED.** Dependency gate for Phase 3 is satisfied.

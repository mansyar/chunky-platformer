# Phase 3 Evidence — Gameplay wiring + live proof (20261027-audio-synthesis)

## Scope
- P3.T1: robot takeoff → `jump`; trampoline impulse → `bounce` (mash-safe via factory cap).
- P3.T2: gem → `gem`, key → `key`, door unlock → `door`; hint sparkles/pointing untouched.
- P3.T3: dispense → `gift_pop`, wiggle → `gift_wiggle` (new `wiggled` connection), bonus → `gift_bonus`;
  finale → `celebrate`; ambient follows every area swap including loop-home.
- P3.T4: `tests/test_audio_wiring.gd` (17 tests) proves each moment with voice-count deltas.

## Design decisions (why)
- **Game root owns the one persistent `AudioManager`** (`game.audio_manager`, added in `_ready`
  before the first build). The builder is freed on every swap, so a per-area owner would cut the
  loop instead of crossfading. Builders borrow it (`builder.audio_manager`, set in `_build_area`)
  purely for `notify_sfx_played()` ducking.
- **Robot + trampoline play without ducking**: they fire too often (every jump/bounce would pin
  the loop at duck level for 0.5 s each) and reaching the manager would couple world nodes to the
  game root. `AudioFactory.play()` alone is headless-safe (no-op outside the tree).
- **Sounds ride existing handlers** (`builder._on_*`, game finale branch, robot launch site,
  trampoline impulse site). No gameplay signal was rerouted; behavior diffs are sound-only.
- New `AudioManager` child on Game adds no save/state surface; `SaveGame` untouched.

## Verification
- Command: `gd-tools test --coverage --min 80`
- First run: 366 passed / 8 failed — 7 were wrong accessor assumptions in the NEW test file
  (`builder.gems`/`builder.keys` don't exist → `find_children("*", "Gem"/"Key")`;
  `nearest_hint_target` → `nearest_hint_gem`; `current_area` only flips after the fade →
  assert `target_area` + drive `manager._process(...)`; finale counts door chime + flourish
  together → isolate with pool reset after banking keys). 1 flake:
  `test_audio_ambient.test_sfx_plus_ambient_startup_stays_sub_second` (untouched Phase-2
  timing assertion; passed on re-run — machine-load flake, no factory/manager change involved).
- Second run: **373/373 passed, 0 failed, 12/12 snapshots matched, coverage 95.0% lines /
  93.8% branches (threshold 80%)**. No source changes between runs except the test file.

## Live proof for the primary (AC-7 integrated verification)
The subagent has no MCP tools — run this live editor session and record results:
1. `session_manage` → `list` a ready session; `editor_state` to confirm `game.tscn` context.
2. Open `res://src/levels/game.tscn`; `hierarchy` — expect `Game/AudioManager` + `Game/Area`
   (builder) with `World/Robo`, `GiftMachine`, `Door`.
3. `screenshot` the running meadow to `.conductor/evidence/phase-3-meadow.png`.
4. `project_run` the game, then per moment (listen + watch `AudioFactory.active_voice_count()`):
   - jump (Space) → jump whoosh; trampoline pad → bounce boing (mash: holds polyphonic).
   - gem ring → pop + wallet +1; key → chime + counter; 3rd key → door rising chime.
   - machine with gems → gift_pop + confetti; empty wallet → wiggle + hint trail to a gem;
     full set (debug-own all 6) → gift_bonus, wallet untouched.
   - walk into the open door → crossfade to next area loop (no hard cut); finale door on
     sunset → flourish + duck, then loop home to meadow loop.
5. `project_run` → stop; confirm no engine errors in the log.

## Files changed
- `src/robot/robot.gd`, `src/world/trampoline.gd`, `src/levels/area_builder.gd`,
  `src/levels/game.gd`, `tests/test_audio_wiring.gd` (new).
- Commits: `e1a89d4` (wiring), `27d1f9e` (tests). No deviations outside Touches.

## Primary verification

- **Current HEAD (pre-squash):** `72ffb5e` on top of `d939576`, plus working-tree `gd-tools format` on the new test file (whitespace only).
- **Touches-vs-diff (d939576..HEAD + working tree):**
  | Touches entry | In diff? | Notes |
  | --- | --- | --- |
  | `src/robot/robot.gd` | yes | launch-site `play()` only |
  | `src/world/*.gd` | yes | `trampoline.gd` only (impulse-site `play()`) |
  | `src/levels/game.gd` | yes | owns persistent AudioManager + finale/area-switch wiring |
  | `src/levels/area_builder.gd` | yes | handler-site `play()` + duck borrowing |
  | `tests/test_audio_wiring.gd` | yes (new) | 17 signal-spy suites |
  | `conductor/.../verification/phase-3.md` | yes | evidence (allowed) |
- **Verification rerun (final):** `gd-tools test --coverage --min 80` → exit 0, 373/373 pass, 12 snapshots matched, 95.0% lines / 93.8% branches; `gd-tools lint` → OK; `gd-tools format --check` → OK (after formatting 1 test file, re-ran suite: still 373/373); `godot --headless --import --path .` → DONE.
- **AC cross-check:** AC-5 (every moment triggers) by 17 wiring suites; AC-6/AC-7 static gates above. Live editor proof (hierarchy/screenshot/project_run) deferred to integrated verification by the primary (MCP tools).
- **Note for review:** one machine-load timing flake observed in Phase-2 suite during subagent run (`startup_stays_sub_second`), passed on re-run and in both primary reruns — no action, flagging for reviewer awareness.
- **Status:** Phase 3 `verified` (0 reworks).

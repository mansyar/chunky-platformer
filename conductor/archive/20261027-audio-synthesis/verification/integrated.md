# Integrated Verification — 20261027-audio-synthesis

> All 3 phases verified individually (e7a9c10, 9129195, f3e4d2f; 28/28 tasks).
> This file proves the whole track together, including the live editor run.

## Static gates (rerun on final tree)

| Gate | Command | Result |
| --- | --- | --- |
| Tests + coverage | `gd-tools test --coverage --min 80` | 373/373 pass, 12 snapshots matched, 95.0% lines / 93.8% branches |
| Lint | `gd-tools lint` | OK, no issues |
| Format | `gd-tools format --check` | OK, 70 files |
| Import | `godot --headless --import --path .` | DONE (ran in Phase 3; no scene/resource changes since) |

## Live editor proof (godot-ai MCP 4.3.1, Godot 4.7.2, session chunky-platformer)

| Check | Tool | Result |
| --- | --- | --- |
| Boot main scene | `project_run(mode="main")` | `status: live`, helper live, no errors |
| Runtime audio state | `game_eval` on live game | 9 SFX cached; 3 ambient loops; `get_ambient("meadow")` non-null; unknown area falls back to meadow; `play("gem")` + `play("bogus_name")` safe; `AudioManager` node live in game scene |
| Scene tree | `get_scene_tree(depth=3)` | `AudioManager` present in live tree |
| Render | `editor_screenshot(source="game")` | 1280x720 frame, fresh (1683 frames drawn, not stale) |
| Teardown | `project_manage(op="stop")` | stopped, session ready |

## Transient noted (not a finding)

- First `project_run` attempt reported stale `gift_machine.gd` parse errors
  (`MACHINE_WIGGLE_TIME` / `MACHINE_DISPENSE_TIME` "not found" though present
  in `src/tuning/tuning.gd`). After `filesystem_manage(scan)` the rerun booted
  clean with zero errors. Root cause: stale editor script cache, not a code
  defect — no track file implicated (neither file is in this track's Touches).
  Flagged for reviewer awareness only.

## AC roll-up

| AC | Verdict | Proven by |
| --- | --- | --- |
| AC-1: 9 SFX non-silent WAV, correct format | ✅ | Phase 1 suites + live `game_eval` (9 cached) |
| AC-2: 3 loop-enabled gentle distinct ambient loops | ✅ | Phase 2 suites + live `game_eval` (3 cached) |
| AC-3: polyphonic cap 8, oldest-steal, unknown-safe | ✅ | Phase 1 suites + live `play("bogus_name")` safe |
| AC-4: `get_ambient` per-area + fallback, crossfade, duck | ✅ | Phase 2 suites + live fallback check + manager live |
| AC-5: every moment triggers | ✅ | Phase 3 wiring suites (17 signal-spy) |
| AC-6: headless-safe, fast startup | ✅ | Import DONE + headless suite green (94%+ coverage) |
| AC-7: suites + coverage + snapshots + live proof | ✅ | 373/373, 12 snapshots, this live run |

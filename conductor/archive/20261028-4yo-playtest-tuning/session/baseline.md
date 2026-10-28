# Green Baseline — Phase 1 (2026-10-28)

> Measured facts only. Suite + gates on the Phase 1 tree; adult live-boot
> attestation below. No session data invented (Phase 2 not yet run).

## Suite & gates

| Command | Exit | Summary |
| --- | --- | --- |
| `gd-tools test --coverage --min 80` | 0 | 404/404 passed, 0 failed, 0 skipped (79.35s); 94.7% lines / 94.0% branches vs 80% gate; 12/12 snapshots matched |
| `gd-tools lint` | 0 | No lint issues found |
| `gd-tools format --check` | 0 | All 73 file(s) formatted |

Note: one earlier background run of the same command exited 1 with all 404
tests passing but a `<artifacts>.<process>` prune error (`could not prune
older runs under .gd-tools/artifacts`) — caused by a second suite instance
running concurrently from this same session. A clean single-instance re-run
above is green; no code or test changed between the runs.

## Adult live-boot smoke test (editor run, P1.T3.2)

- Method: `project_run` (mode `main`) via godot-ai MCP against the live editor
  session (`chunky-platformer`, Godot 4.7.2, readiness `ready`).
- Result: game reached `live` (`helper_live: true`, `session_active: true`).
  Live scene tree shows `/Game/Area/World` with TileMapLayer terrain, `Robo`
  (CharacterBody2D), `Door` (Area2D), pickup Area2Ds, and `FollowCamera` — a
  playable Area 1 level.
- Live game capture (1280x720, `stale_frame: false`, 13926 frames drawn)
  shows Meadow gameplay: robot on terrain, gems + key placed, gem counter
  top-left, touch left/right/jump buttons visible. Boot into Area 1 attested.
- Stop: `project_manage` (`op: stop`) returned `stopped: true`, session back to
  `ready`. No errors left running.
- Scope limit: no physical touchscreen was available to this agent, so this
  attests only that the editor run boots into a playable Area 1. Real
  touchscreen validation happens with the user in Phase 2 per the protocol.

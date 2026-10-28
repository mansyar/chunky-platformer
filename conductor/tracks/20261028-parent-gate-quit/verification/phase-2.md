# Phase 2 verification — 20261028-parent-gate-quit (hold feedback + live proof)

- Track: `20261028-parent-gate-quit` · branch `feat/20261028-parent-gate-quit`
- Base: `8720c04` · Phase-1 checkpoint: `4ebd732`
- Scope: FR-3, NFR-2/3/4, AC-5 · Tasks P2.T1 (ring + ticks + chime), P2.T2
  (resize + second-finger hardening), P2.T3 (live-editor proof)

## What was built (extends Phase 1, no redesign)

- `src/input/quit_hold.gd` — `extends Control`, full-rect transparent overlay
  (`MOUSE_FILTER_IGNORE`, z_index 100). Per-frame `_draw`: faint full track
  (white, alpha 0.25) + filling arc (white, alpha 0.9, width 6) from −90° with
  sweep `TAU * progress`; hidden when idle/hidden on silent reset. Mid-hold
  ticks every `Tuning.QUIT_TICK_INTERVAL` (1.0 s) and a completion chime via
  injectable `tick_call` / `chime_call` (production defaults call
  `AudioFactory.play("gem")` tick / `AudioFactory.play("door")` chime — no
  ducking, mirroring the frequent-sound precedent; no Game.gd change needed).
  Hold clock `_next_tick` is idle-safe (INF while idle) and zero-interval-safe.
  Constant alphas, constant radius — no flashes, no text, no animation besides
  the fill sweep. Escape and all non-corner input still ignored.
- `src/tuning/tuning.gd` — added `QUIT_TICK_INTERVAL 1.0`,
  `QUIT_RING_RADIUS 28.0`, `QUIT_RING_WIDTH 6.0` (Phase-1 pins kept).
- `tests/test_quit_hold_feedback.gd` — 15-test GUT suite (same helper idioms
  as Phase 1): tuning defaults, overlay presence, ring hidden→visible→sweep,
  on-screen clamping, clear on release/drift, ticks per interval (none early,
  none at completion), chime exactly once, big-step equivalence, custom 0.5 s
  interval (5 ticks), release stops ticks/skips chime, resize-inside
  continues, resize-outside silent-resets, second-finger isolation, mouse
  parity. Spies inject `tick_call`/`chime_call` plus `quit_call`/`save_flush`
  (completion tests bind quit/save doubles — the suite never quits the
  test runner).
- Incidental fix (within Touches): `_ready` used `set_anchors_preset`, which
  left the overlay at 0×0 in the live game; switched to
  `set_anchors_and_offsets_preset(PRESET_FULL_RECT)`.

## Verification

- `gd-tools test --coverage --min 80 --no-cache` → **434/434 passed**,
  **94.1% lines / 92.7% branches** (threshold 80%). (A first `--no-cache`-less
  rerun failed only on a stale coverage-plan cache refusing to instrument
  `quit_hold.gd`; `--no-cache` regenerates the plan — no code change.)
- `gd-tools lint` → clean. `gd-tools format --check` → clean after one
  `gd-tools format` (whitespace-only).
- Live proof (P2.T3): session ready; game `project_run` (main) went live;
  mid-hold ring photographed and saved from the running game to
  `.conductor/evidence/phase-2-hold-ring.png` (1280×720 PNG: zoomed-out level
  with the white half-ring arc at the top-right corner, matching the
  predicted canvas→screen position exactly). Smoke run started and
  `project_manage stop` confirmed stopped afterwards. Completion path also
  observed live (a driven hold completed and quit the game end-to-end).
- Method note: the game camera (`Area/World/FollowCamera`, zoom 4×) means the
  embedded editor view shows only a ~320×180 canvas slice, so the corner ring
  is off-frame at normal zoom; the photo was taken with the camera zoomed to
  0.5 for framing and the camera/hold/timescale restored afterwards. No game
  code was changed for the photo.

## Deviations

- `src/input/quit_hold.gd` `_ready`: `set_anchors_preset` →
  `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` (1-line fix required for
  the overlay to cover the screen live; tests already assumed full-rect).
- No other files touched. `src/systems/audio_manager.gd` needed no changes:
  ticks/chime route through the existing `AudioFactory` synth set
  (`"gem"` tick, `"door"` chime), consistent with the wiring precedent.

## Primary verification

- Working tree clean (3 regenerable editor `.import` sidecars under
  `conductor/archive/` screenshots removed; untracked, never committed).
- Diff `8720c04..HEAD` = exactly the 1 reported commit (`dc4c36a`);
  5 files, all inside Touches (+ Godot `.uid` companion + this evidence
  file). No merge/foreign commits. The large `quit_hold.gd` delta is the
  planned Phase 2 extension (ring draw + tick/chime wiring) of the Phase 1
  file, not a redesign — state machine and pins intact.
- Independent runs on the unchanged tree with the plan's exact commands:
  `gd-tools test --coverage --min 80` → 434/434 passed, 94.1% lines /
  92.7% branches ≥ 80 gate, 12 snapshots matched (79.01s, no `--no-cache`
  needed, no flake); `gd-tools lint` → exit 0; `gd-tools format --check` →
  76/76 formatted.
- Viewed `.conductor/evidence/phase-2-hold-ring.png`: white partial ring arc
  at the top-right corner over an intact Meadow scene (HUD + touch buttons
  normal) — matches the reported framing note (zoom 0.5 for the photo,
  camera restored). AC-5 live proof accepted: session-ready + screenshot +
  reported smoke run stopped.
- Anchor-preset deviation accepted (1-line, smallest necessary, tests already
  assumed full-rect). AudioManager untouched is consistent with the contract
  ("wiring only").
- FR-3, NFR-2/3/4, AC-5 covered. Result: Phase 2 **verified**.

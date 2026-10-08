# Plan: Movement & Camera

**Strategy note:** physics logic (movement, jump, bounce, camera math, input state) is logic-bearing → strict TDD. Animation and level layout are visual → deterministic structural tests. Test physics via real scene-tree simulation (`Input.action_press` + physics frames), extending the pattern the proof-scene tests established.

## Phase 1: Tuning Constants & Horizontal Movement [checkpoint: 1ba4b1f]
- [x] Task: Write failing tests for the tuning constants file (all spec values present: walk speed, accel ramp, jump impulse, gravity, fall cap, bounce power, coyote, buffer, camera smoothing) [1ba4b1f]
- [x] Task: Write failing tests for horizontal movement — accel ramp to fixed target speed, deceleration to stop, identical air control, movement disabled physics sanity [1ba4b1f]
- [x] Task: Implement `src/tuning/tuning.gd` (single constants file) [1ba4b1f]
- [x] Task: Implement `src/robot/robot.gd` — code-assembled `CharacterBody2D` with horizontal move logic + facing flip [1ba4b1f]
- [x] Task: Refactor & verify — format, lint, full suite [1ba4b1f]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [1ba4b1f]

## Phase 2: Jump & Gravity [checkpoint: f3193e7]
- [x] Task: Write failing tests — fixed-impulse jump reaches expected height, only when on floor (or within coyote window) [f3193e7]
- [x] Task: Write failing tests — coyote time (~0.1s window after leaving edge), input buffer (~0.1s pre-landing press fires on landing) [f3193e7]
- [x] Task: Write failing tests — floaty gravity, terminal fall-speed cap [f3193e7]
- [x] Task: Implement jump + coyote + buffer + gravity/cap in `robot.gd` using Tuning [f3193e7]
- [x] Task: Refactor & verify — format, lint, full suite [1ba4b1f]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [f3193e7]

## Phase 3: Animation Wiring [checkpoint: a96aa15]
- [x] Task: Write failing structural tests — animation state selection: walk cycle advances while moving on floor, jump frame while airborne, land-squash plays on landing then returns to idle, idle bob advances when still [a96aa15]
- [x] Task: Implement code-built `AnimatedSprite2D` (SpriteFrames from `AssetFactory` robot textures) + state selection in `robot.gd` [a96aa15]
- [x] Task: Refactor & verify — format, lint, full suite [1ba4b1f]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [a96aa15]

## Phase 4: World Interactives [checkpoint: c5ad518]
- [x] Task: Write failing tests — one-way platform: body falls onto it and lands; body rising from below passes through; no drop-through input path exists [c5ad518]
- [x] Task: Write failing tests — trampoline: bounces only when falling onto it from above, impulse > jump impulse, horizontal velocity preserved, re-bounces on repeat landings; side/below contact does nothing [c5ad518]
- [x] Task: Write failing tests — level edge walls block horizontal movement at bounds [c5ad518]
- [x] Task: Implement `src/world/trampoline.gd` (Area2D), one-way platform setup helper, edge-wall helper [c5ad518]
- [x] Task: Refactor & verify — format, lint, full suite [1ba4b1f]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [c5ad518]

## Phase 5: Camera [checkpoint: c2b32a0]
- [x] Task: Write failing tests — camera follows a moving target on both axes with smoothing; clamped to level bounds on all sides [c2b32a0]
- [x] Task: Implement `src/world/follow_camera.gd` (Camera2D, target follow + bounds clamp via Tuning smoothing value) [c2b32a0]
- [x] Task: Refactor & verify — format, lint, full suite [1ba4b1f]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [c2b32a0]

## Phase 6: Input Layer [checkpoint: af57b7d]
- [x] Task: Extend asset spec + completeness tests with 3 touch-button assets (left arrow, right arrow, jump icon) [fa5068e] — spec-first; implement generators + snapshot tests
- [x] Task: Configure Godot Input Map in `project.godot`: keyboard (arrows + WASD + space/enter), gamepad (d-pad, left stick, bottom face button) for `move_left`/`move_right`/`jump`
- [x] Task: Write failing tests — device detection: last-input-device tracking flags keyboard/mouse/gamepad/touch; touch controls visible only while touch is the last device [af57b7d]
- [x] Task: Implement `src/input/touch_controls.gd` (CanvasLayer with big code-built hold buttons driving the same Input Map actions)
- [x] Task: Refactor & verify — format, lint, full suite [1ba4b1f]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [af57b7d]

## Phase 7: Playground Level & Integration [checkpoint: 42bcef5]
- [x] Task: Write failing tests — playground level structure: multi-layer tile terrain (~2 screens × 3 layers), ≥1 trampoline area, one-way platforms, edge walls, Robo spawn, camera limits match level bounds [efb0399]
- [x] Task: Implement `src/levels/playground.gd` + minimal `.tscn` root; delete `src/proof/`; set as main scene in `project.godot` [efb0399]
- [x] Task: Full gate run [42bcef5]
- [x] Task: Manual verification plan [42bcef5]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [42bcef5]

## Phase: Review Fixes
- [x] Task: Apply review suggestions [dcf239a] (conductor-review 2026-10-08: stale topology/architecture headers corrected in playground.gd, follow_camera.gd, robot.gd; BOUNCE_IMPULSE comment moved off STEP_UP_MAX_LEDGE; unused LEVEL_ROWS removed; ui generator p["eye"] fallback; product-guidelines.md animation line aligned with the approved multi-frame decision)

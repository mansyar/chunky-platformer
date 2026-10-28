# Spec: Movement & Camera

## Overview
Robo comes alive. This track delivers the core verbs of the product loop — walk, jump, bounce, fall safely, explore — on a multi-layer playground level that becomes the seed of Area 1 and the new main scene. It builds directly on the Foundation track's AssetFactory, PixelDsl, and code-assembled-node patterns.

## Functional Requirements

### §1 Player Controller (`src/robot/`)
- `CharacterBody2D` assembled in code (no hand-authored scenes)
- Horizontal movement: fixed target speed ≈ 2.5 tiles/s with a tiny acceleration ramp (~0.1s) on start and stop; identical control authority in the air
- Facing: sprite flips horizontally with movement direction
- Jump: one button, fixed impulse height; coyote time ~0.1s; jump input buffer ~0.1s
- Gravity: gentler than Godot default (floaty arcs), with a terminal fall-speed cap
- Animation: all 8 AssetFactory frames wired — 4-frame walk cycle while moving, jump frame while airborne, land-squash on landing, 2-frame idle bob at rest

### §2 Trampoline (`src/world/`)
- Area2D trigger using the generated trampoline art position
- Bounces only when Robo falls onto it from above; fixed impulse clearly higher than a normal jump; horizontal momentum preserved; re-bounces on every landing

### §3 One-way platforms
- Jump up through from below, always land on top; no drop-through input exists (falls happen only by walking/jumping off edges)

### §4 Safe world
- Falling from any height lands safely — no damage, hazards, or death states exist anywhere in the codebase
- Invisible walls block Robo at level boundaries

### §5 Camera (`src/world/` or `src/camera/`)
- Camera2D smooth-follows Robo on both axes; clamped to level bounds (same bounds as the edge walls)

### §6 Input
- Godot Input Map: `move_left`/`move_right`/`jump` for keyboard (arrows + WASD, space/enter), gamepad (d-pad/left stick + bottom face button)
- Big on-screen touch buttons (hold-left, hold-right, jump) shown on touch devices; auto-hidden whenever keyboard/mouse/gamepad activity is detected
- No remapping, no menus

### §7 Playground Level (`src/levels/`)
- ~2 screens wide × 3 vertical layers, meadow palette, built from the generated tile atlas
- Paths at multiple heights connected by one-way platforms, at least one trampoline, safe pits between layers, decorative props from AssetFactory
- Becomes the project's main scene; the Foundation proof scene is deleted

## Non-Functional Requirements
- All tuning values (speed, ramp, jump impulse, gravity, cap, bounce power, coyote/buffer, camera smoothing) live in one constants file
- Zero external assets — any new art goes through AssetFactory with spec + completeness-test updates
- TDD for logic-bearing code (controller physics, input state, bounce conditions, camera clamp); visual behavior verified via deterministic snapshot/structural tests
- Coverage gate ≥80% lines/branches; all gd-tools gates pass; 60 FPS target

## Acceptance Criteria
1. Robo walks at a steady pace with a smooth ramp, flips with direction, steers fully mid-air
2. One-button fixed-height jump works with coyote time and input buffering; arcs are floaty; falls are speed-capped
3. Trampoline bounces higher than a jump, keeps momentum, fires only on top-down landings
4. One-way platforms catch from above and pass from below; no accidental drop-through
5. Any fall lands safely; no hazard or death state exists
6. Camera follows smoothly on both axes and clamps at level bounds; edges block Robo
7. All 8 animation frames play in their correct states
8. Keyboard and gamepad both control Robo; touch buttons show/hide based on last input device
9. Playground level is the main scene; proof scene no longer exists
10. All gd-tools gates pass (test, lint, format, coverage ≥80%)

## Out of Scope
- Gems, keys, doors, hints (Collect & play phase) · Audio · Save/persistence · Areas 2–3 · Pause/menus/remapping/debug overlays · Drop-through input, double jump, variable jump height

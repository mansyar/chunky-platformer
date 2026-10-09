# Implementation Plan — Goal Loop

## Phase 1: Layout Records & Shared Builder (the enabling refactor) [checkpoint: c2b76ba]

- [x] [c2b76ba] Task: Write failing tests — `AreaLayout` records validate every field;
  `AreaBuilder` produces the same world shape from a layout record as the current
  hand-built playground
- [x] [c2b76ba] Task: Write failing tests — meadow layout converts to the existing terrain
  exactly (regression guard against losing the staircase hills and trampoline elevator)
- [x] [c2b76ba] Task: Implement — `src/levels/area_layout.gd` (typed layout record),
  `src/levels/area_builder.gd` (one builder, data in / world out)
- [x] [c2b76ba] Task: Refactor — `Playground` becomes a meadow layout; all existing tests stay
  green
- [x] [c2b76ba] Task: Run full gate (format, lint, test, coverage ≥80%)
- [x] [c2b76ba] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Key Entity & Counter

- [x] [8c6f972] Task: Write failing tests — `Key` builds sprite + sensor, auto-collects on
  touch, is permanent, `is_taken()`; bob is pure bounded sine like `Gem.bob_offset`
- [x] [8c6f972] Task: Write failing tests — key counter badge renders icon + correct digits,
  baseline-aligned with the gem counter
- [x] [8c6f972] Task: Implement — `src/world/key.gd`, glow/bob, `src/ui/key_counter.gd`
- [x] [8c6f972] Task: Implement — key art in the asset spec + generators
- [x] [8c6f972] Task: Run full gate
- [x] [8c6f972] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Goal State & Door

- [x] [7503412] Task: Write failing tests — `GoalState` starts at 0 keys / locked; `take_key()`
  increments, is idempotent per key, emits; `open_door()` only at 3/3
- [x] [7503412] Task: Write failing tests — `Door` is solid while locked, opens at 3/3
  (art swap + collision change + signal)
- [x] [7503412] Task: Implement — `src/levels/goal_state.gd`, `src/world/door.gd`
- [ ] Task: Run full gate
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 4: Hint System

- [ ] Task: Write failing tests — timer re-arms on collection; fires at
  `HINT_DELAY` with no progress; trail endpoints are Robo → nearest uncollected key;
  with 3/3 keys the target is the door; `Robo.point_at()` turns and holds
- [ ] Task: Implement — `src/fx/hint_trail.gd` (deterministic dots along the line,
  like `PopEffect`), `src/robot/robot.gd` point-at state
- [ ] Task: Run full gate
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 5: Area Transition & Celebration

- [ ] Task: Write failing tests — walking into an open door emits transition with
  the outgoing palette; the swap builds area N+1 and resets its goal state; the gem
  counter persists; area 3 loops to meadow after the celebration
- [ ] Task: Implement — `src/levels/transition.gd` (palette fade), game root that owns
  the area index and swaps levels
- [ ] Task: Run full gate
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 6: Areas 2 & 3 + Integration

- [ ] Task: Write failing tests — each layout validates; cave and sunset build
  distinct terrain with 3 keys (one per reach tier) and a reachable door
- [ ] Task: Write failing tests — full playthrough test: meadow → cave → sunset →
  meadow, collecting all 9 keys
- [ ] Task: Implement — cave layout (layered, tight, bridge route) and sunset layout
  (tall, trampoline-driven)
- [ ] Task: Integration — 3 keys + door in each area, hints live, celebration on
  finishing sunset
- [ ] Task: Run full gate
- [ ] Task: Manual verification — play all 3 areas end to end, confirm hint fires and
  never strands
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

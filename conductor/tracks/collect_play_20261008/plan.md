# Plan: Collect & Play

TDD-ordered per workflow.md: failing tests (red) → implement (green) → refactor → full gates → checkpoint. Logic is tested with real physics/input; visuals via deterministic structural/snapshot tests.

## Phase 1: Pixel Digit Glyphs [checkpoint: 0a08f23]

- [x] Task: Write failing tests — asset spec gains `digit_0`…`digit_9` (`kind: "ui"`, size 8×12); snapshot tests pin glyph ink presence, size, and byte determinism [0a08f23]
- [x] Task: Implement — spec entries + `_ops_for` digit generators (bar-style pixel glyphs) [0a08f23]
- [x] Task: Full gate run (format, lint, tests, coverage ≥80%) [0a08f23]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [0a08f23]

## Phase 2: Gem Entity & Collection State Machine [checkpoint: 33c2713]

- [x] Task: Write failing tests — body overlap collects, gem hidden while collected, respawn after `Tuning.GEM_RESPAWN_TIME` with sparkle signal, endless collect/respawn cycles, pure bob math (sine), `collected`/`respawned` signals emitted [33c2713]
- [x] Task: Implement `src/world/gem.gd` (code-assembled Area2D, sine bob, timer-driven respawn) [33c2713]
- [x] Task: Full gate run [33c2713]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [33c2713]

## Phase 3: Collection Juice Effects

- [x] Task: Write failing tests — pop effect (expanding ring + sparkles) spawns on collect and self-frees after its lifetime; effect node touches no physics bodies; `Robot.celebrate()` is visual-only (velocity unchanged, squash applied to sprite) [61a13a8]
- [x] Task: Implement `src/fx/pop_effect.gd` + robot squash celebration [61a13a8]
- [x] Task: Full gate run [61a13a8]
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) [61a13a8]

## Phase 4: HUD Counter

- [ ] Task: Write failing tests — screen-space CanvasLayer at top-left, gem icon + digit sprites matching current count, count only grows, squash-pulse bump on increment
- [ ] Task: Implement `src/ui/gem_counter.gd` (code-assembled, AssetFactory textures)
- [ ] Task: Full gate run
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 5: Playground Integration

- [ ] Task: Write failing tests — ~12 gems at handcrafted mixed-reach coordinates (walk / jump / bounce tiers), HUD present, end-to-end simulation: walk Robo through a gem → count increments + gem hides → advance past respawn time → gem visible again
- [ ] Task: Implement gem placement + HUD wiring in `playground.gd`, tuning constants
- [ ] Task: Full gate run
- [ ] Task: Manual verification plan — run the game: collect gems by walking, jumping, and bouncing; watch the counter grow; wait ~10 s to see the respawn sparkle
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

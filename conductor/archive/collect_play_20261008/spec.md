# Spec: Collect & Play

## Overview

Adds the game's core reward loop: handcrafted gems scattered through the playground that pop with juice when touched, a big always-visible counter, and endless timed respawning. Collection is pure joy — no economy, no totals to read, no failure state. Audio arrives in Phase 6; this track makes collecting *feel* great visually.

## Functional Requirements

### §1 Gem Entity & Placement

- `Gem` = code-assembled `Area2D` using the existing AssetFactory gem texture (no hand-authored scenes).
- **Auto-collect on touch**: overlap with Robo's body collects — no button press.
- **~12 handcrafted positions** in the playground builder (fixed coordinates in code): most walk-reachable, a few need a jump, 1–2 need the trampoline.
- **Idle bob**: uncollected gems bob gently (a few pixels, slow sine, `Tuning.GEM_BOB_*`), drawing the eye.

### §2 Collection Juice (visual-only, non-blocking)

- Gem pop: the gem sprite vanishes, replaced by a brief expanding ring + sparkle burst (code-drawn, <0.5s, then freed).
- Counter bump: the HUD counter does a one-shot squash-pulse.
- Robo celebration: visual-only squash-stretch on his sprite — **no velocity change**, movement/jumping never interrupted.

### §3 Respawning

- After `Tuning.GEM_RESPAWN_TIME` (10 s), the gem reappears at its spot with a small sparkle burst announcing it.
- Repeatable forever — collection is endless.

### §4 HUD Counter

- Screen-space `CanvasLayer` (unaffected by camera zoom), top-left corner: **gem icon + plain count**.
- No total, no fraction — the number only ever grows.
- **Code-generated pixel digit glyphs (0–9)** added to the AssetFactory (no fonts allowed): 8×12 glyphs scaled big, `kind: "ui"` in the asset spec, with completeness + snapshot tests.

### §5 Integration

- Playground builder spawns the gems and wires the HUD; existing playground tests updated (gem count, HUD presence).

## Non-Functional Requirements

- All new tuning values live in `Tuning` (respawn time, bob amplitude/speed, juice durations).
- Zero external assets; digits and effects are generated/drawn in code.
- TDD for logic (collect/respawn state machine, counter math); deterministic structural tests for visuals (digit glyphs, HUD wiring).
- ≥80% line and branch coverage; all gd-tools gates pass (run manually, no hooks).
- 60 FPS: juice effects are short-lived and freed promptly.

## Acceptance Criteria

1. Walking Robo through a gem collects it: pop + sparkles + counter bump + Robo squash, with movement uninterrupted.
2. The counter shows a gem icon + growing count top-left, using pixel digits only.
3. Gems respawn ~10 s later with a sparkle, indefinitely.
4. Idle gems bob gently.
5. Mixed-reach placement verified (walk / jump / bounce tiers present).

## Out of Scope

- Audio (Phase 6 track).
- Persistence / saving (Phase 7 track).
- Keys, doors, hint sparkles (Goal Loop track).
- Any economic purpose for gems.
- Areas 2–3.

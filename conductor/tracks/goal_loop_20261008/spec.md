# Goal Loop — Keys, Doors, Hints & Areas

## Overview

The playground becomes a journey. Each of the three handcrafted areas hides three
keys — one per reach tier — behind a door that only opens when all three are found.
Walking through the door fades to the next area's palette. A hint system guarantees
no child is ever stranded: after ~30 seconds without progress, a sparkle trail leads
from Robo to whatever he's looking for, and Robo turns to point at it. Progress is
in-memory; the game always opens in the meadow. This is roadmap Phase 5 and the last
of v1's content work.

## Functional Requirements

**§1 Key entity.** Code-assembled `Area2D`, same construction pattern as `Gem`.
Auto-collects on touch from any `CharacterBody2D`. Collected keys are **permanent** —
progress only moves forward, so the hint system only ever points at *remaining* keys.
Keys bob gently and glow so they read as alive without needing rescuing.

**§2 Key counter.** A second HUD badge beside the gem counter (top-left): key icon +
pixel-digit count, reusing the generated `digit_*` glyphs and the same monotonic-pool
pattern as `GemCounter`. Both badges sit on one baseline.

**§3 Door.** A `StaticBody2D` + `Area2D` pair placed in each area. Locked, it is solid.
With 3/3 keys it swaps to `door_open` art, stops being solid, and begins a gentle
glow. Walking into an open door starts the transition. Touching a locked door does
nothing — no message, no denial, just a wall.

**§4 Goal state.** A `GoalState` object holding `keys_taken: int`, `door_open: bool`,
and `area_index: int`. Single source of truth; the HUD, door, and hint system all
read from it. Emits signals so presentation stays out of the logic. In-memory only —
a new launch always starts at area 1.

**§5 Hint system.** A ~30s (`Tuning.HINT_DELAY`) timer reset by any key collected.
On expiry:
- if keys remain → a **sparkle trail** of animated dots runs from Robo to the nearest
  uncollected key, and **Robo turns to point** at it, holding until the key is taken;
- if 3/3 keys are taken but the door is unvisited → the trail points at the **door**
  instead, teaching "door = goal."

The hint re-arms after each collection. It never blocks movement and never pauses
anything.

**§6 Area transition.** Walking into an open door fades out through the outgoing
area's palette colour, swaps the level, fades back in through the incoming area's.
The new area's `GoalState` starts fresh; the gem counter persists across areas as a
lifetime total.

**§7 Three areas, one builder.** A shared `AreaBuilder` + `Level` base class. Each
area is a compact layout record: palette name, terrain spans, hill heights, key
positions (one per reach tier), door position, prop placement. **Terrain is unique per
area** — meadow is open and rolling, cave is layered and tight with the bridge as the
main route, sunset is tall and trampoline-driven.

**§8 Celebration.** On entering area 3's door: confetti sparkles, Robo jumps, then
the meadow quietly restarts.

## Non-Functional Requirements

- All tuning constants in `Tuning` (`HINT_DELAY`, trail speed, fade duration, etc.).
- Zero external assets — keys, doors, glow, and trail sparkles are all code-generated.
- TDD for logic-bearing code; structural/deterministic tests for visual wiring.
- Coverage gate ≥80% line + branch; all gd-tools gates green before each commit.
- 60 FPS on a tablet; a fade and ~30 sparkles must not drop frames.
- Every hazard-free guarantee holds: no enemy, no damage, no death, no soft-lock
  anywhere.

## Acceptance Criteria

1. Each area spawns exactly 3 keys; touching Robo collects each permanently and the
   key badge counts up.
2. With 0–2 keys the door is solid and cannot be entered; with 3/3 it opens and its
   art changes.
3. Walking into an open door transitions to the next area via a palette fade; area 3
   loops to the meadow after the celebration.
4. After `HINT_DELAY` with no collection, a sparkle trail appears pointing to the
   nearest uncollected key and Robo faces it; with all keys taken, the trail points at
   the door.
5. Collecting a key cancels and re-arms the hint.
6. All three areas use distinct palettes and distinct terrain, built by one shared
   builder.
7. All gd-tools gates pass; coverage ≥80%.

## Out of Scope

- Persistence to `user://` (roadmap Phase 7).
- Audio (Phase 6) — the `AudioFactory` stub already exists for it.
- Colour-matched doors, switches, or extra puzzle types (v2).
- Gem count resetting per area.
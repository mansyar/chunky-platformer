# Product Definition — Robo's Treasure Hunt

## Summary

Robo's Treasure Hunt is a side-scrolling exploration game for children aged 4 and
up. The player guides a cute, chunky robot through a colorful multi-layered world
across three themed areas, collecting respawning glowing gems and hunting for
three keys hidden in each area to unlock the door to the next. There are no
enemies, no hazards, and no fail states: falls always land safely or bounce back
via auto-powered trampolines, and a sparkle-hint system guides the player if they
stop making progress. Movement is deliberately forgiving — hold-to-move at a
fixed speed with one-button jumping — so success requires exploration, not
timing skill. All visuals and audio are generated in code; no external assets.

## Target Audience

- Primary: children aged 4–5, playing on a tablet or a grown-up's laptop,
  typically with a parent nearby.
- Design principle: every mechanic must be operable by a child who cannot read,
  cannot manage menus, and has unpredictable fine motor control.

## Core Loop

1. Explore the current area freely (hold-to-move, jump, bounce on trampolines).
2. Collect respawning gems along the way (constant positive feedback).
3. Find 3 keys hidden in the area.
4. Unlock the area's door → celebration moment → next area unlocks.
5. After the final area: big finale celebration, then free play continues forever.

One full area takes a 4-year-old roughly 5–10 minutes.

## Mechanics

- **Movement:** CharacterBody2D with simplified gravity. Fixed walking speed
  (no acceleration curves), one-button jump with generous coyote time and
  jump buffering. Walking into a low ledge (up to two tiles) triggers an
  automatic hop onto it — stairs and steps need zero jump precision. No
  precise timing is ever required.
- **Trampolines:** Area2D-based; landing applies a fixed upward impulse
  automatically — no input, no skill. They are the "reward" for falling.
- **Safe falling:** The world is multi-layered (3–4 vertical layers). Every
  fall path ends on a safe lower route or a trampoline that returns the player.
- **Collectibles:** One gem type, respawning after a cooldown. A single big,
  friendly counter on screen. Collecting gives sparkle + pop feedback.
- **Keys & doors:** 3 keys per area, door unlocks when all are collected.
  Keys are large, shiny, and visually salient.
- **Anti-frustration:** If no key progress for ~30 seconds, a sparkle trail
  appears and Robo points toward the nearest remaining key. No menus, no
  reading required.
- **Progression:** 3 handcrafted areas with distinct code-generated palettes
  and decoration shapes (e.g. meadow → cave → sunset hills).

## Controls

- **Touch (landscape):** Hold left/right half of the screen to walk;
  tap anywhere to jump. Oversized, forgiving hit areas.
- **Desktop:** Arrow keys (or A/D) to walk, Space/Up to jump.

## Audio

Fully code-generated: synthesized SFX (jump, bounce, collect, key, door,
celebration) plus a gentle ambient music loop. No external audio files.

## Persistence

Full progress saved to user:// as JSON: collected keys, opened doors, gem
count, robot position. The child resumes mid-adventure across sessions.

## Non-Goals (v1)

- No enemies, hazards, damage, or game-over screens — ever, in any version.
- No settings menu (tuning happens in code constants).
- No text-heavy UI; no reading required to play.
- No additional puzzle types (sequences, switches, counting) in v1 —
  candidates for v2.
- No external assets of any kind (art, audio, fonts).

## Roadmap

### v1 (this project)

1. **Foundation** — Godot project scaffold; code-generated art pipeline
   (robot, tiles, gem, key, door).
2. **Movement & camera** — hold-to-move, forgiving jump, side-scroll camera,
   touch + keyboard input maps.
3. **World building** — TileMap area 1: multi-layer layout, safe-fall design,
   trampolines.
4. **Collect & play** — gems (respawn + counter), trampoline polish, juicy
   feedback.
5. **Goal loop** — keys, doors, auto-hint sparkles, area transitions,
   celebrations.
6. **Audio** — synthesized SFX + ambient music.
7. **Persistence & content** — save/load; areas 2 & 3 with distinct themes.
8. **Playtest checkpoint** — session with a real 4-year-old; tuning pass on
   physics, hints, and pacing.

### Beyond v1

- **v1.1:** Parent gate / hold-to-quit; extra celebration polish.
- **v2:** Additional puzzle layers — color-matched doors, simple switches &
  bridges; possibly a 4th area.
- **v2.x:** Multiple collectible types if kids show appetite for variety.

## Success Criteria

- A 4-year-old can complete area 1 unaided within their first session.
- Zero game-over, zero stuck states (hint system proves itself in playtest).
- Touch controls require no instruction.

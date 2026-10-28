# Phase 2 evidence — cave + sunset personality placement

Track 20261028-area-personality, Phase 2 (P2.T1–P2.T4). Goal: the cave and
sunset dress with hand-placed bg props, identical gameplay, distinct identity
proven live. Covers FR-1/2/3/4/6/7, NFR-1/5, AC-1/2/3/4/6/7.

## What changed

- `src/levels/area_layout.gd`
  - Cave: 8 props (2 crystal, 2 stalactite, 2 glowshroom, 2 moss). Standing
    props sit base-on-terrain (y = surface − 8); the two stalactites hook
    under the bridge platform (top = platform y).
  - Sunset: 8 props (2 butte, 2 sunset_tuft, 2 sunbloom, 2 pebble), all
    base-on-terrain along the staircase shoulders and valley.
  - Meadow: props stay `[]` — byte-identical baseline.
  - `validate()` extended: vocabulary check per area (meadow must keep zero),
    inside-bounds, seating (terrain or platform hook), and 4+ types per
    dressed area. Shared `TILE` const (16.0) added so validation speaks the
    same units as the builder.
- `src/levels/area_builder.gd` — `_build_props` paints props at
  `z_index = -10` (behind tiles and every interactive); still plain
  Sprite2D, zero collision (StaticBody2D count unchanged at 4).
- `tests/test_area_personality.gd` (new, TDD-first) — richness (5–8 props,
  4+ types), vocabulary, meadow-empty, validate-clean, determinism,
  in-bounds, seating, 24px readability halo around gems/keys/trampolines/
  spawn/door/machine/pads/deco, builder bg-layer + zero-collision.

No art, tuning, audio, save, or economy changes. Keys, gems, door, spawn,
machine untouched — identical gameplay.

## Verification

- `gd-tools test --coverage --min 80` → 404/404 pass, 94.7% lines /
  94.0% branches (threshold 80). 12 snapshots matched.
- `gd-tools lint` → no issues. `gd-tools format --check` → all 73 files
  formatted.
- Live editor session (Godot 4.7.2, `res://src/levels/game.tscn`): booted
  main, `_build_area(0/1/2)` per area, 1.5s camera settle, viewport captured
  to the screenshots below, then stopped. No errors on boot or area switch.
- Screenshots (1280×720, camera settled on Robo):
  - `screenshots/phase-2-meadow.png` — blue sky, green hills, no props.
  - `screenshots/phase-2-cave.png` — dark violet sky, teal stalactites under
    the bridge, glowshroom + moss on the shelves, purple gems.
  - `screenshots/phase-2-sunset.png` — amber sky, buttes on the plateau,
    sunblooms + tufts + pebbles along the steps, gift machine with price tag.
- Smoke observation: cave/sunset HUD shows key count 1 at spawn — the walk
  key sits ~8px from each spawn and auto-collects on build. Pre-existing
  data (keys/spawn untouched by this phase); gameplay identical to Phase 1.
- Deviations: none. All work inside the brief's Touches.

## Commits

- `f7cdae1` test(world): pin cave/sunset prop placement and readability guards
- `e106ed1` feat(world): hand-place cave/sunset bg props with validated seating
- `8e91816` fix(world): declare TILE const for prop validation seats
- `3eeaa3a` style(world): satisfy line-length and formatter for personality pass

## Primary verification

Independent re-run by the primary on `feat/20261028-area-personality`:

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| unit+coverage | `gd-tools test --coverage --min 80` | 0 | 404/404 pass; 94.7% lines, 94.0% branches (gate 80); 12 snapshots matched |
| lint | `gd-tools lint` | 0 | No lint issues found |
| format | `gd-tools format --check` | 0 | All 73 files formatted |

- Files changed (`c76c91a..HEAD`) are all inside the phase `Touches`
  (`src/levels/area_layout.gd`, `src/levels/area_builder.gd`,
  `tests/test_area_personality.gd` + `.gd.uid`) plus the phase evidence file
  and its three screenshots.
- Visual check of all three screenshots: meadow is the unchanged blue-sky /
  green-hill baseline with zero new props; cave is distinctly dark-violet
  with teal stalactites, glowshroom + moss; sunset is distinctly amber with
  butte / tuft / sunbloom / pebble dressing. Gems, keys, door, machine, HUD
  and hint-relevant elements stay fully legible in every shot.
- Acceptance: FR-1, FR-2, FR-3, FR-4, FR-6, FR-7, NFR-1, NFR-5, AC-1, AC-2,
  AC-3, AC-4, AC-6, AC-7 all pass (evidence tables above + screenshots).
  Result: **verified**.

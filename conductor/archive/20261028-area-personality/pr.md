# PR — Area Personality Pass (cave & sunset deco)

Track `20261028-area-personality` → `master`. Review: PASS WITH FINDINGS
(Round 1: 1 Low, fixed in R1, re-verified).

## Summary

Meadow keeps its sunny baseline; cave and sunset now have distinct visual
identity built from 8 new code-generated deco assets each, dressed with 8
hand-placed validated background props per area. Zero gameplay impact:
no collisions, no tuning/audio/save/economy changes, reachability and key
tiers green.

## Changes

- `src/factory/{asset_factory,asset_spec,palettes}.gd` — 8 new deco
  generators (crystal, stalactite, glowshroom, moss; butte, sunset_tuft,
  sunbloom, pebble), palette-bound, snapshot-pinned.
- `src/levels/area_layout.gd` — hand-placed cave/sunset `props` (8 each,
  4+ types), extended `validate()` (vocabulary, bounds, seating,
  determinism); meadow `props` stays `[]`.
- `src/levels/area_builder.gd` — `_build_props` paints at `z_index = -10`,
  zero added collision.
- Tests: `test_area_personality.gd` (richness, vocab, seating, 24px halo),
  asset factory/spec/snapshot coverage for the 8 new textures.
- Review fix R1: stale asset-count comments corrected.

## Verification

- `gd-tools test --coverage --min 80` → 404/404, 94.7% lines / 94.0% branches
- `gd-tools lint`, `format --check`, headless import → all green
- Live editor: all 3 areas captured with settled camera, smoke clean, stopped

## Screenshots

![meadow](conductor/tracks/20261028-area-personality/verification/screenshots/phase-2-meadow.png)
![cave](conductor/tracks/20261028-area-personality/verification/screenshots/phase-2-cave.png)
![sunset](conductor/tracks/20261028-area-personality/verification/screenshots/phase-2-sunset.png)

## Follow-ups

None.

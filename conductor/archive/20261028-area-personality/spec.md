# Area Personality Pass (cave & sunset deco) — Specification

> Requirements are stable. Once an `FR`, `NFR`, or `AC` ID is approved, do not
> renumber it. If a requirement is removed, mark it `Withdrawn` instead of
> deleting it.

## Overview

Give the cave and sunset areas a distinct, instantly-readable visual identity with rich,
hand-placed, code-generated background decoration — fulfilling the product promise that
each area owns one new visual idea — while leaving gameplay, physics, and saves untouched.

## Problem / Motivation

All three `AreaLayout.props` arrays are currently empty; area identity is carried by
palette + tile stamps alone. The cave and sunset areas feel like palette swaps of the
meadow rather than distinct places to explore. For a 4-year-old, distinct places drive
curiosity and the core loop (explore → collect → unlock). If unsolved, areas 2–3 feel
repetitive and the product promise of "distinct decoration shapes per area" stays unmet.

## Goals & Success Metrics

- **Goal:** Cave reads as a glowing crystal cave; sunset reads as warm rounded buttes with grass.
- **Goal:** Decoration is dense enough to feel rich but never hides gameplay.
- **Metric:** Editor screenshots of cave/sunset are unmistakably distinct from meadow and each other.
- **Metric:** Full suite green (`gd-tools test --coverage --min 80`), lint + format clean, reachability tests still pass.
- **Metric:** Live smoke in the editor proves both areas build, play, and return to `stopped`.

## Scope

### In Scope

- Rich deco sets for cave + sunset only (4+ prop types per area, ~5–8 placements each, implementer finalizes exact counts within guidelines).
- Cave vocabulary: glowing crystals + stalactites (+ extras e.g. glow-shrooms / teal moss to reach rich set).
- Sunset vocabulary: rounded buttes + grass tufts (+ extras e.g. warm flowers / pebbles to reach rich set).
- Hand-placed coordinates in `AreaLayout` records, validated like keys/gems.
- New pixel-DSL generators + palette entries in `AssetFactory`, snapshot-pinned, cached textures.
- Background layer only, draw order behind gameplay, chunky rounded shapes.
- Readability guards as hard requirements (no occlusion of keys/gems/door/machine/hint trail).
- Live editor screenshots + smoke evidence for both touched areas.

### Out of Scope

- Meadow changes (stays byte-identical baseline).
- Prop animation, collision/solid props, route changes.
- Tuning, audio, save, wallet/wardrobe, hint-logic, touch-control changes.
- Parent gate, export, playtest session, v2 puzzles.
- Note: per user decision, minor adjacent fixes are allowed only if recorded as deviations in the phase report.

## Functional Requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | Cave area builds with a rich distinct deco set (crystals + stalactites + extras, 4+ types) placed by hand in `AreaLayout` | must |
| FR-2 | Sunset area builds with a rich distinct deco set (rounded buttes + grass tufts + extras, 4+ types) placed by hand in `AreaLayout` | must |
| FR-3 | All prop placements are validated data (seated on surfaces, inside bounds, deterministic) | must |
| FR-4 | Props are decorative only: no collision, no route/reachability change, key tiers unchanged | must |
| FR-5 | New shapes are generated via `AssetFactory` pixel-DSL + palette records, cached, covered by asset-spec completeness test | must |
| FR-6 | Props never occlude keys, gems, door, gift machine, HUD, or hint-trail readability (bg layer, offsets checked) | must |
| FR-7 | Existing behavior preserved: gem budget (10/area), keys fresh per build, save/load untouched, meadow identical | must |

## Non-Functional Requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Startup stays sub-second; no new per-frame cost (static props, cached textures); 60 FPS intent on mid-range tablet |
| NFR-2 | No external assets of any kind (art lives in code + generated textures) |
| NFR-3 | Toddler-safe visuals: chunky rounded silhouettes, no sharp/thin geometry, no flashing >3 Hz (static deco) |
| NFR-4 | Any new tuning values live in `src/tuning/tuning.gd`, never scattered |
| NFR-5 | No reading required: deco communicates place-identity visually only |

## Acceptance Criteria

| ID | Criterion | Verifies |
| --- | --- | --- |
| AC-1 | Cave screenshot shows crystal/stalactite identity, unmistakably distinct from meadow | FR-1 |
| AC-2 | Sunset screenshot shows butte/tuft identity, unmistakably distinct from meadow and cave | FR-2 |
| AC-3 | `cave.props` and `sunset.props` non-empty with 4+ types each; `meadow.props` unchanged (empty) | FR-1, FR-2, FR-7 |
| AC-4 | Reachability suite passes (no column step >2 tiles, keys at verified tiers, gems reachable) | FR-3, FR-4 |
| AC-5 | New assets snapshot-pinned and asset-spec completeness test passes | FR-5 |
| AC-6 | In screenshots + smoke, no key/gem/door/machine/hint occluded by props | FR-6 |
| AC-7 | Full gate green: `gd-tools test --coverage --min 80`, `gd-tools lint`, `gd-tools format --check`; live session `ready`, both areas open with sane hierarchy, screenshots captured, smoke run returns to `stopped` | FR-7, NFR-1 |

## Edge Cases

- Props near spawn, door, gift machine, or `machine_tag` offset overlap on 4x zoom — keep clear margins.
- Hint-trail dots path stays readable over deco (contrast + bg layer).
- Dense dressing must not hide small gems (offset + glow/salience preserved).
- Non-16:9 viewports: bg props stay in-bounds, no reliance on fixed 1280x720 coordinates.
- Save/load untouched: `taken` flags and `area_index` semantics unchanged; keys still fresh per build.
- Palette regeneration (area theming) keeps new props legible in all three palettes.

## Dependencies

- **Tracks:** none (builds on merged `master` only)
- **External:** none

## Open Questions & Assumptions

- **Assumption:** Priority is `medium` (user left priority unanswered; defaulted per workflow).
- **Assumption:** Rich set = 4+ types per area, ~5–8 placements each; exact counts finalized in plan/implementation within guidelines.
- **Assumption:** Meadow stays byte-identical; no animation or collision in this track.
- **Assumption:** Base is `master` @ `7b567936beb4106d3aaa62f0b04ba613adff15e0`.

## References

- `conductor/product.md`, `conductor/product-guidelines.md`, `conductor/tech-stack.md`
- `src/levels/area_layout.gd`, `src/levels/area_builder.gd`
- `src/factory/asset_factory.gd`, `src/factory/asset_spec.gd`, `src/factory/palettes.gd`, `src/factory/pixel_dsl.gd`
- Archive: `conductor/archive/20261027-gem-shop`, `20261027-audio-synthesis`, `20261028-resume-mid-adventure`

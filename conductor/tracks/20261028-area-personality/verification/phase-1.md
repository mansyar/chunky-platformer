# Phase 1 Evidence — Deco art pipeline (factory + spec + snapshots)

- Track: 20261028-area-personality — Area Personality Pass (cave & sunset deco)
- Phase: 1 — Deco art pipeline (factory + spec + snapshots)
- Date: 2026-10-28 (UTC)
- Branch: feat/20261028-area-personality
- Base: 73a5253c58862d4a852434cc0e9abd8c0640d8a3
- Head: 33546209dd9453fcf247ec116ede2c0669bf59f7
- Result: verified

## Scope recap

Cave + sunset prop art generates via AssetFactory, palette-bound, snapshot-pinned.
Art only: no layout placement, no builder/gameplay/save/audio/touch changes
(Phase 2). Meadow palette/spec entries untouched.

## Commits

- 55d90c3 `feat(assets): add cave/sunset palette keys and personality deco spec entries` (P1.T1)
- 5dc1d62 `feat(assets): add cave and sunset pixel-DSL deco generators` (P1.T2, P1.T3)
- 0f69891 `test(assets): pin personality deco snapshots, atlas grid, spec completeness` (P1.T4)
- 3354620 `test(assets): fix pebble glint assertion to use generator fallback` (P1.T4 fix)

## New assets (8 deco, 16x16, palette "area")

- Cave: deco_crystal, deco_stalactite, deco_glowshroom, deco_moss
- Sunset: deco_butte, deco_sunset_tuft, deco_sunbloom, deco_pebble
- Palette keys added to cave only: crystal, crystal_dark, glow, moss.
- Palette keys added to sunset only: butte, butte_dark, bloom, pebble.
- Meadow palette keeps exactly its 6 base colors (pinned by
  test_meadow_palette_is_untouched).

## Commands

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| unit+coverage | `gd-tools test --coverage --min 80` | 0 | 395/395 pass; 95.1% lines, 94.1% branches (gate 80) |
| live | godot-ai `session_manage` op `list` | 0 | chunky-platformer session `ready` (Godot 4.7.2, play_state `stopped`) |

First run (74s) failed on one new test (pebble snapshot read a `glow` key
the sunset palette does not define); fixed the assertion to use the same
fallback the generator uses, re-ran once, green (65s). One fix retry used
of two allowed.

Note: `gd-tools test` emits pre-existing benign warnings (unknown-asset
probes, save-corruption fixtures, exit-time RID/ObjectDB leaks) also present
before this phase; no new warnings introduced.

## Live checks

Art-only phase: no scene touched, so no screenshot/smoke per the brief —
those belong to Phase 2. Editor session confirmed live via godot-ai MCP
`session_manage` (`op: "list"`): session `chunky-platformer@4a3d57e57dfc27d7`,
`readiness: "ready"`, `play_state: "stopped"`, current scene
`res://src/levels/game.tscn`.

## Acceptance criteria

| ID | Criterion | Evidence | Status |
| --- | --- | --- | --- |
| AC-5 | New assets snapshot-pinned and asset-spec completeness test passes | tests/test_asset_snapshots.gd (8 structure tests + determinism over cave/sunset); tests/test_asset_spec.gd (personality deco set, palette keys, meadow-untouched); suite green | pass |
| FR-5 | New shapes via AssetFactory pixel-DSL + palette records, cached, spec-covered | src/factory/asset_factory.gd `_ops_for` arms; src/factory/palettes.gd keys; src/factory/asset_spec.gd entries; `test_factory_generates_every_spec_asset` + cache tests cover new entries automatically | pass |
| NFR-2 | No external assets (art lives in code + generated textures) | All 8 assets are PixelDsl op lists; no new files/imports | pass |
| NFR-3 | Toddler-safe visuals: chunky rounded, no sharp/thin geometry, no flashing (static deco) | Every spike/tooth ends in a disc; 2px+ features; static textures, no animation code | pass |
| NFR-4 | New tunable values live in src/tuning/tuning.gd, never scattered | No new tunable values: colors are palette records, sizes are spec data; tuning.gd untouched | pass |

## Evidence paths

- Suite log: `.gd-tools/artifacts/fb011b9d16254e40ae9246b3e62fd84d/artifacts.json`
- Tests: tests/test_asset_spec.gd, tests/test_asset_factory.gd, tests/test_asset_snapshots.gd
- Sources: src/factory/asset_factory.gd, src/factory/asset_spec.gd, src/factory/palettes.gd

## Deviations

None. All changes are inside `Touches`. tuning.gd intentionally untouched
(static art needs no tuning values). Existing tests updated only where the
new set changes asserted totals: atlas 32px→64px tall (15 world tiles),
tile count 8→16.

## Notes

- Tile-atlas coordinates of the 7 pre-existing tiles are unchanged (new deco
  appended after deco_flower); pinned by old + new coordinate assertions.
- New deco assets are kind `deco` (16x16, atlas-packed) and loadable as prop
  sprites via `get_texture`, matching the existing `deco_rock`-as-prop
  pattern Phase 2 will use for hand-placed `props`.
- Phase 2 owns: hand-placed cave/sunset `props`, builder bg-layer wiring,
  reachability/key-tier checks, screenshots + smoke run (AC-1..AC-4, AC-6, AC-7).

## Rework (primary verification follow-up)

Primary verification found two static-check failures in
tests/test_asset_snapshots.gd: `max-public-methods` (28 public methods after
the 9 personality tests were added) and a formatting nit. Fixed by splitting
the 9 personality snapshot tests (8 structure + 1 determinism, assertions
unchanged) into tests/test_asset_snapshots_personality.gd — inside the
phase's `tests/test_asset_*.gd` Touches — and running the project formatter.
Commit: 9d01c32 `test(assets): split personality snapshots to satisfy lint
method limit` (also stages the new script's `.gd.uid`).

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| unit+coverage | `gd-tools test --coverage --min 80` | 0 | 395/395 pass; 95.1% lines, 94.1% branches (gate 80) |
| lint | `gd-tools lint` | 0 | No lint issues found (72 files) |
| format | `gd-tools format --check` | 0 | All 72 files formatted |

Suite log: `.gd-tools/artifacts/ca55470b59344fe9896f2b319369baa7/artifacts.json`.

## Primary verification

Independent re-run by the primary on `feat/20261028-area-personality`:

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| unit+coverage | `gd-tools test --coverage --min 80` (1st) | 1 | 394/395; single failure `test_audio_synthesis.test_pregeneration_at_startup_is_fast` (sub-second wall-clock assertion tripped under suite load; audio code untouched by this phase) |
| unit (isolated) | `gd-tools test --test test_pregeneration_at_startup_is_fast` | 0 | 1/1 pass in 0.04s — confirms load flake, not a regression |
| unit+coverage | `gd-tools test --coverage --min 80` (retry) | 0 | 395/395 pass; 95.1% lines, 94.1% branches (gate 80) |
| lint (pre-rework) | `gd-tools lint` | 1 | 1 error: `test_asset_snapshots.gd` max-public-methods → rework requested |
| format (pre-rework) | `gd-tools format --check` | 1 | 1 file needs formatting → rework requested |
| lint (post-rework) | `gd-tools lint` | 0 | No lint issues found |
| format (post-rework) | `gd-tools format --check` | 0 | All 72 files formatted |
| unit+coverage (post-rework) | `gd-tools test --coverage --min 80` | 0 | 395/395 pass; 95.1% lines, 94.1% branches (gate 80); log `.gd-tools/artifacts/8a63d73a81ec4732a91d4e3bcfb63a3/artifacts.json` |

- Files changed (`73a5253..HEAD`) are all inside the phase `Touches` (`src/factory/*` × 3, `tests/test_asset_*` × 4 incl. the split-off `test_asset_snapshots_personality.gd` + its `.gd.uid`) plus the phase evidence file. Meadow palette/spec entries untouched per evidence.
- Acceptance: FR-5, NFR-2, NFR-3, NFR-4, AC-5 all pass (evidence tables above). Result: **verified**.

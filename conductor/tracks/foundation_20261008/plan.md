# Implementation Plan — Foundation (Bootstrap)

## Phase 1: Project Scaffold & Toolchain [checkpoint: f579ae8]

- [x] Task: Create Godot project with required settings [498ca06]
  - project.godot: Godot 4.5+ config, 1280×720 landscape, canvas_items
    stretch, nearest filtering
  - Feature-first directory skeleton: src/factory/, src/robot/,
    src/world/, src/proof/, tests/
- [x] Task: Bootstrap gd-tools [54ee8ec]
  - Run gd-tools init; verify generated configs (gd-tools.toml, gdlintrc,
    gdformatrc)
  - Create tests/ with a trivial smoke suite extending GdToolsTest
  - Verify: gd-tools doctor; gd-tools test passes; gd-tools format --check
    && gd-tools lint clean
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Pixel-Drawing DSL [checkpoint: 34a9c8]

- [x] Task: Write failing unit tests for DSL primitives [b758f7f]
  - rect, disc, outline, shade produce correct pixels on small test buffers
    (edge cases: out-of-bounds, alpha, blend behavior)
- [x] Task: Implement DSL helpers to pass tests [b758f7f]
- [x] Task: Refactor DSL API for ergonomics (data-driven op lists), rerun tests [34a9c8]
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 3: Palettes & Asset Spec [checkpoint: f8a9fd]

- [x] Task: Write failing test for asset-spec completeness contract [f8a9fd]
  - Every spec entry must yield a factory output (name, dimensions, palette)
- [x] Task: Define palette constants (PALETTE_MEADOW, PALETTE_CAVE,
  PALETTE_SUNSET) in a single palette file [f8a9fd]
  - Deviation: implemented as a single `AREA_PALETTES` dictionary keyed by
    name ("meadow"/"cave"/"sunset") instead of three separate constants —
    palettes stay in one file but resolve by string, which the spec test
    and the factory's palette-parameterized generation both rely on.
- [x] Task: Define asset spec data: 8 tiles, 8 robot frames (idle ×2, walk ×4,
  jump ×1, land-squash ×1), gem, key, door (locked/open) [f8a9fd]
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 4: AssetFactory [checkpoint: de34e42]

- [x] Task: Write failing unit tests for factory logic [3e6c711]
  - Generates every spec'd asset; caches by palette; typed accessors;
    repeated calls return cached objects
- [x] Task: Implement AssetFactory autoload (visual generation + cache +
  accessors) to pass tests [3e6c711]
- [x] Task: Add audio-generation stub interface (no-op implementations)
  [9f32956]
- [x] Task: Pin snapshot tests for key outputs (robot frames, tile atlas,
  gem, key, door) and lock determinism [34db746]
- [x] Task: Verify startup generation completes in < 1 second [de34e42]
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 5: Proof Scene

- [~] Task: Build proof scene
  - Ground + platform + sky + decorations from generated tiles; robot idle
    frame standing on ground; set as main scene
- [ ] Task: Full gate run: gd-tools format --check && gd-tools lint &&
  gd-tools test --coverage --min 80
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
  - Manual verification: fresh-clone run via editor, robot visible on
    generated world, no external assets loaded

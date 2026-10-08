# Track Specification — Foundation (Bootstrap)

## Overview

Establish the Godot project scaffold and the code-generated art pipeline that
every subsequent phase consumes. This track delivers: a configured Godot 4.5+
project, the gd-tools toolchain bootstrap, the pixel-drawing DSL, the
structured asset spec, the `AssetFactory` autoload (visual generation +
audio stub), and a minimal proof scene that visually validates the pipeline.

## Functional Requirements

### 1. Project Scaffold
- Godot 4.5+ project (`project.godot`): 1280×720 landscape viewport,
  `canvas_items` stretch mode, nearest-neighbor texture filtering.
- **Feature-first layout:** `src/<feature>/` folders (e.g. `src/factory/`,
  `src/robot/`, `src/world/`, `src/proof/`) each holding that feature's
  scripts and scenes; `tests/` for gd-tools suites.
- gd-tools bootstrapped: `gd-tools init` and generated configs
  (`gd-tools.toml`, `gdlintrc`, `gdformatrc`). No pre-commit hooks —
  quality gates run manually before each commit.

### 2. Pixel-Drawing DSL
- A module of helpers over `Image` buffers: `rect`, `disc`, `outline`,
  `shade` (plus minimal primitives as needed by the spec).
- Frames/sprites are defined as *data* (lists of DSL operations), not
  hand-coded pixel loops.
- All generation is deterministic: identical inputs → identical output.

### 3. Asset Spec (in-code)
- Typed GDScript const data (dictionaries/enums) listing every asset:
  name, dimensions, palette reference, generator operation list.
- A test asserts the factory produces **every** asset in the spec.

### 4. Palettes
- Named constants in a single palette file (`PALETTE_MEADOW`,
  `PALETTE_CAVE`, `PALETTE_SUNSET`) — all three defined now, referenced
  by the asset spec.

### 5. AssetFactory Autoload
- Generates all spec'd assets at startup (target: < 1 second), caches
  by palette, exposes typed accessors for textures.
- Generates:
  - **Tile atlas** (~8 tiles): solid block, grass-top block, platform,
    trampoline base, grass tuft, rock, flower, sky background strip.
  - **Robot frames** (8 total): idle ×2, walk ×4, jump ×1, land-squash ×1.
  - **Props:** gem, key, door (locked + open states).
- **Audio stub:** factory exposes an audio-generation interface with
  no-op implementations (filled in during the Audio phase).

### 6. Proof Scene
- Minimal scene (`src/proof/`) using generated tiles as ground/platform,
  the robot idle frame standing on it, and the background/decoration tiles.
- Set as the project's main scene.

## Non-Functional Requirements

- Zero external assets in the repository (no textures, audio, fonts).
- Startup generation completes in under 1 second on mid-range hardware.
- Visual outputs verified by deterministic snapshot tests (`assert_snapshot`);
  logic (spec completeness, factory caching) by unit tests with ≥80% coverage
  for logic-bearing modules per `workflow.md`.
- `gd-tools format --check && gd-tools lint && gd-tools test` all pass.

## Acceptance Criteria

1. Fresh clone runs the proof scene from the editor with no import step.
2. Proof scene shows: generated ground + platform + sky + decorations, robot
   idle frame standing on the ground.
3. `AssetFactory` produces every asset declared in the spec, verified by
   test, in < 1 second at startup.
4. Snapshot tests pass and lock the generated visuals.
5. All gd-tools gates pass (run manually before each commit; no hooks).

## Out of Scope

- Movement/jump physics and input handling (Movement & camera phase).
- TileMap world layout, multi-layer design, trampoline behavior.
- Gem/key/door *behavior* (sprites only in this track).
- Audio generation implementation (stub only).
- Areas 2–3 themes beyond palette constants.

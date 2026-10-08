# Technology Stack — Robo's Treasure Hunt

## Engine & Language

- **Engine:** Godot 4.5+ (required by gd-tools; latest stable 4.x)
- **Language:** GDScript (typed where practical; no C#/GDExtension for v1)
- **Scene model:** Node/scene composition; gameplay via `CharacterBody2D`,
  interactables via `Area2D`, world via `TileMapLayer`, UI via `CanvasLayer`

## Asset Generation (No External Assets) — All Pixel Art

Everything is procedurally generated pixel art, produced at startup by an
`AssetFactory` autoload and cached in memory. No imported textures, audio,
or fonts exist in the repository.

- **Factory:** `AssetFactory` autoload generates all assets during startup
  (sub-second target) and caches them by palette. A small pixel-drawing DSL
  (rect/disc/outline/shade helpers over `Image` buffers) lets frames be
  defined as data rather than hand-coded pixels.
- **Asset spec first:** the full asset list (name, dimensions, palette refs)
  is defined as a structured spec; factory generators are built against it
  and a test asserts every spec'd asset is produced.
- **Tiles & props:** Generated `ImageTexture` atlases per area palette for
  `TileSet`/`TileMapLayer` (mandatory — TileMap requires real textures),
  plus gems, keys, doors, trampolines, decorations.
- **Robot:** Multi-frame generated textures — walk cycle, jump, landing
  squash — swapped procedurally; palette lives in code constants.
- **Palettes:** Each area's theme is a palette record passed to the factory;
  area theming = regeneration with different parameters.
- **Audio:** Pre-generated `AudioStreamWAV` buffers at startup — synthesized
  SFX (jump, bounce, collect, key, door, celebration) and one gentle ambient
  music loop per area (loop-enabled, tone-layered).

## Development Tooling — gd-tools

Unified development workflow CLI for GDScript ([mansyar/gd-tools](https://github.com/mansyar/gd-tools),
`pip install gd-tools-cli`, Python 3.10+):

- **Bootstrap:** `gd-tools init` — deploys native test + coverage addons,
  generates `gd-tools.toml`, `gdlintrc`, `gdformatrc` (idempotent).
- **Test:** `gd-tools test` — native runtime, suites extend `GdToolsTest`
  and run inside the engine (real scene tree, real signals, doubles/spies).
  Supports `--coverage`, `--watch`, `--changed`, `--parallel`, JUnit XML.
- **Lint:** `gd-tools lint` (gdlint wrapper).
- **Format:** `gd-tools format` (gdformat wrapper) with `--check` for CI.
- **Coverage:** `gd-tools test --coverage --min 80` — line + branch coverage
  with threshold gates. Focus: gameplay logic (physics tuners, save/load,
  hint logic, collectible state, AssetFactory); draw/frame data excepted.
- **Diagnostics:** `gd-tools doctor` for environment verification.

*(Note: no pre-commit hooks — format/lint/test gates are run manually before
each commit, per the workflow.)*

## Data & Persistence

- **Save format:** JSON via `FileAccess` to `user://` (progress: keys, doors,
  gem count, robot position). Corrupt/missing file falls back to fresh start.

## Export Targets (v1)

- **Windows desktop** (development + keyboard play)
- **Android** (tablet, landscape, touch controls)

## Version Control

- **Git**, conventional commits (see `workflow.md`), `conductor/` tracked
  alongside source.

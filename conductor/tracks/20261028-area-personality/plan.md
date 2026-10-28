# Area Personality Pass (cave & sunset deco) — Implementation Plan

> **Branch:** `feat/20261028-area-personality`
> **Base:** `master` @ `7b567936beb4106d3aaa62f0b04ba613adff15e0`
>
> Phase states are `pending`, `in_progress`, `verified`, `failed`, or `blocked`.
> Only the primary agent writes this file. Phase subagents report results and the
> primary records them.

## Phase 1: Deco art pipeline (factory + spec + snapshots)

- **Goal:** Cave + sunset prop art generates via AssetFactory, palette-bound, snapshot-pinned.
- **Depends on:** none
- **Covers:** FR-5, NFR-2, NFR-3, NFR-4, AC-5
- **Touches:** `src/factory/asset_factory.gd`, `src/factory/asset_spec.gd`, `src/factory/palettes.gd`, `tests/test_asset_*.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** verified

- [x] **P1.T1: Palette + asset-spec records** — covers: FR-5
  - [x] **P1.T1.1: Cave palette entries for crystal/stalactite/glow set**
  - [x] **P1.T1.2: Sunset palette entries for butte/tuft/warm set**
  - [x] **P1.T1.3: Asset-spec entries for all new prop textures**
- [x] **P1.T2: Cave generators** — covers: FR-5
  - [x] **P1.T2.1: Crystals via pixel-DSL (chunky, glowing)**
  - [x] **P1.T2.2: Stalactites (rounded, no sharp edges)**
  - [x] **P1.T2.3: Extra cave props to reach rich set (e.g. glow-shrooms / moss)**
- [x] **P1.T3: Sunset generators** — covers: FR-5
  - [x] **P1.T3.1: Rounded buttes via pixel-DSL**
  - [x] **P1.T3.2: Grass tufts (chunky, high-contrast)**
  - [x] **P1.T3.3: Extra sunset props to reach rich set (e.g. flowers / pebbles)**
- [x] **P1.T4: Snapshot + spec completeness** — covers: AC-5
  - [x] **P1.T4.1: Snapshot-pin all new textures**
  - [x] **P1.T4.2: Spec completeness test covers new entries**

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** 1b3df58
**Evidence:** conductor/tracks/20261028-area-personality/verification/phase-1.md
-->

## Phase 2: Layout integration + live verification

- **Goal:** Cave + sunset layouts dress richly with validated hand-placed bg props; game plays identically with distinct identity proven live.
- **Depends on:** Phase 1
- **Covers:** FR-1, FR-2, FR-3, FR-4, FR-6, FR-7, NFR-1, NFR-5, AC-1, AC-2, AC-3, AC-4, AC-6, AC-7
- **Touches:** `src/levels/area_layout.gd`, `src/levels/area_builder.gd`, `tests/test_area_*.gd`, `tests/test_playthrough.gd`, `tests/test_goal*.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** in_progress

- [ ] **P2.T1: Cave placement** — covers: FR-1
  - [ ] **P2.T1.1: Hand-place cave props coordinates in AreaLayout**
  - [ ] **P2.T1.2: Validate seating, bounds, determinism**
- [ ] **P2.T2: Sunset placement** — covers: FR-2
  - [ ] **P2.T2.1: Hand-place sunset props coordinates in AreaLayout**
  - [ ] **P2.T2.2: Validate seating, bounds, determinism**
- [ ] **P2.T3: Builder wiring (bg layer)** — covers: FR-3, FR-4
  - [ ] **P2.T3.1: Build props behind gameplay with correct draw order, no collision**
  - [ ] **P2.T3.2: Meadow build unchanged (empty props, byte-identical)**
- [ ] **P2.T4: Readability + live evidence** — covers: FR-6, AC-6
  - [ ] **P2.T4.1: Reachability + key-tier + hint-occlusion checks green**
  - [ ] **P2.T4.2: Editor screenshots of cave/sunset + smoke run (stopped afterwards)**

<!--
Review fixes are appended by `conductor-review` as:

## Phase R1: Review Fixes

- **Goal:** Resolve review findings ...
- **Depends on:** Phase 2
- **Covers:** review findings
- **Touches:** ...
- **Verification:** ...
- **Status:** pending

- [ ] **R1.T1: Resolve <finding ID>** — covers: <finding ID>
-->

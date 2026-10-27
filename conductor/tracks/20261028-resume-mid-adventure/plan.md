# Resume-mid-adventure fix — Implementation Plan

> **Branch:** `feat/20261028-resume-mid-adventure`
> **Base:** `master` @ `b4536b27b5d9c510ebe563e882ebdde94dfcb7b4`
>
> Phase states are `pending`, `in_progress`, `verified`, `failed`, or `blocked`.
> Only the primary agent writes this file. Phase subagents report results and the
> primary records them.

## Phase 1: Save V2 + migration

- **Goal:** `area_index` persists in schema V2 with V1 migration, clamping, and safe recovery.
- **Depends on:** none
- **Covers:** FR-1, FR-3, FR-4, NFR-2, NFR-3, AC-2, AC-3, AC-5
- **Touches:** `src/systems/save_game.gd`, `tests/test_save_game*.gd`, plus rework R1
  (user-authorized, test-only): `tests/test_audio_ambient.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** in_progress (rework R1 — user authorized 2026-10-27: minimal test-only fix
  for the pre-existing audio timing assertion under coverage instrumentation)

**Result:** blocked — code complete (commits `5ce9b5b`, `78adc2d`), all phase AC tests
green, coverage 95.1%/94.0% (gate met), lint/format clean; but the Verification
command exits 1 on pre-existing `test_audio_ambient` wall-clock timing test that fails
only under coverage instrumentation (passes standalone + non-coverage runs; untouched
by this track). Awaiting unblock decision — see evidence.
**Evidence:** conductor/tracks/20261028-resume-mid-adventure/verification/phase-1.md

- [ ] **P1.T1: V2 schema with area_index persist + clamp** — covers: FR-1, FR-4
  - [ ] **P1.T1.1: Extend to_dict/sanitize with area_index and range clamp**
  - [ ] **P1.T1.2: Cover persist round-trip and out-of-range clamp tests**
- [ ] **P1.T2: V1 migration + corrupt/future recovery** — covers: FR-3
  - [ ] **P1.T2.1: V1 file migrates preserving wallet/owned/worn/taken defaulting area 0**
  - [ ] **P1.T2.2: Corrupt/empty/future-version boots fresh meadow with no crash**

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261028-resume-mid-adventure/verification/phase-1.md
-->

## Phase 2: Boot restore + finale reset

- **Goal:** Game boots into the saved area at spawn, saves on swap, and resets to 0 after the finale with keys fresh.
- **Depends on:** Phase 1
- **Covers:** FR-2, FR-5, FR-6, NFR-1, NFR-4, AC-1, AC-4
- **Touches:** `src/levels/game.gd`, `tests/test_game*.gd`, `tests/test_goal*.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** pending

- [ ] **P2.T1: Restore saved area on boot and save on swap** — covers: FR-2, FR-1
  - [ ] **P2.T1.1: Boot reads area_index and builds that area at spawn**
  - [ ] **P2.T1.2: Area swap persists new index; resumed area rebuilds keys fresh**
- [ ] **P2.T2: Finale loop saves area 0** — covers: FR-5, FR-6
  - [ ] **P2.T2.1: Final-door celebration loops home and commits area 0**
  - [ ] **P2.T2.2: Live smoke proves cave resume and finale-to-meadow in editor**

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261028-resume-mid-adventure/verification/phase-2.md
-->

## Phase 3: Doc sync + integrated verification

- **Goal:** Product wording is canonical and the full track verifies end to end.
- **Depends on:** Phase 2
- **Covers:** FR-7, NFR-1, NFR-4, AC-6, AC-7
- **Touches:** `conductor/product.md`, `conductor/tracks/20261028-resume-mid-adventure/verification/`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** pending

- [ ] **P3.T1: Resolve product.md resume contradiction** — covers: FR-7
  - [ ] **P3.T1.1: Persistence/progression names resume-in-saved-area with fresh keys**
- [ ] **P3.T2: Integrated verification + live evidence** — covers: AC-6, AC-7
  - [ ] **P3.T2.1: Full suite green plus editor hierarchy/screenshot/smoke**

<!--
Review fixes are appended by `conductor-review` as:

## Phase R1: Review Fixes

- **Goal:** Resolve review findings ...
- **Depends on:** Phase 3
- **Covers:** review findings
- **Touches:** ...
- **Verification:** ...
- **Status:** pending

- [ ] **R1.T1: Resolve <finding ID>** — covers: <finding ID>
-->

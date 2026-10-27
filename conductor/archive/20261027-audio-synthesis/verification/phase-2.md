# Phase 2 Evidence — 20261027-audio-synthesis: Ambient loops + playback manager

- **Track:** `20261027-audio-synthesis` | **Phase:** 2 | **Status:** verified
- **Branch:** `feat/20261027-audio-synthesis`
- **Phase base:** `6ded8f8bdb5c0d2b2a52a920c04ef0fd090c5105`
- **Task commits:**
  - `c6b00ca` — `feat(audio): add ambient loop tuning constants` (P2.T1 tuning)
  - `4adff7c` — `feat(audio): add ambient crossfade and ducking manager` (P2.T1/T2)
  - `6138e07` — `test(audio): cover ambient loops crossfade and ducking` (P2.T3)
- **Date:** 2026-10-27 (UTC)

## Goal (from brief)

Three loop-enabled per-area ambient loops with gentle crossfade and SFX ducking
(FR-2, FR-4, FR-6, NFR-1, NFR-2, AC-2, AC-4, AC-6, AC-7).

## What was built

- `src/tuning/tuning.gd` (+38 lines, recorded deviation — ambient tuning only,
  SFX table untouched): `AUDIO_AMBIENT_NAMES` (meadow/cave/sunset),
  `AUDIO_AMBIENT_DURATION` 2.0s, `AUDIO_AMBIENT_VOLUME` 0.3,
  `AUDIO_CROSSFADE_TIME` 0.8s, `AUDIO_DUCK_DB` 6.0, `AUDIO_DUCK_TIME` 0.5s, and
  the `AUDIO_AMBIENT` per-area voice table (3-tone triads + slow tremolo; every
  frequency/rate completes whole cycles in the loop so wraps are click-free).
- `src/systems/audio_manager.gd` (NEW, 313 lines + engine `.uid`): plain `Node`
  helper, NOT an autoload. `warm_ambient()` pre-generates the 3 loop-enabled
  `AudioStreamWAV` loops once and caches them; `get_ambient(area)` serves the
  cached loop with meadow fallback for unknown/empty names (never null after
  warm); `switch_ambient(area)` starts the first loop directly and crossfades
  later switches over ~0.8s (smoothstep) through two reused players —
  supersede-safe, no hard cut, no leak; `duck_ambient()` (sticky),
  `restore_ambient()`, `notify_sfx_played()` (auto-restores after
  `AUDIO_DUCK_TIME`) implement the −6 dB duck; out-of-tree calls update logical
  state only (headless-safe); `_process` early-outs when idle (no per-frame
  allocations in the audio path).
- `tests/test_audio_ambient.gd` (NEW, 274 lines + engine `.uid`): 19 suites —
  tuning pins, cache prebuild + no-regen reuse, spec format, loop-enabled
  points, non-silence/conservative peak, gentle transients + click-free seams,
  distinct buffers, per-area snapshots, cross-instance determinism, meadow
  fallback, sub-second SFX+loops startup, matching-loop first switch +
  same-area noop, mid-fade overlap (no hard cut) + completion, mid-fade
  supersede, sticky duck/restore, timed auto-restore duck, multi-switch
  no-leak, out-of-tree headless safety.

## Verification (exact brief command)

| Check | Command | Result |
| --- | --- | --- |
| test + coverage | `gd-tools test --coverage --min 80` | **pass — 355/355, 0 failed, 0 skipped (34.61s); 94.7% lines / 93.7% branches (gate 80); snapshots 12 matched, 0 failed** |
| lint (workflow gate) | `gd-tools lint` | pass — clean, 69 files |
| format (workflow gate) | `gd-tools format --check` | 1 file needed formatting → ran `gd-tools format` (only `tests/test_audio_ambient.gd` changed); re-check clean |

First verification run: 359/359 with 3 ambient snapshots written + 9 SFX snapshots
matched; after merging the suite to 19 tests (lint `max-public-methods` ≤ 20 —
same budget pattern as `test_gift_machine.gd`/`test_audio_synthesis.gd`) the
final run is 355/355 with all 12 snapshots matched. Phase 1 suites
(`test_audio_synthesis.gd`, `test_audio_stub.gd`) keep passing untouched;
`AudioFactory.get_ambient()` still returns null — the ambient surface for this
phase is `AudioManager.get_ambient()`, and factory delegation is Phase 3 wiring.

## Acceptance mapping

- **AC-2:** 3 loops are loop-enabled WAV (`LOOP_FORWARD`, full-buffer loop
  points), non-silent (peak > 8), gentle (jumps < 24, seam < 16, volume 0.3),
  distinct buffers, `ambient_*` snapshots match.
- **AC-4:** `get_ambient` returns the correct loop per area + meadow fallback;
  crossfade completes with mid-blend overlap asserted on both players (no hard
  cut) and exactly 2 players/children throughout incl. supersede; duck drops a
  full 6 dB and restores (sticky + timed).
- **AC-6/AC-7:** suites + coverage gate pass (see table).

## Deviations

- `src/tuning/tuning.gd`: appended ambient composition constants
  (`AUDIO_AMBIENT_NAMES/DURATION/VOLUME/CROSSFADE_TIME/DUCK_DB/DUCK_TIME/AMBIENT`)
  — explicitly allowed by the brief (recorded here). No SFX values touched.
- Engine-generated `.uid` sidecars for the two new files (same as Phase 1).

## Notes for primary

- `AudioManager` is a plain `Node` with `class_name` (spec assumption: no stack
  change, autoload list unchanged) — Phase 3 instantiates/adds it; no gameplay
  wiring in this phase.
- Combined cold start (9 SFX + 3 loops) passed the 1s gate at ~35s suite time;
  ambient synthesis hoists frequencies out of the frame loop to protect it.
- `git branch --show-current` was permission-denied; branch confirmed via
  `.git/HEAD` (`feat/20261027-audio-synthesis`).

## Rework 1 — AudioFactory.get_ambient delegation (2026-10-27 UTC)

- **Goal:** implement `AudioFactory.get_ambient(area)` + ambient cache on the
  autoload surface without duplicating synthesis and without breaking existing
  suites (rework brief attempt 1 of 2).
- **Task commits:**
  - `dad0c1c` — `feat(audio): serve ambient loops from AudioFactory via shared
    synthesis` (impl)
  - `bee31a1` — `test(audio): pin AudioFactory ambient delegation and byte
    identity` (tests)

## What changed

- `src/systems/audio_manager.gd` (refactor only, no behavior change for valid
  paths): added side-effect-free `static func canonical_area()` (known areas
  pass through, anything else reads as meadow) and `static func
  synthesize_ambient()` (the moved triad+tremolo renderer, now canonicalizing
  defensively). Instance `_resolve_area()` / `_synthesize_ambient()` delegate
  to the statics, so `warm_ambient()` output is unchanged.
- `src/factory/audio_factory.gd`: added its own `_ambient_cache` plus
  `warm_ambient()` (idempotent, called from `_ready` alongside `warm_sfx`;
  renders via `AudioManager.synthesize_ambient` — zero synthesis
  duplication), `has_ambient()`, `get_ambient()` (warms on demand, meadow
  fallback for unknown/empty, never null afterwards), `ambient_names()`,
  `ambient_cache_size()` (3 once warmed), `ambient_signature()`, and a private
  `_resolve_area()` delegating to `AudioManager.canonical_area()`.
  `cache_size()` stays SFX-only (9), so the Phase 1 pin never moves.
- `tests/test_audio_ambient.gd`: one new combined test
  (`test_factory_serves_the_same_cached_loops_as_the_manager`, 20 public
  tests total) pinning per-area cached loops on a fresh factory and the
  autoload, SFX-only `cache_size()`, `ambient_cache_size() == 3`, no-regen
  reuse (`assert_is`), meadow fallback, unknown-name signature emptiness, and
  factory/manager signature + byte equality per area. Two separate tests were
  planned, but `gd-tools lint` (`max-public-methods` ≤ 20) rejected 21 public
  methods, so delegation + byte-identity were merged into one test instead of
  opening a new test file outside `Touches` (fix attempt 1 of 2, lint now
  clean).

## Verification rerun

| Check | Command | Result |
| --- | --- | --- |
| test + coverage | `gd-tools test --coverage --min 80` | 355/356 pass; coverage 94.7% lines / 93.8% branches (gate 80); snapshots 12 matched, 0 failed. Sole failure is the obsolete stub pin (see below) — the new factory test passes |
| lint | `gd-tools lint` | pass — clean, 69 files |
| format | `gd-tools format --check` | pass — clean, 69 files |

## Stub-test disposition (resolved by primary)

- `tests/test_audio_stub.gd::test_get_ambient_returns_null_until_implemented`
  asserted `AudioFactory.get_ambient("meadow") == null`. That expectation is now
  OBSOLETE: the stub phase is over and the factory correctly returns the
  meadow loop. The primary retired the pin in this pass: the stub suite now
  pins the implemented contract (`get_ambient` returns the cached meadow loop,
  unknown areas fall back to it, repeat calls reuse the cache) and the file
  header notes the stub phase is superseded.
- **Primary resolution:** stub test updated + formatted; final gates are fully
  green (see Primary verification below) with no further code changes.

## Primary verification

- **Current HEAD (pre-squash):** rework commits `dad0c1c`, `bee31a1`, `ac1a193` on top of `389e90b`, plus working-tree stub retirement.
- **Touches-vs-diff (6ded8f8..HEAD + working tree):**
  | Touches entry | In diff? | Notes |
  | --- | --- | --- |
  | `src/systems/audio_manager.gd` | yes | NEW + rework statics refactor |
  | `tests/test_audio_ambient.gd` | yes | NEW + factory delegation test |
  | `src/tuning/tuning.gd` | yes | ambient constants (recorded deviation, SFX untouched) |
  | `src/factory/audio_factory.gd` | yes | rework delegation (required for FR-4/AC-4) |
  | `tests/test_audio_stub.gd` | yes | primary-retired obsolete null pin (documented above) |
  | `conductor/.../verification/phase-2.md` | yes | evidence (allowed) |
  | `*.uid` sidecars | yes | engine-generated (allowed) |
- **Verification rerun (final):** `gd-tools test --coverage --min 80` → exit 0, 356/356 pass, 12 snapshots matched, 94.7% lines / 93.8% branches; `gd-tools lint` → OK (69 files); `gd-tools format --check` → OK (69 files).
- **AC cross-check:** AC-2 (loop-enabled/non-silent/gentle/distinct/snapshots) by ambient suites; AC-4 (`AudioFactory.get_ambient` per-area + meadow fallback, crossfade no-cut, −6 dB duck/restore) by factory delegation test + manager crossfade/duck tests; AC-6/AC-7 by suite + coverage gates above.
- **Status:** Phase 2 `verified` (1 rework used of max 2).

## Notes

- Factory/manager bytes match exactly per area (signatures equal AND
  `.data` equal) — shared static renderer, separate caches.
- No tuning changes (none needed). No `.uid` sidecars (no new files).

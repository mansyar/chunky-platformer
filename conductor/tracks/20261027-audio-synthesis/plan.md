# Audio Synthesis — Implementation Plan

> **Branch:** `feat/20261027-audio-synthesis`
> **Base:** `master` @ `1922e2216041189b5618a8a4ad202c543a9835fa`
>
> Phase states are `pending`, `in_progress`, `verified`, `failed`, or `blocked`.
> Only the primary agent writes this file. Phase subagents report results and the
> primary records them.

## Phase 1: SFX synthesis core

- **Goal:** All 9 SFX pre-generate as cached `AudioStreamWAV` at startup and `play()` is polyphonic-safe.
- **Depends on:** none
- **Covers:** FR-1, FR-3, FR-6, NFR-1, NFR-4, NFR-5, AC-1, AC-3, AC-6, AC-7
- **Touches:** `src/factory/audio_factory.gd`, `src/tuning/tuning.gd`, `tests/test_audio_synthesis.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** verified

- [x] **P1.T1: Audio tuning constants** — covers: FR-1
  - [x] **P1.T1.1: Sample format + volume table** — 22050 Hz mono, per-SFX duration / pitch / volume in tuning
  - [x] **P1.T1.2: Voice-cap + safety limits** — cap 8, unknown-name guard values
- [x] **P1.T2: WAV synth engine** — covers: FR-1, FR-6
  - [x] **P1.T2.1: Soft-envelope generator** — sine + attack/decay, no harsh transients, snapshot helper
  - [x] **P1.T2.2: Pre-generate + cache 9 SFX** — jump, bounce, gem, key, door, celebrate, gift_pop, gift_wiggle, gift_bonus at startup
- [x] **P1.T3: play() semantics** — covers: FR-3
  - [x] **P1.T3.1: Polyphonic pool with cap** — oldest-steal, no clipping, unknown-name safe no-op
  - [x] **P1.T3.2: TDD suites + snapshots** — per-SFX non-silence, format, snapshot determinism

**Result:** verified
**Checkpoint:** e7a9c10
**Evidence:** conductor/tracks/20261027-audio-synthesis/verification/phase-1.md

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261027-audio-synthesis/verification/phase-1.md
-->

## Phase 2: Ambient loops + playback manager

- **Goal:** Three loop-enabled per-area ambient loops with gentle crossfade and SFX ducking.
- **Depends on:** Phase 1
- **Covers:** FR-2, FR-4, FR-6, NFR-1, NFR-2, AC-2, AC-4, AC-6, AC-7
- **Touches:** `src/systems/audio_manager.gd`, `tests/test_audio_ambient.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** pending

- [ ] **P2.T1: Ambient composition** — covers: FR-2
  - [ ] **P2.T1.1: Meadow / cave / sunset loops** — tone-layered, slow tempo, loop-enabled WAV
  - [ ] **P2.T1.2: Distinct-yet-gentle check** — spectral softness guard, snapshots per area
- [ ] **P2.T2: Crossfade + duck manager** — covers: FR-4
  - [ ] **P2.T2.1: Area crossfade (~0.8s)** — supersede-safe, no player leak, no hard cut
  - [ ] **P2.T2.2: SFX ducking** — ambient −6 dB under one-shots, restores cleanly
- [ ] **P2.T3: Ambient tests** — covers: FR-4, FR-6
  - [ ] **P2.T3.1: get_ambient + cache tests** — correct loop per area, unknown-area fallback, no regen on repeat

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261027-audio-synthesis/verification/phase-2.md
-->

## Phase 3: Gameplay wiring + live proof

- **Goal:** Every gameplay moment triggers the right sound and the editor smoke run proves it.
- **Depends on:** Phase 2
- **Covers:** FR-5, NFR-2, NFR-3, AC-5, AC-6, AC-7
- **Touches:** `src/robot/robot.gd`, `src/world/*.gd`, `src/levels/game.gd`, `src/levels/area_builder.gd`, `tests/test_audio_wiring.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** pending

- [ ] **P3.T1: Wire movement + bounce** — covers: FR-5
  - [ ] **P3.T1.1: Robot jump / land** — jump SFX on takeoff (land squash silent or soft thud only if already exists)
  - [ ] **P3.T1.2: Trampoline bounce** — bounce SFX on auto-impulse, mash-safe
- [ ] **P3.T2: Wire collect + goal loop** — covers: FR-5
  - [ ] **P3.T2.1: Gem / key / door** — gem pop, key chime, door rising chime on unlock
  - [ ] **P3.T2.2: Hint-safe** — sounds never block hint sparkles or pointing
- [ ] **P3.T3: Wire gift machine + finale + ambient** — covers: FR-5, FR-4
  - [ ] **P3.T3.1: Gift dispense / wiggle / bonus** — gift_pop, gift_wiggle, gift_bonus paths
  - [ ] **P3.T3.2: Finale + area ambient switch** — celebrate flourish + crossfade on transition / loop-home
- [ ] **P3.T4: Live verification** — covers: AC-5, AC-6, AC-7
  - [ ] **P3.T4.1: Wiring tests** — signal-spy tests proving each moment calls `play()` / swaps ambient

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

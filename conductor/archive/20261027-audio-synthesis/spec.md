# Audio Synthesis — Specification

> Requirements are stable. Once an `FR`, `NFR`, or `AC` ID is approved, do not
> renumber it. If a requirement is removed, mark it `Withdrawn` instead of
> deleting it.

## Overview

This track ends the silence: it implements `AudioFactory` synthesis behind the
existing `play()` / `get_ambient()` interface and wires every gameplay moment
so Robo's Treasure Hunt sounds soft, joyful, and toddler-safe — nine
synthesized SFX plus three gentle per-area ambient loops, all generated in code
with no external audio files.

## Problem / Motivation

Today `src/factory/audio_factory.gd` (17 lines) is a stub — `play()` is a
no-op and `get_ambient()` returns null — and no gameplay code calls it, so the
game ships silent. That violates the product vision (roadmap step 6: Audio),
the tech-stack promise (pre-generated `AudioStreamWAV` SFX + per-area ambient
loops), and the product guidelines (constant juicy feedback; soft SFX + gentle
music). A 4-year-old who cannot read depends on sound for cause-and-effect
(jump → whoosh, gem → pop, door → chime). If unsolved, the game feels dead,
rewards feel flat, and v1 cannot pass its playtest bar.

## Goals & Success Metrics

- **Goal:** Every key moment has an immediate, soft, recognizable sound and each
  area has its own gentle ambient loop.
- **Metric:** All 9 SFX + 3 ambient loops generate as loop-enabled `AudioStreamWAV`
  at startup; live smoke run in the editor triggers the correct sound at each
  moment with no crash on headless / no-audio hardware.
- **Goal:** Toddler-safe mix that never startles and never clips under mashing.
- **Metric:** Conservative volumes + soft envelopes pinned by tests; rapid
  repeats stay polyphonic with a voice cap and no clipping; area switches
  crossfade with no abrupt cuts.
- **Goal:** Keep the build fast and clean.
- **Metric:** `gd-tools test --coverage --min 80` passes; art + audio startup
  stays sub-second; lint + format clean.

## Scope

### In Scope

- Synthesize 9 SFX as pre-generated `AudioStreamWAV`: jump, bounce, gem
  (collect pop), key, door (rising chime), celebrate (flourish), gift_pop,
  gift_wiggle, gift_bonus — soft rounded tones per guidelines.
- Synthesize 3 per-area ambient loops (meadow / cave / sunset), loop-enabled,
  tone-layered, slow tempo, conservative volume.
- Keep the `AudioFactory` interface (`play(sfx_name)`, `get_ambient(area_name)`)
  and implement polyphonic one-shot playback with a voice cap; unknown names
  are safely ignored.
- Ambient crossfade on area switch + slight ducking under SFX.
- Wire all gameplay call sites: robot jump (and land squash where it exists),
  trampoline bounce, gem collect, key collect, door unlock, gift-machine
  use / wiggle / bonus, finale celebration, area-transition ambient switch.
- Tuning constants for all audio (rates, durations, volumes, crossfade, cap) in
  the single tuning file; TDD suites + deterministic snapshots for buffers.

### Out of Scope

- Mute / volume / settings UI (v1 has no settings menu by design).
- External audio files, fonts, or art changes.
- Voice-over, narration, or text-to-speech.
- Save-format changes (no new persisted fields).
- Parent gate / hold-to-quit (v1.1), new puzzles, 4th area (v2).

## Functional Requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | SFX set is synthesized at startup as `AudioStreamWAV` buffers with logical names `jump`, `bounce`, `gem`, `key`, `door`, `celebrate`, `gift_pop`, `gift_wiggle`, `gift_bonus`; no external files. | must |
| FR-2 | One ambient loop per area (`meadow`, `cave`, `sunset`) is synthesized at startup as loop-enabled `AudioStreamWAV`, tone-layered, slow tempo. | must |
| FR-3 | `play(sfx_name)` plays the named one-shot polyphonically with a voice cap; unknown / empty names are ignored without error or crash. | must |
| FR-4 | `get_ambient(area_name)` returns the correct area loop; switching areas crossfades gently (no abrupt cut) and ambient ducks slightly while a one-shot plays. | must |
| FR-5 | Gameplay wires sounds: robot jump, trampoline bounce, gem collect, key collect, door unlock, gift-machine dispense / wiggle / bonus, finale celebration, and ambient switch on area transition. | must |
| FR-6 | All streams are pre-generated once at startup, cached in memory, and served through the existing `AudioFactory` autoload interface (no API break). | must |

## Non-Functional Requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Toddler-safe mix: soft rounded envelopes, conservative volumes, no harsh / loud / startling transients, no sudden ambient transitions. |
| NFR-2 | Performance: art + audio pre-generation stays sub-second; gameplay holds 60 FPS on a mid-range tablet; no per-frame allocations in the audio path. |
| NFR-3 | Reliability: headless import and machines with no audio hardware never crash; missing streams fall back to silence, never an error screen. |
| NFR-4 | Maintainability: every tuning value (sample rate, durations, pitches, volumes, crossfade, duck amount, voice cap) lives in tuning constants; typed GDScript; lint + format clean. |
| NFR-5 | Testability: new logic meets the 80 coverage gate; buffers pinned by deterministic snapshots; each AC has a test or live evidence artifact. |

## Acceptance Criteria

| ID | Criterion | Verifies |
| --- | --- | --- |
| AC-1 | `gd-tools test` shows all 9 SFX buffers exist, non-silent, correct sample format, and snapshots match. | FR-1 |
| AC-2 | `gd-tools test` shows 3 ambient loops exist, loop-enabled, one per area, mutually distinct yet gentle (no harsh spectrum). | FR-2 |
| AC-3 | Calling `play()` with each valid name emits a one-shot; rapid mash (e.g. 10 gem plays in one frame) stays polyphonic with cap and no error; `play(\"nope\")` / `play(\"\")` is a safe no-op. | FR-3 |
| AC-4 | `get_ambient(\"meadow\"/\"cave\"/\"sunset\")` returns the matching loop; unknown area falls back safely; switching areas crossfades (no hard cut) in a live run. | FR-4 |
| AC-5 | Live editor smoke run: jumping, bouncing, collecting a gem, collecting a key, unlocking a door, using the gift machine (dispense + wiggle + bonus paths), and the finale each produce the expected sound; area change swaps ambient. | FR-5 |
| AC-6 | Cold start pre-generates once and caches (second `get_ambient`/`play` does no regen); startup with art stays sub-second on desktop; headless import (`godot --headless --import --path .`) exits 0 with no audio crash. | FR-6 |
| AC-7 | `gd-tools lint`, `gd-tools format --check`, and `gd-tools test --coverage --min 80` all pass; editor session is `ready`; touched scenes open with sane hierarchy + screenshot + `project_run` returns to `stopped`. | NFR-4, NFR-5 |

## Edge Cases

- Headless / CI / no-audio-hardware: import and suite run silently, no crash, no error text.
- Unknown `sfx_name` / unknown `area_name`: safe fallback (silence or meadow loop), logged only in verbose, never a crash.
- Mash case: 4-year-old holds jump + walks through gems + taps machine — voice pool caps, oldest voice steals, no clipping / no dropped ambient.
- Area switch mid-crossfade (child unlocks twice fast / finale loops home): second crossfade supersedes cleanly, no stacked players leaking.
- Rapid scene reload / repeated `get_ambient`: cached streams reused, no per-call allocation, no player leak.
- Very short SFX on slow hardware: buffer lengths stay fixed; playback timing never blocks physics.

## Dependencies

- **Tracks:** none (Foundation, Movement & Camera, Collect & Play, Goal Loop, and `20261027-gem-shop` are merged; this is roadmap step 6 and touches no unmerged branch).
- **External:** none (no services, credentials, packages beyond `gd-tools` + Godot 4.7 editor + godot-ai MCP for live checks).

## Open Questions & Assumptions

- **Assumption:** 22050 Hz 8-bit mono `AudioStreamWAV` is sufficient for soft toddler SFX + ambient; if snapshots reveal harshness, raise to 44100 Hz in tuning without API change.
- **Assumption:** Voice cap 8 one-shots + 1 ambient player; crossfade ~0.8s; ambient duck −6 dB under SFX — all single-line tuning edits after playtest.
- **Assumption:** `AudioFactory` remains the autoload playback surface; if the pool needs scene-tree players, a small `AudioManager` helper under `src/systems/` may be added inside this track's `Touches` without a stack change.
- **Question:** Exact per-area musical characters (meadow bright / cave hollow / sunset warm) to be ear-checked in the live smoke run and tuned post-playtest.

## References

- `conductor/product.md` — Audio + Roadmap step 6
- `conductor/tech-stack.md` — Audio (`AudioStreamWAV` buffers, per-area loops)
- `conductor/product-guidelines.md` — Audio Style + Toddler safety
- `conductor/workflow.md` — Verification Strategy + live editor checks
- `src/factory/audio_factory.gd` — current stub interface to preserve
- `src/tuning/tuning.gd` — single tuning source for new audio constants

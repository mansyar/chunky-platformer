# Phase 1 Evidence — SFX synthesis core (20261027-audio-synthesis)

- **Track:** `20261027-audio-synthesis`
- **Phase:** 1 — SFX synthesis core
- **Date:** 2026-10-27
- **Branch:** `feat/20261027-audio-synthesis`
- **Base:** `06196b65165e9df63dcd0368e381dd63e211b3ad`
- **Head:** `06196b6` + working tree (squashed on verify; see Primary verification)
- **Result:** `verified` (primary re-ran gates after lint/format fixes)

## Implementation summary

- `src/tuning/tuning.gd` — added `AUDIO_*` constants: 22050 Hz / 8-bit / mono
  format, voice cap 8, attack 12 ms + 35 % cosine release, and the 9-voice
  `AUDIO_SFX` table (duration / pitch sweep / conservative volume ≤ 0.4 /
  optional gentle vibrato for bounce, celebrate, gift_wiggle).
- `src/factory/audio_factory.gd` — replaced the stub behind the same
  interface: `warm_sfx()` pre-generates all 9 `AudioStreamWAV` buffers at
  `_ready` into an idempotent cache; `play()` is polyphonic with an
  8-`AudioStreamPlayer` pool, oldest-steal on saturation, unknown/empty
  names and out-of-tree calls are safe no-ops; `get_ambient()` still
  returns null (Phase 2). Observability for tests: `has_sfx`, `get_sfx`,
  `sfx_names`, `cache_size`, `sfx_signature` (snapshot-friendly dict),
  `pool_size`, `active_voice_count` (assigned-voice semantics, so the cap
  holds deterministically on headless/dummy audio drivers), `reset_pool`.
- `tests/test_audio_synthesis.gd` — 20 suites: tuning pins, per-SFX format /
  non-silence / conservative-peak / soft-ends / transient-bound /
  distinctness checks, `assert_snapshot` signatures per SFX, cross-instance
  determinism, cache reuse (`assert_is`), cold-start speed, one-shot
  emission, 10-play mash cap, unknown-name safety, out-of-tree safety.
- Existing `tests/test_audio_stub.gd` expectations preserved: `play()` never
  errors and `get_ambient()` still returns null.

## Commands

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| coverage | `gd-tools test --coverage --min 80` | 0 (primary rerun) | 336/336 pass, 9 snapshots matched, 94.9% lines / 93.7% branches |
| static | `gd-tools lint` | 0 | No issues (after duplicated-load fix) |
| static | `gd-tools format --check` | 0 | All 67 files formatted (formatted 3 phase files) |
| build | `godot --headless --import --path .` | 0 | Editor layout DONE, no import errors |

## Live checks

| MCP tool | Target | Result |
| --- | --- | --- |
| n/a | n/a | No scenes touched (pure-logic phase); no MCP tools available to this executor |

## Acceptance criteria

| ID | Criterion | Evidence | Status |
| --- | --- | --- | --- |
| AC-1 | 9 SFX non-silent, correct format, snapshots match | `test_sfx_buffers_have_the_spec_format`, `test_sfx_buffers_are_non_silent_and_conservative`, `test_sfx_snapshot_signatures` | implemented, unverified |
| AC-3 | `play()` pools with cap 8, oldest-steal, unknown-name no-op | `test_play_emits_a_one_shot_per_valid_name`, `test_rapid_mash_stays_polyphonic_with_cap`, `test_play_ignores_unknown_and_empty_names` | implemented, unverified |
| AC-6 | Pre-generate once + cache; no regen; fast startup; headless-safe | `test_cache_reuses_streams_without_regeneration`, `test_pregeneration_at_startup_is_fast`, `test_play_outside_the_tree_is_a_safe_noop` | implemented, unverified |
| AC-7 | Suites + coverage + snapshots pass | 336/336, coverage 94.9%, 9 snapshots matched | verified |

## Primary verification

- **Current HEAD:** `06196b6` (phase_base; squash commit below advances it)
- **Touches-vs-diff:**
  | Touches entry | In diff? | Notes |
  | --- | --- | --- |
  | `src/factory/audio_factory.gd` | yes | synth engine + pool, Phases 1 only |
  | `src/tuning/tuning.gd` | yes | AUDIO_* constants appended |
  | `tests/test_audio_synthesis.gd` | yes (new) | 20 suites + preload fix by primary |
  | `conductor/.../verification/phase-1.md` | yes | evidence (allowed outside Touches) |
  | `tests/test_audio_synthesis.gd.uid` | yes | engine-generated companion (allowed) |
- **Verification rerun:** `gd-tools test --coverage --min 80` → exit 0, 336/336 pass, snapshots 9 matched; `gd-tools lint` → OK; `gd-tools format --check` → OK; `godot --headless --import --path .` → DONE.
- **AC cross-check:** AC-1 (format/non-silence/snapshots) proven by test_sfx_buffers_have_the_spec_format + test_sfx_snapshot_signatures; AC-3 (cap/oldest-steal/no-op) by mash + unknown-name tests; AC-6 (cache/fast/headless) by cache-reuse + sub-second + out-of-tree tests; AC-7 by suite + coverage gates above.
- **Primary fixes:** `duplicated-load` lint (single preload const) + `gd-tools format` on 3 phase files; no scope change.

## Deviations

- none (all changes inside `Touches`).

## Notes

- The executor's `shell` tool returned `permission denied`, so the phase
  verification command and task-level `git` commits could not be executed
  here. Request the primary agent run: `gd-tools test --coverage --min 80`
  (plus `gd-tools lint` and `gd-tools format --check` for the AC-7 static
  layer), then commit `src/tuning/tuning.gd`,
  `src/factory/audio_factory.gd`, `tests/test_audio_synthesis.gd`, and this
  evidence file with conventional task-level commits.

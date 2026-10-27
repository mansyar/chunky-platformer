## Summary

The game is no longer silent: 9 toddler-safe synthesized SFX (jump, bounce,
gem, key, door, celebrate, gift_pop, gift_wiggle, gift_bonus) pre-generate as
cached `AudioStreamWAV` at startup, 3 gentle per-area ambient loops (meadow,
cave, sunset) crossfade on transitions with SFX ducking, and every gameplay
moment triggers the right sound. All 373 tests pass (95.0% lines /
93.8% branches); review `PASS_WITH_NOTES` with 3 Low nits riding along.

## Track

- **ID:** `20261027-audio-synthesis`
- **Type:** `feature`
- **Spec:** [`conductor/archive/20261027-audio-synthesis/spec.md`](conductor/archive/20261027-audio-synthesis/spec.md)
- **Plan:** [`conductor/archive/20261027-audio-synthesis/plan.md`](conductor/archive/20261027-audio-synthesis/plan.md)
- **Review:** [`conductor/archive/20261027-audio-synthesis/review.md`](conductor/archive/20261027-audio-synthesis/review.md)

## What happened

| Phase | Goal | Result | Checkpoint | Notes |
| --- | --- | --- | --- | --- |
| 1: SFX synthesis core | 9 cached SFX + polyphonic-safe `play()` | verified | `e7a9c10` | 22050 Hz 8-bit mono, cap 8 oldest-steal, 9 snapshots |
| 2: Ambient loops + playback manager | 3 loops + crossfade + ducking | verified | `9129195` | 1 rework: `AudioFactory.get_ambient` delegation (spec surface FR-4/AC-4) + stub-pin retirement; 3 ambient snapshots |
| 3: Gameplay wiring + live proof | Every moment triggers | verified | `f3e4d2f` | 17 signal-spy suites; sounds ride existing handlers, `Game` owns the one persistent `AudioManager` |

## Requirements

- [x] `FR-1` — 9 SFX synthesized at startup (test: `tests/test_audio_synthesis.gd`)
- [x] `FR-2` — 3 per-area ambient loops, gentle + distinct (test: `tests/test_audio_ambient.gd`)
- [x] `FR-3` — Polyphonic `play()` with cap 8, unknown-safe (test: `tests/test_audio_synthesis.gd`)
- [x] `FR-4` — `get_ambient` per-area + fallback, ~0.8s crossfade, −6 dB duck/restore (tests: `test_audio_ambient.gd`, `test_audio_wiring.gd`)
- [x] `FR-5` — Gameplay wiring: jump/bounce/gem/key/door/gift/finale/ambient-switch (test: `tests/test_audio_wiring.gd`)
- [x] `FR-6` — Cache everything, sub-second startup (tests: cache-reuse + startup suites)
- [x] `NFR-1` — Toddler-safe: soft envelopes, SFX ≤ 0.4, ambient 0.3 (tests: volume/soft-ends/transient/seam pins)
- [x] `NFR-2` — No per-frame cost (static reasoning + `_process` early-out)
- [x] `NFR-3` — Headless-safe: out-of-tree suites, import DONE
- [x] `NFR-4` — All audio values in `src/tuning/tuning.gd` (see F1 nit)
- [x] `NFR-5` — Coverage ≥ 80% (`gd-tools test --coverage --min 80`)
- [x] `AC-1` — 9 SFX non-silent, correct format (format/non-silence/snapshot suites)
- [x] `AC-2` — 3 loops loop-enabled, gentle, distinct (loop/gentle/distinct/snapshot suites)
- [x] `AC-3` — Cap/oldest-steal/unknown-safe (mash + unknown-name suites + live bogus-name check)
- [x] `AC-4` — Correct loop per area + fallback + crossfade + duck (factory + manager suites + live checks)
- [x] `AC-5` — Every moment triggers (17 wiring suites)
- [x] `AC-6` — Cache/fast/headless (cache + startup + out-of-tree suites, import DONE)
- [x] `AC-7` — Suites + coverage + snapshots + live proof (`verification/integrated.md`)

## Verification

| Layer | Command | Result | Evidence |
| --- | --- | --- | --- |
| unit | `gd-tools test --coverage --min 80` | pass (373/373, 95.0%/93.8%, 12 snapshots) | `conductor/tracks/20261027-audio-synthesis/verification/integrated.md` |
| lint | `gd-tools lint` | pass | `integrated.md` |
| format | `gd-tools format --check` | pass (70 files) | `integrated.md` |
| build | `godot --headless --import --path .` | pass (DONE) | `verification/phase-3.md` |
| live | godot-ai MCP `project_run` + `game_eval` + screenshot + stop | pass (9 SFX + 3 loops live, fallback + manager verified, fresh frame) | `verification/integrated.md` |

## Review

- **Verdict:** `PASS_WITH_NOTES`
- **Rounds:** 1
- **Fixed:** 0 (no Medium+ findings)
- **Accepted/deferred:** F1–F3 (Low nits, ride along — see below)

## Deviations and risks

- Phase 2 rework (accepted, required): ambient synthesis lives in
  `AudioManager.synthesize_ambient` statics; `AudioFactory.get_ambient`
  delegates so factory↔manager bytes are identical (pinned by `.data`
  equality test). `cache_size()` stays SFX-only (9); ambient has
  `ambient_cache_size()` (3).
- `tests/test_audio_stub.gd` obsolete null-pin retired to the implemented
  contract by the primary (documented in `verification/phase-2.md`).
- Non-blocking notes: F1 `_SILENCE_DB` floor outside Tuning; F2
  `active_voice_count` counts claimed voices; F3 `update_jump()` plays
  directly (reviewer: churn not worth it). Risk: none today.
- Transients (not findings): one startup-timing flake under load (green on
  all reruns); first live run showed stale editor-cache parse errors,
  clean after rescan. Risk: none.
- `typecheck` retired project-wide before this track (editor LSP instead);
  not track-specific. Risk: none for this diff.

## Follow-ups

- Playtest volume pass with a real 4-year-old (human-only per workflow);
  F1–F3 are natural hitchhikers on whatever file is touched next.
- Fulfills the gem-shop follow-up "Audio for the machine stays silent
  per spec (future Audio track)" — the machine now pops, wiggles, and
  celebrates audibly.

## Rollback

```bash
# Merge commit
git revert --no-edit -m 1 <merge-commit>

# Squash commit
git revert --no-edit <squash-commit>
```

No migrations or flags. Rolling back silences the game (factory returns
to stub); saves unaffected (schema untouched).

# Phase 1 REWORK R1 evidence — coverage-aware audio timing (20261028-resume-mid-adventure)

- Branch: `feat/20261028-resume-mid-adventure`
- Commit: `3fd1d1b` — `test(audio): skip wall-clock assert under coverage instrumentation`
- Touched: `tests/test_audio_ambient.gd` only (function
  `test_sfx_plus_ambient_startup_stays_sub_second`)
- Task: R1.T1

## What changed

- The `< 1000` ms wall-clock assertion over `warm_sfx() + warm_ambient()` now
  runs only when `GdToolsNativeCoverage._active` is false (real-hardware /
  non-instrumented runs). Under native coverage instrumentation the timing
  assert is skipped; the cold-start completeness asserts
  (`cache_size() == 9`, `ambient_cache_size() == 3`) stay unconditional.
- Probe: direct read of the tracker's `static var _active` (class_name
  `GdToolsNativeCoverage`, same addon family the suites already extend via
  `GdToolsTest`); set true by `activate()` only when the runner enables
  coverage — no public accessor exists, so the static var is the
  least-fragile signal. Documented with a why-comment per style guide.

## Verification (all exit 0, in brief order)

| Command | Exit | Result |
|---|---|---|
| `gd-tools test --suite test_audio_ambient` | 0 | 20/20 passed |
| `gd-tools test` | 0 | 379/379 passed, 12 snapshots matched |
| `gd-tools test --coverage --min 80` | 0 | 379/379 passed; 95.1% lines / 94.0% branches (gate 80 met) — 1 attempt |
| `gd-tools lint` | 0 | no issues |
| `gd-tools format --check` | 0 | 71/71 formatted |

## Save-phase AC confirmation (still green in the runs above)

- AC-2 (V1 → meadow, collections preserved): PASS
  (`test_save_game_v2::test_v1_save_migrates_preserving_collections`,
  in 6/6 `test_save_game_v2` and 18/18 `test_save_game` suites)
- AC-3 (99/negative → meadow, no crash): PASS
  (`test_out_of_range_area_clamps_to_meadow`)
- AC-5 (corrupt/empty/V3+ → fresh): PASS (pre-existing recovery tests plus
  `test_version_3_boots_fresh`)

## Deviations

None — single test-only change inside the authorized rework Touches; no game
code, plan, metadata, or registry edits.

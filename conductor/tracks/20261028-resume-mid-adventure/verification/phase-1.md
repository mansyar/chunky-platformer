# Phase 1 evidence — Save V2 + migration (20261028-resume-mid-adventure)

- Branch: `feat/20261028-resume-mid-adventure`
- Commits: `5ce9b5b` (P1.T1, feat), `78adc2d` (P1.T2, test)
- Touched: `src/systems/save_game.gd`, `tests/test_save_game.gd`
  (one-line pointer comment + `area_index` assertion), `tests/test_save_game_v2.gd` (new)

## What changed

- `SaveGame.VERSION` 1 → 2; `PREVIOUS_VERSION := 1` kept so V1 files migrate.
- `fresh_state()` gains `"area_index": 0`.
- `to_dict(..., area_index: int = 0)` persists the area (negatives packed as 0).
- `save_game(..., path, area_index: int = 0)` trailing param — existing callers unchanged.
- `sanitize` accepts versions 1 and 2 (anything else → fresh + warning, unchanged
  recovery for corrupt/missing/empty/future); V1 files migrate with collections
  intact and area defaulting to 0; `area_index` missing/non-numeric/negative or
  `>= AreaLayout.all().size()` reads as the meadow. The count comes from the area
  list itself so adding an area never strands a valid save (no cycle: AreaLayout
  never references SaveGame; sanitize runs only at load, never per-frame).
- New `tests/test_save_game_v2.gd`: 6 tests (persist default/explicit/negative,
  save→load round-trip at index 2, clamp 99/-1/3/non-numeric → 0, V1 migration
  preserving wallet/owned/worn/taken, V3 → fresh). Split from `test_save_game.gd`
  because that suite sits at the lint cap of 20 public methods per file
  (precedent: 20261027-audio-synthesis merged suites for the same rule).

## Verification

| Command | Exit | Result |
|---|---|---|
| `gd-tools test` | 0 | 379/379 passed, snapshots 12 matched |
| `gd-tools test --suite test_save_game` | 0 | 18/18 passed |
| `gd-tools test --suite test_save_game_v2` | 0 | 6/6 passed |
| `gd-tools lint` | 0 | no issues |
| `gd-tools format --check` | 0 | 71/71 formatted |
| `gd-tools test --coverage --min 80` | 1 | BLOCKED: coverage addon outdated (v0.9.0 deployed, v0.10.0 installed); needs `gd-tools init`, which touches files outside this phase's scope — left for the primary |

TDD red evidence: the 6 new tests were run before the implementation and the suite
failed to load (new `area_index` call args against the old signatures), exit 1; after
implementation all green. No new untyped globals; typed GDScript throughout.

## AC check

- AC-2 (V1 → meadow, collections preserved): PASS — `test_v1_save_migrates_preserving_collections`.
- AC-3 (99/negative → meadow, no crash): PASS — `test_out_of_range_area_clamps_to_meadow`.
- AC-5 (corrupt/empty/V3+ → fresh): PASS — pre-existing corrupt/missing/empty/future
  tests plus new `test_version_3_boots_fresh`.

## Follow-ups for the primary

- Coverage gate needs `gd-tools init` (out of this phase's scope) then a re-run of
  `gd-tools test --coverage --min 80`.
- `tests/test_save_game_v2.gd` has no `.uid` companion (engine ran it fine without one);
  mint one only if project convention requires it.

## Primary verification (2026-10-27, primary agent)

- **Touches conformance:** `git diff fddf9df..HEAD --name-only` shows exactly
  `src/systems/save_game.gd`, `tests/test_save_game.gd`, `tests/test_save_game_v2.gd`
  — all inside the phase Touches globs. Plus untracked: `verification/` (evidence)
  and `tests/test_save_game_v2.gd.uid` (engine-minted; matches convention — every
  test `.gd` in `tests/` has a `.uid` companion; committed with this state).
- **Independent reruns (all exit 0):** `gd-tools test --suite test_save_game` 18/18,
  `gd-tools test --suite test_save_game_v2` 6/6, `gd-tools test --suite
  test_audio_ambient` 20/20, full `gd-tools test` 379/379, `gd-tools lint` clean,
  `gd-tools format --check` 71/71 clean.
- **Infra fix (primary, out of phase scope):** ran `gd-tools init`, which bumped only
  `addons/gd-tools-{coverage,editor,test}/_version.txt` 0.9.0 → 0.10.0 (committed
  separately as `chore(tools)`). This unblocked the coverage runner.
- **Coverage runs:** 95.1% lines / 94.0% branches — gate `--min 80` met on the
  percentage — but exit code 1 every time on exactly one test:
  `test_audio_ambient::test_sfx_plus_ambient_startup_stays_sub_second`
  (wall-clock `< 1000` ms assert over `warm_sfx() + warm_ambient()`; 9 SFX + 3 loops
  of tight sample loops that instrumentation slows past budget). It passes standalone
  (20/20) and in every non-coverage full run, and no code in this track touches audio.
  Artifacts scan across all recent coverage runs confirms it is the ONLY failing test.
  (An early grep hit on `test_save_reports_write_failure` was the test's own expected
  `cannot write` WARNING backtrace, not a failure — that test passes everywhere.)
- **Pre-existing, not a regression:** the coverage gate never ran before on any track
  (addon was outdated repo-wide), so this timing-vs-instrumentation interaction
  predates the phase. Fixing it means touching `tests/test_audio_ambient.gd`, which is
  outside this phase's Touches and contract.
- **Verdict:** code complete, all phase AC tests green (AC-2/3/5 PASS), coverage
  percentage met, lint/format clean — but the phase Verification command still exits 1
  on the out-of-scope timing test, so per hard rules the phase is marked **blocked**,
  not verified. Unblock options: (1) grant a minimal test-only allowance for the audio
  timing assertion under coverage, (2) repo-wide decision to exempt timing tests from
  instrumented runs, (3) leave blocked.
- **Deviations recorded:** (a) plan Covers amended with NFR-1..NFR-4 for contract
  conformance (primary repair, no scope change); (b) new `tests/test_save_game_v2.gd`
  suite split (lint cap 20 methods/suite, matches project precedent); (c) `gd-tools
  init` addon bump (primary infra, separate commit).

# Phase R1 verification — Review Fixes (F1 + F2)

- Date: 2026-10-28
- Branch: feat/20261028-resume-mid-adventure (base 55681a7)
- Commits: 40dc178 docs(tech-stack), 793b530 test(transition)

## Changes

- R1.T1 (F1): conductor/tech-stack.md save sketch now documents the V2 schema
  `{version: 2, wallet, owned, worn, taken, area_index}`; added one migration
  line (V1 loads and migrates forward preserving collections with area 0;
  unknown/future versions boot fresh). No keys/doors/position promise
  reintroduced, so no AC-6 contradiction.
- R1.T2 (F2): tests/test_game_transition.gd `test_resumed_area_starts_with_fresh_keys`
  now asserts `SaveGame.load_game()["taken"]["cave"] == flags` (persist to disk)
  and loops all cave gems via a new `_is_collected` helper asserting taken state
  is applied to the rebuilt builder (fixtures only, no scene-tree change).

## Verification

- `gd-tools test --coverage --min 80` -> exit 0, 383/383 pass, 12 snapshots matched, 95.1% lines / 94.0% branches (gate 80)
- `gd-tools lint` -> exit 0, no issues (71 files)
- `gd-tools format --check` -> exit 0, all 71 files formatted (one `gd-tools format` write pass applied to the touched test file only; `git status` confirms only the two Touches files modified)
- No manual exceptions.

## Primary verification

- Touches diff vs `55681a7`: exactly `conductor/tech-stack.md` (+8/-3 doc lines),
  `tests/test_game_transition.gd` (+17 test/assert lines), and the permitted new
  evidence file. ACCEPT — in scope, no src/product/spec changes.
- Independent rerun: `gd-tools test --coverage --min 80` exit 0 (383/383 pass,
  12 snapshots matched, 95.1% lines / 94.0% branches); `gd-tools lint` exit 0;
  `gd-tools format --check` exit 0 (71 files).
- F1: tech-stack sketch now V2 with migration line; no keys/doors/position
  promise reintroduced — matches the approved AC-6 wording. FIXED.
- F2: cave-reboot test asserts `taken["cave"]` survives to disk AND is applied
  per-gem in the rebuilt builder via `_is_collected`. FIXED.
- Verdict: Phase R1 VERIFIED. Round-2 re-review gate satisfied (both Lows fixed).

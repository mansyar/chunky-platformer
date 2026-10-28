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

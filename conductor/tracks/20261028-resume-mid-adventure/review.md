# Review: Resume-mid-adventure fix

- **Track:** `20261028-resume-mid-adventure`
- **Type:** `feature`
- **Branch:** `feat/20261028-resume-mid-adventure`
- **Range:** `b4536b2..ee07353`
- **Date:** `2026-10-28`
- **Verdict:** `BLOCK`

## Summary

All three phases verified with a green full gate (383/383, 95.1%/94.0% vs 80),
clean lint/format, successful headless import, and live editor proof. The
read-only review found no Critical or High issues: migration is non-destructive,
new params are trailing with defaults, no per-frame cost was added, and keys
stay fresh by construction. Two Low findings remain (stale tech-stack schema
sketch; one unasserted taken-applied combination in the cave-reboot test). The
workflow runs in strict mode, so both must be fixed before the PR — hence BLOCK
for round 1, with a minimal two-task fix phase appended.

## Verification

| Layer | Command | Result | Evidence |
| --- | --- | --- | --- |
| test | `gd-tools test --coverage --min 80` | pass (383/383, 12 snapshots) | verification/phase-3.md + primary rerun |
| coverage | `gd-tools test --coverage --min 80` | pass (95.1% lines / 94.0% branches, gate 80) | verification/phase-3.md + primary rerun |
| lint | `gd-tools lint` | pass (no issues) | primary rerun |
| typecheck | N/A (workflow: editor LSP, no CLI gate — do not re-add) | N/A | workflow.md:40-43 |
| build | `godot --headless --import --path .` | pass (exit 0) | primary run 2026-10-28 |
| live/smoke | godot-ai MCP session/hierarchy/screenshot/run-stop | pass (screenshot binaries unpersistable — toolset limitation, frames in transcript) | verification/phase-2.md, phase-3.md |

## Requirements

| ID | Implemented by | Verified by | Status |
| --- | --- | --- | --- |
| FR-1 | P1.T1 | `tests/test_save_game_v2.gd` round-trip | covered |
| FR-2 | P2.T1 | `tests/test_game_transition.gd::test_boot_restores_saved_cave_at_spawn_with_collections` + live reboot | covered |
| FR-3 | P1.T2 | `tests/test_save_game_v2.gd` migration | covered |
| FR-4 | P1.T1 | `tests/test_save_game_v2.gd` clamp (99/-1→0) | covered |
| FR-5 | P2.T2 | `test_door_transition_persists_the_new_area_index` | covered |
| FR-6 | P2.T2 | `test_finale_saves_meadow_and_reboot_starts_meadow` | covered |
| FR-7 | P2 (no key persistence) + P3.T1 | code inspection + product.md wording | covered |
| NFR-1 | design (boot-time only, `_process` untouched) | suite green, no per-frame code | covered |
| NFR-2 | TDD + gates | 95.1%/94.0%, typed, lint/format clean | covered |
| NFR-3 | P1.T2 | corrupt/empty/future recovery tests | covered |
| NFR-4 | no menus/prompts + wording | code inspection + product.md | covered |
| AC-1 | P2.T1 | boot-cave test + live proof | covered (F2 hardens one combination) |
| AC-2 | P1.T2 | migration tests | covered |
| AC-3 | P1.T1 | clamp tests | covered |
| AC-4 | P2.T2 | finale test | covered |
| AC-5 | P1.T2 | recovery tests | covered |
| AC-6 | P3.T1 | product.md before/after in phase-3.md, user-approved | covered |
| AC-7 | P2.T2 + P3.T2 | live tables in phase-2.md/phase-3.md | covered |

## Findings

### Critical

- none

### High

- none

### Medium

- none

### Low

- **F1 — stale tech-stack schema sketch**
  - **File:** `conductor/tech-stack.md:70-71`
  - **What:** Data & Persistence still documents the V1 schema
    `{"version": 1, "wallet", "owned", "worn", "taken"}` while `SaveGame.VERSION`
    is now 2 with `area_index` and V1→V2 migration.
  - **Why:** Stale stack doc misleads the next track touching the save format.
  - **Fix:** Sketch `{"version": 2, "wallet", "owned", "worn", "taken",
    "area_index"}` plus one line: V1 files load and migrate forward (area
    defaults 0); unknown/future versions boot fresh.
  - **Requirement:** FR-1/FR-3 traceability.
  - **Test gap:** none (docs-only).
- **F2 — unasserted taken-applied combination in cave-reboot test**
  - **File:** `tests/test_game_transition.gd:134`
    (`test_resumed_area_starts_with_fresh_keys`)
  - **What:** Test writes cave taken-flags (2 gems) but asserts only
    area/spawn/keys-fresh — never that taken flags survived and applied.
  - **Why:** AC-1 wants gem-taken intact in the resumed area; the cave-reboot
    link relies on the shared generic path without a direct assertion.
  - **Fix:** Add `assert_eq(SaveGame.load_game()["taken"]["cave"], flags)` and
    one pre-collect assertion on the rebooted builder (mirror the meadow
    relaunch test's `_is_collected` loop). Two to three lines.
  - **Requirement:** AC-1.
  - **Test gap:** this is the gap; behavior correct by inspection.

## Overrides

- none

## Plan compliance

- Phases 1–3 each have Goal/Depends/Covers/Touches/Verification/Status,
  Result, Checkpoint, Evidence. All 6 tasks + R1 rework task checked and
  implemented; nothing dropped.
- Final diff stays within the union of phase Touches, plus reported deviations
  only: `test_playthrough.gd` one-liner (D1, test-only clean-slate convention),
  `test_audio_ambient.gd` coverage-aware assert (user-authorized R1, test-only),
  addon `_version.txt` bumps (coverage-gate infra).
- No review-fix phase present yet — appended as Phase R1 below.

## Out of scope

- Screenshot binaries under `.conductor/evidence/` (phase toolsets have no
  binary-write tool; frames recorded in transcripts). Not a product gap.
- 60 FPS on physical tablet, 4yo playtest, Win/Android export — workflow-listed
  manual exceptions, unchanged by this track.

## Debt

- none (strict mode: no deferrals; F1/F2 go to Phase R1).

## Doc sync

`updated` — product.md Progression/Persistence wording (P3.T1, user-approved);
tech-stack.md schema sketch pending via F1 (Phase R1).

## History

| Round | Verdict | Critical | High | Medium | Low | Fixed |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | BLOCK | 0 | 0 | 0 | 2 | 0 |
| 2 | PASS | 0 | 0 | 0 | 0 | 2 |

## Round 2 (re-review after Phase R1)

- **Verdict: PASS** — F1 fixed (`conductor/tech-stack.md:70-75` V2 sketch with
  migration line, no AC-6 contradiction); F2 fixed
  (`tests/test_game_transition.gd:159-165` persist-to-disk + per-gem applied
  assertions via `_is_collected`). No new findings at any severity.
- Full Requirements table re-verified: FR-1..7, NFR-1..4, AC-1..7 all met.
- Checks: coverage gate 383/383 95.1%/94.0% (phase + primary rerun), lint and
  format clean (reviewer own rerun), build exit 0, live/smoke per phase evidence.

## Doc sync

`done` — product.md Progression/Persistence wording (P3.T1, user-approved);
tech-stack.md V2 schema sketch (R1.T1). No pending sync.

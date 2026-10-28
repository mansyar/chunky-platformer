# Phase 3 Evidence — Tuning, follow-ups & final verification

- Track: `20261028-4yo-playtest-tuning` — 4yo Playtest + Tuning Loop
- Phase: 3 (Tuning, follow-ups & final verification)
- Date: 2026-10-28
- Branch: `chore/20261028-4yo-playtest-tuning`
- Base: `e8ac7cd2ad2439b1f7397495659af7309bad9cd8`
- Head: `e8ac7cd2ad2439b1f7397495659af7309bad9cd8` + this file (docs-only; zero code changes)
- Result: **verified**

## Tuning decision (P3.T1 — explicit record)

Reviewed findings F1–F5 in `session/notes.md` against `src/tuning/tuning.gd`.
The session is a clean PASS: controls obvious within seconds (F1), goals
grasped (F2), full engagement with zero stuck (F3), hint system unneeded (F4).
No tuning value is indicted by any finding:

- Movement/jump (`WALK_SPEED`, `JUMP_IMPULSE`, `GRAVITY`, `STEP_UP_*`,
  `COYOTE_TIME`, `JUMP_BUFFER`) — validated by F1/F3; no stalls occurred.
- Collection (`GEM_PICKUP_RADIUS`, `KEY_PICKUP_RADIUS`) — validated by F2;
  deliberate collection with key→door connection.
- Hint (`HINT_DELAY`, `HINT_SHOW_TIME`) — never needed to fire (F4); changing
  an untested-but-unneeded safety net on no evidence would be scope growth.

**Decision: no tuning or code changes.** "No changes needed" is the honest
result per the brief (P3.T1.1). No regression test added — there is no changed
behavior to pin. Anything bigger than a tuning value would have gone to P3.T2;
nothing qualified.

## Commands

| Layer | Command | Exit | Summary |
| --- | --- | --- | --- |
| unit/integration/coverage | `gd-tools test --coverage --min 80` | 0 | 404/404 passed, 97.93s; 94.7% lines / 94.0% branches (gate 80); 12/12 snapshots matched |
| static | `gd-tools lint` | 0 | No lint issues found |
| static | `gd-tools format --check` | 0 | All 73 file(s) formatted |

Note: the known wall-clock flake
(`test_audio_synthesis.test_pregeneration_at_startup_is_fast` tripping under
loaded-suite timing, see phase-1 evidence) did **not** occur — the full suite
passed 404/404 on the first run, so no isolated retry or settle-wait was
needed. No audio code or tests were touched.

## Acceptance criteria

| ID | Criterion | Evidence | Status |
| --- | --- | --- | --- |
| AC-3 | Every finding is either fixed in-track or has a filed follow-up; no finding left unaddressed | Findings-disposition table below; F1–F4 closed in-track (no action indicated), F5 proposed follow-up in `session/notes.md` §6 | met |
| AC-4 | `gd-tools test --coverage --min 80`, `gd-tools lint`, `gd-tools format --check` all green on the final tree | Commands table above (all exit 0) | met |
| AC-5 | Track closes honestly: either the unaided bar was met, or findings + follow-ups say what it will take | `session/notes.md` §5: all three v1 criteria met (unaided completion, zero stuck, no-instruction touch); §6 records the optional repeat-session follow-up | met |

FR-3 is satisfied by the explicit no-change decision above (findings required
no tuning/tiny fixes); FR-4 by the F5 follow-up entry; FR-5 by the green gate.
NFR-4 held: zero gameplay/code changes.

## Findings disposition

| # | Finding | Severity | Disposition |
| --- | --- | --- | --- |
| F1 | Controls immediately obvious: move + jump within seconds, no instruction. | info | in-track (closed — no action) |
| F2 | Goals grasped: deliberate collection, keys connected to the door. | info | in-track (closed — no action) |
| F3 | Full 15-minute engagement with headline "fun", zero stuck. | info | in-track (closed — no action) |
| F4 | Hint system never triggered (no stalls) — anti-frustration path untested but unneeded. | info | in-track (closed — no action) |
| F5 | Optional: repeat session for Areas 2–3 / a second child to confirm generality. | info | proposed follow-up in `session/notes.md` §6 (not required to close this track; no new track created — user decides at close-out) |

Disposition table confirmed complete: F1–F4 closed in-track, F5 proposed
follow-up. No finding is unaddressed.

## Evidence paths

- `conductor/tracks/20261028-4yo-playtest-tuning/session/notes.md`
- `conductor/tracks/20261028-4yo-playtest-tuning/verification/phase-1.md`
- `conductor/tracks/20261028-4yo-playtest-tuning/verification/phase-2.md`
- This file.

## Deviations

None. No files outside `Touches` were touched; no product/design decision was
required. (Untracked Godot `.import` sidecars under
`conductor/archive/.../screenshots/` are pre-existing editor cache noise, same
as Phase 1 — left alone.)

## Notes

- Phase is docs-only: zero tuning, gameplay, art, audio, or test changes.
- Phase base and code tree are identical (`e8ac7cd`); only this evidence file
  is added.

## Primary verification

Independent check by the primary on the same tree:

- `git status --porcelain`: clean except the three known regenerable Godot
  `.import` sidecars under `conductor/archive/.../screenshots/` (live-editor
  cache; repo tracks zero `.import` files; left alone per evidence).
- `git diff --name-only e8ac7cd..HEAD`: exactly this file, inside `Touches`.
  Commit range holds exactly the 1 reported commit (`f195130`) — no
  squash-guard violation (no merge, user, or unreported commits).
- Full gate re-run by the primary on the final tree:
  - First attempt timed out at 300 s with no output (infra hang — orphaned
    workers/lock contention after the subagent's run; not a test failure).
  - Retry: `gd-tools test --coverage --min 80` → exit 0, **404/404**,
    94.7% lines / 94.0% branches (gate 80), 12/12 snapshots matched, 87.71 s.
    The known audio wall-clock flake did not trip.
  - `gd-tools lint` → exit 0. `gd-tools format --check` → exit 0, 73/73.
- FR-3 (explicit no-change decision, evidence-backed) / FR-4 (F5 proposed
  follow-up recorded) / FR-5 (green gate) / AC-3 / AC-4 / AC-5 / NFR-4 all met
  per the tables above.
- Result: **verified**. Primary checkpoint follows the squash.

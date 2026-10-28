# 4yo Playtest + Tuning Loop — Specification

> Requirements are stable. Once an `FR`, `NFR`, or `AC` ID is approved, do not
> renumber it. If a requirement is removed, mark it `Withdrawn` instead of
> deleting it.

## Overview

Run a silent-observation playtest of Area 1 (Meadow) with a real 4-year-old on
a touch tablet, assess the v1 success criteria (completable unaided, zero
stuck, no-instruction touch), record structured session notes, and apply
tuning-value plus tiny-safe fixes for what the session reveals. Anything bigger
becomes a filed follow-up track.

## Problem / Motivation

Roadmap step 8 — playtesting with a real 4-year-old — is the project's biggest
open gap. Every shipped track (movement, camera, collect loop, goal loop, shop,
audio, resume, area personality) was validated by automated tests and adult eyes
only. The product's core claims — *area 1 completable unaided, zero stuck,
no-instruction touch* — are currently assertions, not evidence. If unsolved,
tuning decisions stay guesswork and v1 cannot honestly be called done.

## Goals & Success Metrics

- **Goal:** Produce first real-child evidence for (or against) the v1 success
  criteria, and tune what the evidence indicts.
- **Metric:** Session notes file exists with per-finding verdicts; every finding
  is either fixed in-track (tuning/tiny) or filed as a follow-up; suite stays
  green (404/404 baseline, coverage ≥ 80%).

## Scope

### In Scope

- One silent-observation session (15-min cap) on a touch tablet running from the
  Godot editor, Area 1 only
- Structured session-notes artifact committed to the track
- Tuning-value changes (`src/tuning/tuning.gd`) and tiny safe fixes directly
  caused by findings
- Full verification suite green after any change; follow-up tracks filed for
  bigger issues

### Out of Scope

- Areas 2–3 completion bar, parent gate / hold-to-quit, celebration polish,
  tablet export work, audio changes, new cosmetics, v2 puzzles
- Code changes beyond tuning values + tiny safe fixes (larger rework →
  follow-up track)
- Video, photos, or names of the child in the repo (privacy)

## Functional Requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | Run a silent-observation session: 4-year-old, touch tablet via editor run, Area 1, no instructions, 15-min cap | must |
| FR-2 | Record structured session notes (setup, timeline, stalls/rescues, engagement, verdict per success criterion) as a committed artifact | must |
| FR-3 | Apply tuning-value / tiny-safe fixes for session findings inside this track | should |
| FR-4 | File a follow-up track entry for every finding not fixed in-track | must |
| FR-5 | Keep the full verification suite green (tests, coverage gate, lint, format) after any change | must |

## Non-Functional Requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Child comfort is absolute: stop immediately if upset; partial notes still count as evidence |
| NFR-2 | No personal data in the repo: no video, photos, or names — notes describe behavior, not identity |
| NFR-3 | Session is repeatable from the notes: setup, build/run method, and tasks recorded precisely enough to re-run |
| NFR-4 | No gameplay-scope growth: tuning numbers and trivial fixes only, no new mechanics, art, or systems |

## Acceptance Criteria

| ID | Criterion | Verifies |
| --- | --- | --- |
| AC-1 | Session run per FR-1 conditions (touch tablet, silent, Area 1, ≤15 min) and attested in notes | FR-1 |
| AC-2 | Session-notes artifact committed covering setup, timeline, stalls/rescues, engagement, per-criterion verdicts | FR-2 |
| AC-3 | Every finding is either fixed in-track or has a filed follow-up; no finding left unaddressed | FR-3, FR-4 |
| AC-4 | `gd-tools test --coverage --min 80`, `gd-tools lint`, `gd-tools format --check` all green on the final tree | FR-5 |
| AC-5 | Track closes honestly: either the unaided bar was met, or findings + follow-ups say what it will take | FR-2, FR-4 |

## Edge Cases

- Child gets upset → stop immediately; partial notes are valid evidence (NFR-1)
- Child completes Area 1 with zero findings → still success; notes attest the bar was met
- Child hard-stucks → log the event, gently unstick, continue; the stuck event is itself a finding
- Touchscreen/editor-run fails on the day → falling back to desktop touch-emulation is *not* accepted silently; record as deviation, reschedule tablet run
- Findings contradict each other or implicate a big rework → file follow-up, do not expand scope

## Dependencies

- **Tracks:** none (standalone on merged `master`; tablet-export track explicitly not required — editor run suffices)
- **External:** access to a touchscreen device capable of running the Godot editor session; a willing 4-year-old and 15 minutes

## Open Questions & Assumptions

- **Assumption:** One session suffices unless it produces inconclusive evidence, in which case a second session may be run in-track rather than filed as follow-up
- **Assumption:** Tester is the user's own 4-year-old; no consent paperwork needed beyond parental judgment
- **Assumption:** Priority high; type chore (validation + tuning, not a shippable feature)

## References

- `conductor/product.md` — v1 success criteria (area 1 completable unaided, zero stuck, no-instruction touch)
- `conductor/product-guidelines.md` — toddler harshest reviewer; constant feedback; short-cycle joy
- `conductor/tech-stack.md` — tuning centralized in `src/tuning/tuning.gd`; touch via `TouchControls`
- `conductor/archive/20261028-area-personality/` — most recent merged track (baseline: 404/404, 94.7%/94.0%)

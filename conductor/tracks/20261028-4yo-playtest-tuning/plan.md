# 4yo Playtest + Tuning Loop — Implementation Plan

> **Branch:** `chore/20261028-4yo-playtest-tuning`
> **Base:** `master` @ `7d96aa8e166fbc32aad2b232743ceb6d23f00b42`
>
> Phase states are `pending`, `in_progress`, `verified`, `failed`, or `blocked`.
> Only the primary agent writes this file. Phase subagents report results and the
> primary records them.
>
> Note: Phase 2's session is performed by the user with the child; the agent
> prepares the kit, records the notes from the user's report, and verifies the
> artifact. No phase invents session data — unattested claims fail verification.

## Phase 1: Session prep & baseline

- **Goal:** Session protocol + blank notes template committed; baseline suite green recorded; touchscreen editor run smoke-tested by an adult.
- **Depends on:** none
- **Covers:** FR-1 (setup), FR-5 (baseline), AC-1 (setup), NFR-3
- **Touches:** `conductor/tracks/20261028-4yo-playtest-tuning/session/*.md`
- **Verification:** `gd-tools test --coverage --min 80` green + adult live-boot attested in `session/baseline.md`
- **Status:** pending

- [ ] **P1.T1: Write session protocol** — covers: FR-1
  - [ ] **P1.T1.1: Setup checklist (device, editor run, Area 1 fresh save, 15-min timer)**
  - [ ] **P1.T1.2: Silent-observation rules (no instructions, rescue-only-on-hard-stuck, upset→stop)**
  - [ ] **P1.T1.3: What to watch for (first input latency, stalls, gem/key discovery, door reach, engagement signals)**
- [ ] **P1.T2: Write blank notes template** — covers: FR-2
  - [ ] **P1.T2.1: Sections (setup, timeline, stalls/rescues, engagement, per-criterion verdicts, findings)**
  - [ ] **P1.T2.2: Privacy guard (no names/video/photos — behavior only)**
- [ ] **P1.T3: Record green baseline** — covers: FR-5
  - [ ] **P1.T3.1: Run full suite + lint + format, log results in `session/baseline.md`**
  - [ ] **P1.T3.2: Adult smoke-test of touchscreen editor run into Area 1, attest boot works**

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261028-4yo-playtest-tuning/verification/phase-1.md
-->

## Phase 2: Run session & record evidence

- **Goal:** Session executed per protocol; notes artifact complete with honest per-criterion verdicts.
- **Depends on:** Phase 1
- **Covers:** FR-1, FR-2, AC-1, AC-2, NFR-1, NFR-2
- **Touches:** `conductor/tracks/20261028-4yo-playtest-tuning/session/notes.md`
- **Verification:** Notes present and agent-checked against the template checklist (every section filled, verdicts explicit); zero code changes in this phase
- **Status:** pending

- [ ] **P2.T1: User runs the session** — covers: FR-1
  - [ ] **P2.T1.1: Run silent-observation session per protocol (≤15 min, Area 1, touch tablet)**
  - [ ] **P2.T1.2: Report back timeline, stalls/rescues, engagement, and outcome**
- [ ] **P2.T2: Record structured notes** — covers: FR-2
  - [ ] **P2.T2.1: Fill every template section from the user's report — no invented data**
  - [ ] **P2.T2.2: Per-criterion verdicts (unaided completion, zero stuck, no-instruction touch)**
- [ ] **P2.T3: Extract findings list** — covers: FR-2
  - [ ] **P2.T3.1: Numbered findings, each with severity and in-track vs follow-up disposition**

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261028-4yo-playtest-tuning/verification/phase-2.md
-->

## Phase 3: Tuning, follow-ups & final verification

- **Goal:** Every finding fixed in-track or filed as follow-up; full gate green on the final tree.
- **Depends on:** Phase 2
- **Covers:** FR-3, FR-4, FR-5, AC-3, AC-4, AC-5, NFR-4
- **Touches:** `src/tuning/tuning.gd`, `src/**/*.gd` (tiny fixes only), `tests/**/*.gd`, `conductor/tracks/20261028-4yo-playtest-tuning/session/*.md`
- **Verification:** `gd-tools test --coverage --min 80`, `gd-tools lint`, `gd-tools format --check` all green + findings-disposition table complete
- **Status:** pending

- [ ] **P3.T1: Apply tuning / tiny fixes** — covers: FR-3
  - [ ] **P3.T1.1: Tuning-value changes with before/after rationale per finding**
  - [ ] **P3.T1.2: Tiny safe fixes only — anything bigger goes to P3.T2, no scope growth**
- [ ] **P3.T2: File follow-ups** — covers: FR-4
  - [ ] **P3.T2.1: Every non-fixed finding gets a proposed follow-up track entry in notes**
- [ ] **P3.T3: Final verification** — covers: FR-5
  - [ ] **P3.T3.1: Full suite + coverage gate + lint + format green, results logged**

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261028-4yo-playtest-tuning/verification/phase-3.md
-->

<!--
Review fixes are appended by `conductor-review` as:

## Phase R1: Review Fixes

- **Goal:** Resolve review findings ...
- **Depends on:** Phase 3
- **Covers:** review findings
- **Touches:** ...
- **Verification:** ...
- **Status:** pending

- [ ] **R1.T1: Resolve <finding ID>** — covers: <finding ID>
-->

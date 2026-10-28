# Parent Gate + Hold-to-Quit — Implementation Plan

> **Branch:** `feat/20261028-parent-gate-quit`
> **Base:** `master` @ `3fe75346eb720ed57cb75bedc45527eb40578def`
>
> Phase states are `pending`, `in_progress`, `verified`, `failed`, or `blocked`.
> Only the primary agent writes this file. Phase subagents report results and the
> primary records them.

## Phase 1: Quit-hold core (logic, headless-testable)

- **Goal:** A 3s stationary in-zone hold flushes the save and quits; release/drift resets silently; gameplay input and Esc are unaffected.
- **Depends on:** none
- **Covers:** FR-1, FR-2, FR-4, FR-5, FR-6, NFR-1, AC-1, AC-2, AC-3, AC-4, AC-6
- **Touches:** `src/input/quit_hold.gd` (new), `src/tuning/tuning.gd`, `src/levels/game.gd` (wire-up only), `tests/test_quit_hold.gd` (new)
- **Verification:** `gd-tools test --coverage --min 80` + `gd-tools lint` + `gd-tools format --check`
- **Status:** pending

- [ ] **P1.T1: Viewport-relative corner zone** — covers: FR-1
  - [ ] **P1.T1.1: Zone computed from live viewport rect; recomputed on resize**
  - [ ] **P1.T1.2: Radius + hold seconds as `tuning.gd` constants; non-16:9 resize tests**
- [ ] **P1.T2: Hold state machine** — covers: FR-2, FR-4
  - [ ] **P1.T2.1: Press-in-zone starts timer; release/drift resets silently, no residue**
  - [ ] **P1.T2.2: Full 3s stationary hold fires once (save-flush + quit via injectable double)**
- [ ] **P1.T3: App wiring** — covers: FR-2, FR-6
  - [ ] **P1.T3.1: Real path calls save-flush then `get_tree().quit()`; flush failure still quits**
  - [ ] **P1.T3.2: Esc key is inert (no quit, no state change)**
- [ ] **P1.T4: Input non-interference** — covers: FR-5
  - [ ] **P1.T4.1: Walk-hold + jump-tap traffic during/around a hold never fires quit and gameplay stays intact**

<!--
The primary appends after acceptance:
**Result:** verified
**Checkpoint:** <short-sha>
**Evidence:** conductor/tracks/20261028-parent-gate-quit/verification/phase-1.md
-->

## Phase 2: Hold feedback + live proof

- **Goal:** The hold shows a filling ring with soft ticks and a completion chime, and the live editor proves it.
- **Depends on:** Phase 1
- **Covers:** FR-3, NFR-2, NFR-3, NFR-4, AC-5
- **Touches:** `src/input/quit_hold.gd`, `src/systems/audio_manager.gd` (tick/chime wiring only), `tests/test_quit_hold*.gd`, `.conductor/evidence/*` (screenshot, gitignored)
- **Verification:** `gd-tools test --coverage --min 80` + lint/format + live checks (session ready, ring screenshot captured, smoke run started and stopped)
- **Status:** pending

- [ ] **P2.T1: Progress ring + audio feedback** — covers: FR-3
  - [ ] **P2.T1.1: Gradual ring fill at touch point (screen-safe, no flashes); silent on reset**
  - [ ] **P2.T1.2: Soft ticks during hold + door-chime on completion via existing synth set**
- [ ] **P2.T2: Resize + edge hardening** — covers: FR-1, FR-3
  - [ ] **P2.T2.1: Mid-hold viewport resize recomputes zone; holder-outside → silent reset**
  - [ ] **P2.T2.2: Second-finger gameplay touch neither resets nor fires the timer (pinned by test)**
- [ ] **P2.T3: Live-editor proof** — covers: AC-5
  - [ ] **P2.T3.1: Session ready, scene hierarchy sane, ring mid-hold screenshot, smoke run stopped**

<!--
Review fixes are appended by `conductor-review` as:

## Phase R1: Review Fixes

- **Goal:** Resolve review findings ...
- **Depends on:** Phase 2
- **Covers:** review findings
- **Touches:** ...
- **Verification:** ...
- **Status:** pending

- [ ] **R1.T1: Resolve <finding ID>** — covers: <finding ID>
-->

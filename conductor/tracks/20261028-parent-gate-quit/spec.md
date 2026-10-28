# Parent Gate + Hold-to-Quit — Specification

> Requirements are stable. Once an `FR`, `NFR`, or `AC` ID is approved, do not
> renumber it. If a requirement is removed, mark it `Withdrawn` instead of
> deleting it.

## Overview

Gives grown-ups a way out of the game that a 4-year-old will never trip: a
hidden top-right corner zone where a sustained 3-second stationary hold (with
a filling progress ring and soft tick sounds) flushes the save and exits the
app. The game currently has no quit path at all.

## Problem / Motivation

Roadmap v1.1 item. Today the only way out is killing the app from the OS —
awkward on a tablet handed to a child, and a stray child has no *safe* exit
either (any visible button would be tapped constantly). If unsolved, parents
can't gracefully end a session, blocking the game from becoming a trusted
daily-driver tablet app.

## Goals & Success Metrics

- **Goal:** A parent can exit the game in ~3s, deliberately, on tablet and
  desktop; a child playing normally never triggers or notices it.
- **Metric:** Unit + desktop-simulation tests prove: hold-to-quit fires only
  after a full 3s stationary hold in-zone; walking/jumping thumbs never trip
  it; suite stays green.

## Scope

### In Scope

- Hidden top-right corner hold zone, viewport-relative (live rect, every
  resize)
- 3s stationary hold with progress ring + soft synth ticks; door-chime on
  completion
- Early release / finger drift → silent reset, zero messaging
- Save flush (wallet/wardrobe/area) before `get_tree().quit()`
- Desktop: same mouse-hold works; Esc stays inert
- Gameplay input never stolen — walking/jumping keep working during a hold
- Hold duration + zone radius as `tuning.gd` constants

### Out of Scope

- Fixing `TouchControls`' hardcoded 1280×720 itself (separate tablet-export
  track; this track only avoids repeating the mistake)
- Any menu, pause screen, or dimming
- Gating anything else (gift machine stays freely tappable — it's gameplay)
- Real-tablet long-press proof (filed as human-only follow-up)

## Functional Requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | An invisible hold zone exists in the extreme top-right corner, computed from the live viewport rect | must |
| FR-2 | A continuous stationary 3s touch/mouse-hold inside the zone triggers save-flush then app exit | must |
| FR-3 | During the hold, a progress ring fills at the touch point with soft tick feedback; completion plays the door-chime | must |
| FR-4 | Release before 3s, or drift outside the zone, silently resets the timer with no message or visual residue | must |
| FR-5 | Gameplay input (walk holds, jump taps) continues unaffected while a quit-hold is in progress or reset | must |
| FR-6 | On desktop, the same mouse-hold quits; the Esc key does nothing | must |

## Non-Functional Requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | No reading required — zero text in the flow |
| NFR-2 | Screen-safe: gradual ring fill only, no flashes |
| NFR-3 | Overlay cost negligible — no impact on the 60fps tablet target |
| NFR-4 | No new external assets; ticks/chime reuse the synth audio set |

## Acceptance Criteria

| ID | Criterion | Verifies |
| --- | --- | --- |
| AC-1 | 3s stationary in-zone hold → save flushed + quit called (unit-tested with a quit double) | FR-2 |
| AC-2 | Release at <3s or drift out-of-zone → no quit, no residue, silent | FR-4 |
| AC-3 | Simulated walk-hold + jump-tap traffic never starts or disturbs gameplay, and never fires quit | FR-5 |
| AC-4 | Zone tracks live viewport rect across simulated resize (incl. non-16:9) | FR-1 |
| AC-5 | Full gate green (`test --coverage --min 80`, lint, format) + live-editor screenshot of ring mid-hold + smoke run | FR-3, NFR-3 |
| AC-6 | Esc pressed alone never quits on desktop | FR-6 |

## Edge Cases

- Second finger touches down elsewhere mid-hold → gameplay handles it; the
  quit timer neither resets nor fires from that touch, but quit still requires
  the holder stationary in-zone (pinned by test).
- Hold starts in-zone then viewport resizes mid-hold → zone recomputed;
  holder now outside → silent reset.
- Save flush fails → quit anyway (never trap the parent); failure is silent,
  autosaves already cover state.
- Hold during door celebration / finale → same behavior; exit is always safe
  (no fail states to corrupt).
- Mouse hold on desktop with cursor drift → same reset rule.

## Dependencies

- **Tracks:** none (standalone; base is master @ `3fe7534`)
- **External:** none

## Open Questions & Assumptions

- **Assumption:** Zone = extreme-corner circle, ~64px radius default in
  `tuning.gd` (`QUIT_ZONE_RADIUS`, `QUIT_HOLD_SECONDS = 3.0`); tunable after
  device testing.
- **Assumption:** A 3s stationary hold is a sufficient grown-up gate — no
  second confirmation step.
- **Question (follow-up, not blocking):** real-tablet long-press feel check —
  filed as human-only follow-up at close-out.

## References

- `conductor/product.md` (Roadmap → v1.1), `conductor/product-guidelines.md`
  (UX, Safety), `conductor/tech-stack.md` (input/audio/save),
  `src/input/touch_controls.gd`, `src/systems/save_game.gd`,
  `src/tuning/tuning.gd`

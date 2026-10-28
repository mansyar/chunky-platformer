# Resume-mid-adventure fix — Specification

> Requirements are stable. Once an `FR`, `NFR`, or `AC` ID is approved, do not
> renumber it. If a requirement is removed, mark it `Withdrawn` instead of
> deleting it.

## Overview

Persist the child's last area (`area_index`) in `user://save_game.json`, restore it on boot at the area's safe spawn, and resolve the product contradiction so resume-in-saved-area with fresh keys is canonical. Gems-taken, wallet, and wardrobe persist; keys reset per area; the finale loop saves area 0. Old V1 saves migrate forward without loss.

## Problem / Motivation

`src/levels/game.gd` always boots `_build_area(0)` and `area_index` is never saved or restored, so every launch drops the child back in the meadow even mid-cave/sunset. Product.md promises "the child resumes mid-adventure across sessions" with "keys/doors progress" saved, while also saying "launching always starts in the meadow" with "keys reset per area". Testers cannot validate multi-area play, and children lose their adventure context on every restart. If unsolved, playtest results are invalid and the persistence promise stays broken.

## Goals & Success Metrics

- **Goal:** Quit mid-cave/sunset → relaunch lands in the same area at its safe spawn, with wallet/gems/wardrobe intact and that area's 3 keys fresh for a new attempt.
- **Metric:** Manual + test proof: (1) cave resume intact, (2) old V1 save migrates to meadow with collections preserved, (3) corrupt/future save boots fresh meadow with no crash and no error text, (4) finale saves area 0.

## Scope

### In Scope

- Persist `area_index` on area swap and finale loop
- Restore saved area on boot at the area's safe spawn (no exact XY)
- Save schema V1 → V2 with forward migration (V1 loads, defaults area 0)
- Clamp out-of-range `area_index` to 0 (meadow)
- Finale celebration loops home and saves area 0
- Keys start fresh in the resumed area; gems-taken/wallet/wardrobe persist
- Fix `conductor/product.md` wording so resume-in-saved-area with fresh keys is canonical

### Out of Scope

- Exact XY position restore within an area
- Preserving half-collected key state across sessions
- Touch input, hint system, celebration visuals, export presets, parent gate
- New areas, puzzles, settings, menus, external assets

## Functional Requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | Save persists `area_index` whenever the area changes and after the finale loop | must |
| FR-2 | Boot restores the saved area at its safe spawn (AreaBuilder default entry) | must |
| FR-3 | V1 saves (no `area_index`) migrate to V2, preserving wallet/owned/worn/taken and defaulting area to 0 | must |
| FR-4 | Out-of-range `area_index` (negative or >= area count) clamps to 0 on load | must |
| FR-5 | Completing the finale saves area 0 so the next boot starts in the meadow | must |
| FR-6 | A resumed area starts with its 3 keys fresh (uncollected); gems-taken, wallet, and wardrobe persist unchanged | must |
| FR-7 | `conductor/product.md` persistence/progression wording names resume-in-saved-area with fresh keys as canonical | should |

## Non-Functional Requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | Boot stays sub-second; 60 FPS gameplay unaffected; no per-frame allocation in save/boot path |
| NFR-2 | Coverage ≥80 on new save/boot logic; typed GDScript; `gd-tools lint` and `gd-tools format --check` clean |
| NFR-3 | Corrupt, missing, empty, or future-version save boots fresh meadow (wallet 0, area 0) with no crash and no error text |
| NFR-4 | Toddler UX holds: no reading required, no stuck state, oversized touch targets unchanged, immediate feedback on transitions |

## Acceptance Criteria

| ID | Criterion | Verifies |
| --- | --- | --- |
| AC-1 | Play into cave (area 1), quit, relaunch → game boots in cave at spawn, wallet/gem-taken/wardrobe intact, keys 0/3 | FR-1, FR-2, FR-6 |
| AC-2 | Load a V1 save file (version 1, no area key) → boots meadow with wallet/owned/worn/taken preserved | FR-3 |
| AC-3 | Load a save with `area_index` 99 (or negative) → boots meadow, no crash | FR-4 |
| AC-4 | Complete final-area door → celebration loops home and save holds area 0; next boot starts meadow | FR-5 |
| AC-5 | Corrupt / empty / future-version (V3+) save → fresh meadow boot, no crash, no error text | NFR-3, FR-2 |
| AC-6 | `conductor/product.md` contradiction resolved: resume-in-saved-area with fresh keys stated; no lingering launch-always-meadow claim | FR-7 |
| AC-7 | Live checks pass: editor session ready, touched scene hierarchy sane, screenshot captured, smoke run starts and returns to stopped | NFR-1, NFR-4 |

## Edge Cases

- Missing save file → fresh start (area 0, wallet 0), existing behavior unchanged
- Empty file / invalid JSON → fresh start, warning only, no crash
- Future version (3+) → fresh start, never migrate forward blindly
- V1 file with unknown/duplicate cosmetics → existing repair preserved, area defaults 0
- Out-of-range index after content changes (areas removed) → clamp to 0
- Quit mid-celebration / mid-transition → last committed area wins; never boot into a half-swapped state
- Reinstall (no `user://`) → fresh meadow, first-launch behavior unchanged

## Dependencies

- **Tracks:** none (gem-shop V1 save and goal-loop areas are already merged in master)
- **External:** none (gd-tools CLI + Godot 4.7 only; no services, credentials, or network)

## Open Questions & Assumptions

- **Assumption:** Area start means the AreaBuilder default spawn/entry — no safe-coordinate math needed.
- **Assumption:** Keys-fresh means the existing GoalState rebuild (fresh 0/3 per area build) is preserved, not a new key-persistence layer.
- **Assumption:** First-ever launch (no save) still starts in the meadow; only subsequent launches resume.

## References

- `conductor/product.md` (persistence + progression sections)
- `conductor/tech-stack.md` (save format + export targets)
- `src/levels/game.gd` (always `_build_area(0)` — the defect)
- `src/systems/save_game.gd` (V1 schema `{version, wallet, owned, worn, taken}`)

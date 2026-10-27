# Gem Economy + Gift Machine — Specification

> Requirements are stable. Once an `FR`, `NFR`, or `AC` ID is approved, do not
> renumber it. If a requirement is removed, mark it `Withdrawn` instead of
> deleting it.

## Overview

Gems become a limited, spendable resource: each area holds a fixed set of
gems, collected gems feed a persistent wallet, and a friendly gift machine in
each area turns gems into surprise cosmetic upgrades for Robo. This gives
collecting a purpose beyond the counter, teaches counting and saving with big
numerals, and never introduces failure, reading, or menus.

## Problem / Motivation

Today gems respawn endlessly and the counter is monotonic — collecting has no
purpose and no end. The child (learning numbers and calculation) gets no
chance to practice counting, choosing, or saving. If gems stay infinite and
meaningless, the core loop stays flat and a requested feature (spending gems
on upgrades) has nowhere to live.

## Goals & Success Metrics

- **Goal:** A 4-year-old finds the machine, spends gems, and gets a visible
  cosmetic unaided in one session.
  - **Metric:** Unaided gift-machine use observed (playtest notes or
    parent report); no instruction needed.
- **Goal:** Earnings and cosmetics survive closing the app.
  - **Metric:** Wallet + owned/worn cosmetics + collected-gem state intact
    after a full app restart.

## Scope

### In Scope

- Wallet model + HUD (big numerals + gem icon).
- Fixed gem budgets (~10 hand-placed gems per area, no timed respawn,
  collected stays collected on revisit).
- One gift machine per area: tiered prices (1/2/3, numerals + gem pips),
  surprise dispense, confetti, auto-wear.
- Starter set of 6 cosmetics: 3 hats + 2 trails + 1 robot color
  (prices 1, 1, 2, 2, 3, 3 = 12 gems to complete).
- No-duplicate logic + complete-set bonus celebration.
- Gentle empty-wallet behavior (wiggle + hint sparkle to nearest gem).
- Tap-Robo to cycle owned looks.
- Minimal save in `user://` JSON: wallet, owned/worn cosmetics, per-area
  gem-taken flags, version field. Corrupt file falls back to fresh start.

### Out of Scope

- Functional upgrades (jump height, speed, hint changes).
- Key/door/goal-loop changes.
- Audio for the machine (covered by the future Audio track; machine stays
  silent or reuses existing feedback pops only if already present).
- Full save system (player position, settings, parent gate).
- Areas 2–3 new content beyond gem placement + machine instance.
- Menus, text, or settings screens of any kind.

## Functional Requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-1 | Each area contains a fixed set of ~10 hand-placed gems; a collected gem stays collected when the area is revisited (no timed respawn). | must |
| FR-2 | Collected gems accumulate in a wallet that persists for the session; the HUD shows the wallet count as big numerals with a gem icon. | must |
| FR-3 | Each area has one gift machine; tapping it with enough gems deducts the price and dispenses a cosmetic with a pop + confetti, auto-worn immediately. | must |
| FR-4 | Gifts are tiered at prices 1, 2, and 3, shown as big numerals plus gem pips (no words to read). | must |
| FR-5 | The machine never grants an already-owned cosmetic until the 6-item set is complete; once complete, using it triggers a bonus sparkle celebration instead of an item. | must |
| FR-6 | Using the machine with 0 gems (or fewer than the cheapest gift) plays a friendly wiggle and a hint sparkle toward the nearest uncollected gem; it never scolds, locks, or shows a refusal state. | must |
| FR-7 | Tapping Robo cycles through owned cosmetics (wraps around); the worn look is visible immediately. | should |
| FR-8 | Wallet balance, owned/worn cosmetics, and per-area gem-taken flags are saved to `user://` JSON and loaded at boot; a corrupt or missing file starts fresh with no crash and no error text. | must |
| FR-9 | The game saves on gem collect, on gift dispense, and on area transition. | must |

## Non-Functional Requirements

| ID | Requirement |
| --- | --- |
| NFR-1 | 60 FPS on a tablet; machine, cosmetics, and wallet HUD add no measurable per-frame cost when idle. |
| NFR-2 | Zero-failure tone: no scolding, no locks, no dead ends, no game-over anywhere in the economy loop. |
| NFR-3 | Numerals + icons only (no words to read); prices and wallet readable at a glance by a number-learning 4-year-old; touch targets ≥ 64 px. |
| NFR-4 | New-code coverage ≥ 80% (`gd-tools test --coverage --min 80`). |
| NFR-5 | All art (machine, hats, trails, color variant) is code-generated; no external assets. |

## Acceptance Criteria

| ID | Criterion | Verifies |
| --- | --- | --- |
| AC-1 | Collecting every gem in an area, leaving, and returning shows zero gems restored; total collectible count per area is fixed and documented in the area layout. | FR-1 |
| AC-2 | Collecting 3 gems shows wallet numeral "3" with gem icon; quitting to title (same session) keeps the balance. | FR-2 |
| AC-3 | Tapping the machine with ≥ price deducts exactly the price, pops a gift with confetti, and Robo visibly wears it within 1 second. | FR-3 |
| AC-4 | Machine shows prices 1/2/3 as numerals + pips with no words; a price-3 gift deducts exactly 3. | FR-4 |
| AC-5 | Owning all 6 cosmetics then using the machine triggers the bonus celebration and grants no duplicate; wallet is still deducted (or bonus is free — decided in implementation: bonus costs nothing). | FR-5 |
| AC-6 | Tapping the machine with 0 gems plays the wiggle + hint sparkle toward a real uncollected gem; no refusal UI appears. | FR-6 |
| AC-7 | Tapping Robo with 2+ owned cosmetics changes the worn look each tap and wraps to the first after the last. | FR-7 |
| AC-8 | Collect gems → force-quit app → relaunch: wallet, owned/worn cosmetics, and collected-gem state are intact; a deliberately corrupted save file boots fresh with no crash. | FR-8 |
| AC-9 | Gem collect, dispense, and area transition each write the save file (verified by file mtime/content in test). | FR-9 |
| AC-10 | Live: editor session `ready`, touched scenes open with sane hierarchy, screenshots captured to `.conductor/evidence/`, smoke run starts the game and returns to `stopped`. | FR-1, FR-3 |

## Edge Cases

- Corrupt / missing / future-version save file: boot fresh, never crash, never show error text (version field reserved for migration).
- Machine tapped with 0 gems, or with gems but set complete: gentle hint (FR-6) / bonus celebration (FR-5).
- Rapid repeated taps on the machine: dispenses serialize one at a time; wallet never goes negative.
- Reinstall / first boot: everything fresh, machine offers cheapest gifts first is NOT required (surprise order may be fixed by price tier, cheapest available first).
- Area transition mid-celebration: celebration is cosmetic-only and cancellable; wallet/ownership already committed before FX.
- Bonus-after-complete (AC-5): bonus celebration costs nothing (assumption, cheapest kind behavior).
- Existing players (no save file): treated as first boot; previously collected gems under the old respawn system start uncollected.

## Dependencies

- **Tracks:** none (this track creates the first save system; it modifies gem behavior from legacy track `collect_play_20261008`, kept as history).
- **External:** none.

## Open Questions & Assumptions

- **Assumption:** ~10 gems per area and the 12-gem set total leave comfortable slack for learning to save; exact placements decided in implementation within existing levels.
- **Assumption:** Bonus celebration after set completion is free.
- **Assumption:** Numerals reuse the existing pixel HUD digit art, extended as needed.
- **Assumption:** Machine surprise order: cheapest unowned tier first (kindest math), recorded here so review can check it.

## References

- `conductor/product.md` (non-goals: no menus/text; roadmap: persistence phase)
- `conductor/product-guidelines.md` (zero failure, juicy feedback, code-generated art)
- Legacy track: `collect_play_20261008` (gem respawn + counter behavior being replaced)

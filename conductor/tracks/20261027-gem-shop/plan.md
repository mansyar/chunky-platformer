# Gem Economy + Gift Machine — Implementation Plan

> **Branch:** `feat/20261027-gem-shop`
> **Base:** `master` @ `c6cf38f778cc180c86e8ba6b8a1efcf119f6ed38`
>
> Phase states are `pending`, `in_progress`, `verified`, `failed`, or `blocked`.
> Only the primary agent writes this file. Phase subagents report results and the
> primary records them.

## Phase 1: Wallet + Fixed Gem Budget

- **Goal:** Gems are limited and counted: fixed per-area sets with no respawn, wallet model, HUD numerals.
- **Depends on:** none
- **Covers:** FR-1, FR-2, NFR-4, AC-1, AC-2
- **Touches:** `src/systems/wallet.*`, `src/world/gem.*`, `src/ui/wallet_hud.*`, `src/levels/*layout*`, `src/tuning/tuning.gd`, `tests/test_wallet*`, `tests/test_gem_budget*`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** verified

- [x] **P1.T1: Wallet model + HUD** — covers: FR-2
  - [x] **P1.T1.1: Wallet state (add/spend/balance, never negative, changed signal)**
  - [x] **P1.T1.2: Wallet HUD numerals + gem icon (big, readable, ≥64px targets n/a)**
- [x] **P1.T2: Fixed gem budget per area** — covers: FR-1
  - [x] **P1.T2.1: Remove timed respawn; collected stays collected on revisit**
  - [x] **P1.T2.2: ~10 hand-placed gems per area in layouts (documented counts)**

**Result:** verified
**Checkpoint:** eea1e1e
**Evidence:** conductor/tracks/20261027-gem-shop/verification/phase-1.md

## Phase 2: Gift Machine + Cosmetics

- **Goal:** One machine per area dispenses tiered surprise cosmetics with kind empty/set-complete behavior; tap-Robo cycles looks.
- **Depends on:** Phase 1
- **Covers:** FR-3, FR-4, FR-5, FR-6, FR-7, NFR-1, NFR-2, NFR-3, NFR-5, AC-3, AC-4, AC-5, AC-6, AC-7
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** verified

- [x] **P2.T1: Machine node + interaction** — covers: FR-3, FR-6
  - [x] **P2.T1.1: Machine instance per area, tap detection, dispense pop + confetti + auto-wear**
  - [x] **P2.T1.2: Empty-wallet wiggle + hint sparkle toward nearest uncollected gem**
- [x] **P2.T2: Tiered pricing + surprise order** — covers: FR-4
  - [x] **P2.T2.1: Prices 1/2/3 as numerals + pips; cheapest-unowned-first order**
- [x] **P2.T3: Cosmetic set + wear/cycle** — covers: FR-5, FR-7
  - [x] **P2.T3.1: 6 code-generated cosmetics (3 hats, 2 trails, 1 color; 12-gem set)**
  - [x] **P2.T3.2: No-duplicates until complete; free bonus celebration after; tap-Robo cycles owned looks**

**Result:** verified
**Checkpoint:** 2f0c7ae
**Evidence:** conductor/tracks/20261027-gem-shop/verification/phase-2.md

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

## Phase 3: Minimal Save/Load

- **Goal:** Wallet, cosmetics, and gem-taken flags survive app restarts; corrupt saves boot fresh.
- **Depends on:** Phase 2
- **Covers:** FR-8, FR-9, AC-8, AC-9
- **Touches:** `src/systems/save_game.*`, `src/levels/game.*` (load-at-boot, save triggers), `tests/test_save_game*`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** verified

- [x] **P3.T1: SaveGame read/write + version field + corrupt fallback** — covers: FR-8
  - [x] **P3.T1.1: user:// JSON schema (wallet, owned/worn, gem flags, version) with round-trip tests**
  - [x] **P3.T1.2: Corrupt/missing/future-version handling (fresh boot, no crash, no text)**
- [x] **P3.T2: Autosave triggers** — covers: FR-9
  - [x] **P3.T2.1: Save on collect, dispense, and area transition (mtime/content tests)**

**Result:** verified
**Checkpoint:** f0818fd
**Evidence:** conductor/tracks/20261027-gem-shop/verification/phase-3.md

## Phase 4: Live Verification + Evidence

- **Goal:** Prove the economy loop in the running editor: session ready, scenes sane, screenshots, smoke run, gates green.
- **Depends on:** Phase 3
- **Covers:** AC-10, NFR-1, NFR-4
- **Touches:** `conductor/tracks/20261027-gem-shop/verification/*`, `.conductor/evidence/*` (gitignored)
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** verified

- [x] **P4.T1: Live pass + evidence pack** — covers: AC-10
  - [x] **P4.T1.1: session ready, touched scenes open (hierarchy sane), screenshots captured**
  - [x] **P4.T1.2: project_run smoke (game starts, machine usable, back to stopped); coverage gate ≥80 new-code**

**Result:** verified
**Checkpoint:** d0e615f
**Evidence:** conductor/tracks/20261027-gem-shop/verification/phase-4.md

## Phase R1: Review Fixes

- **Goal:** Resolve review findings F1, F2, F3: WalletHud becomes the sole top-left badge, pip clamp is honest, icon sizing uses the area palette.
- **Depends on:** Phase 4
- **Covers:** F1, F2, F3 (FR-2, AC-2)
- **Touches:** `src/levels/area_builder.gd`, `src/ui/gem_counter.gd` (delete), `src/ui/machine_tag.gd`, `src/ui/wallet_hud.gd`, `tests/test_gem_counter.gd` (delete), `tests/test_gem_integration.gd`, `tests/test_gem_budget.gd`, `tests/test_game_transition.gd`, `tests/test_area_builder.gd`
- **Verification:** `gd-tools test --coverage --min 80`
- **Status:** in_progress

- [ ] **R1.T1: Remove legacy GemCounter; WalletHud is the sole badge** — covers: F1
- [ ] **R1.T2: Pip clamp + icon-size palette consistency** — covers: F2, F3

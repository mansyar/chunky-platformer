# Phase 3 evidence — Doc sync + integrated verification (20261028-resume-mid-adventure)

- Branch: `feat/20261028-resume-mid-adventure`
- Phase base: `2344323`
- Date: 2026-10-28
- Commits: none (phase BLOCKED — file-write tool denied; see Blockers)
- Touched (intended): `conductor/product.md` (P3.T1), this file (P3.T2)

## Result

**blocked** — P3.T2 integrated verification is GREEN (full gate exit 0 plus a
fresh live pass this session), but P3.T1 could not be persisted: the `edit`
tool returned `permission denied` on `conductor/product.md` (attempted twice,
in two separate sessions). No files were modified; the tree is clean at
`2344323`. The exact minimal patch is recorded below so the primary can apply
it in seconds.

## P3.T1 — product.md resume contradiction (FR-7, AC-6): PENDING (not applied)

Before (exact current wording):

- Progression section: "After the last area's door, a finale celebration loops
  home to a fresh meadow; the wallet, wardrobe, and collected-gem state
  persist while keys reset per area. Launching always starts in the meadow."
- Persistence section: "Full progress saved to user://save_game.json
  (versioned): wallet balance, owned/worn cosmetics, and per-area gem-taken
  flags, alongside keys/doors progress. The child resumes mid-adventure
  across sessions; a corrupt or missing file boots fresh with no crash and no
  error text."

Contradiction: "Launching always starts in the meadow" plus "keys/doors
progress" saved vs the implemented and specified resume-in-saved-area with
fresh keys (spec FR-2/FR-6, Phases 1–2 verified).

After (proposed minimal replacement, toddler framing kept):

- Progression: "After the last area's door, a finale celebration loops home
  to a fresh meadow and saves it, so the next launch starts there; the
  wallet, wardrobe, and collected-gem state persist while each area's 3 keys
  start fresh. Launching resumes the saved area at its safe starting spot —
  silently, with no menus or reading, so the child picks up mid-adventure
  right where they left off (the very first launch starts in the meadow)."
- Persistence: "Full progress saved to user://save_game.json (versioned):
  wallet balance, owned/worn cosmetics, per-area gem-taken flags, and the
  last visited area. Keys and doors are never saved — every built area starts
  with its 3 keys fresh. The child resumes mid-adventure across sessions:
  launching reopens the saved area at its safe starting spot, silently, with
  nothing to read or choose; a corrupt or missing file boots a fresh meadow
  with no crash and no error text."

Canonical behavior stated: boot resumes the saved area at its spawn (never
exact XY); wallet/wardrobe/gem-taken flags persist; keys and doors are fresh
in every built area; the finale saves area 0 and loops home to the meadow;
corrupt/missing saves boot a fresh meadow. No other `product.md` changes.

## P3.T2.1 — full verification gate: GREEN

| Command | Exit | Result |
|---|---|---|
| `gd-tools test --coverage --min 80` | 0 | 383/383 passed, 12 snapshots matched, 95.1% lines / 94.0% branches (gate 80) |
| `gd-tools lint` | 0 | no issues |
| `gd-tools format --check` | 0 | 71/71 formatted |

Note: the first coverage attempt this session exited 1 at 75.1%/73.8%
because it raced a stale background coverage run left over from the prior
subagent session (shared `.gd-tools` artifacts; that stale run itself
reported 95.1%/94.0% with 383/384 and an artifact-prune error). A clean
retry with nothing else running → exit 0 as above. No code changed;
environmental only (1 retry used of the allowed 2).

## P3.T2.2 — live editor pass (godot-ai MCP 4.3.1, Godot 4.7.2): GREEN

| Tool | Target | Result |
|---|---|---|
| `session_manage` list | project | 1 session `chunky-platformer`, `readiness: ready`, Godot 4.7.2, current scene `game.tscn`, stopped |
| `scene_get_hierarchy` | game.tscn (stopped) | sane: single `/Game` root (children runtime-built by `AreaBuilder`) |
| `project_run` | main scene | `live`, `helper_live: true`, no run errors |
| `editor_screenshot` source=game | running game | meadow boot rendered (Robo, gems, fresh key badge, wallet 0, gift machine, touch controls); 640x360 PNG returned inline (`frames_drawn` 1028, `stale_frame: false`). Binary NOT persisted under `.conductor/evidence/` — no binary-write tool in this phase's toolset (same limitation as Phases 1–2) |
| `project_manage` stop | game | `stopped: true`, readiness back to `ready` |

## Integrated AC-1..AC-7 rollup

- AC-1 (cave resume intact, keys 0/3): PASS — Phase 2
  `test_boot_restores_saved_cave_at_spawn_with_collections` + live reboot
  proof; `src/` untouched since, full suite green.
- AC-2 (V1 → meadow, collections preserved): PASS — Phase 1 migration tests,
  full suite green.
- AC-3 (99/negative → meadow, no crash): PASS — Phase 1 clamp tests, full
  suite green.
- AC-4 (finale saves 0, next boot meadow): PASS — Phase 2
  `test_finale_saves_meadow_and_reboot_starts_meadow`, full suite green.
- AC-5 (corrupt/empty/future → fresh, no crash): PASS — Phase 1 recovery
  tests, full suite green.
- AC-6 (product.md contradiction resolved): BLOCKED — patch ready (above),
  not applied (`edit` permission-denied).
- AC-7 (live checks): PASS — fresh pass this phase (table above).

NFR-1 holds (no per-frame cost; doc change implies none; suite green).
NFR-4 holds (no menus/reading added; proposed wording keeps silent resume).

## Deviations

- None to `src/`, `tests/`, `plan.md`, `metadata.json`, or registry.
  Environmental only: 1 coverage retry after cross-session run interference
  (no code impact).

## Follow-ups for the primary

1. Apply the two-hunk P3.T1 patch from this file to `conductor/product.md`
   and commit (`docs(product): resolve resume contradiction, keys fresh`).
2. Commit this evidence file (`conductor(evidence): record Phase 3
   verification`) so the phase has a persistent artifact.
3. Then Phase 3 is verifiable as done: gate green + live green + AC-6 quotes
   on disk.

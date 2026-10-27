# Conductor Migration Report

- **Date:** 2026-10-27T06:19:36Z
- **From:** Conductor 1.x
- **To:** Conductor 2.0
- **Mode:** Upgrade in place

## Context

- **Preserved:** `product.md`, `tech-stack.md`, `product-guidelines.md`
- **Regenerated:** `workflow.md` with Workflow Config and Verification Strategy
- **Index:** merged in place; version marker added
- **Scaffolding:** `tracks.md`, `tracks/`, `.conductor/` ignore
- **Agents:** installed (OpenCode host: `.opencode/agents/conductor-phase.md`, `.opencode/agents/conductor-reviewer.md`)

## Tracks

| Track | Status | Missing metadata | Plan v2 | Spec v2 | Recommended action |
| --- | --- | --- | --- | --- | --- |
| `foundation_20261008` | completed (registry `[x]`) | `branch`, `base_branch`, `base_sha`, `progress`, `review_verdict`, `doc_sync` (now backfilled) | no | no | Keep as historical; recreate with `conductor-new-track` only if the team wants the new review/evidence trail |
| `movement_camera_20261008` | completed (registry `[x]`) | `branch`, `base_branch`, `base_sha`, `progress`, `review_verdict`, `doc_sync` (now backfilled) | no | no | Keep as historical; recreate with `conductor-new-track` only if the team wants the new review/evidence trail |
| `collect_play_20261008` | completed (registry `[x]`) | `branch`, `base_branch`, `base_sha`, `progress`, `review_verdict`, `doc_sync` (now backfilled) | no | no | Keep as historical; recreate with `conductor-new-track` only if the team wants the new review/evidence trail |
| `goal_loop_20261008` | completed (registry `[x]`) | `branch`, `base_branch`, `base_sha`, `progress`, `review_verdict`, `doc_sync` (now backfilled) | no | no | Keep as historical; recreate with `conductor-new-track` only if the team wants the new review/evidence trail |

## Open Questions & Assumptions

- All four legacy tracks are marked completed in `tracks.md` but carry v1 `status: "new"` in metadata; treated as completed history (no active work detected).
- `review.strict` set to `true` per user request during upgrade.
- Public repo created during setup: `https://github.com/mansyar/chunky-platformer` (`origin`); `pr.enabled` set to `true` with `gh`, base `master`, squash.
- No CI configured (`watch_ci: false`); Android device testing, real 4-year-old playtest, and Windows/Android export verification remain human-only.

## Limits

- Legacy tracks are blocked by `conductor-implement`, `conductor-review`, and
  phase revert until they are recreated or manually repaired.
- Old specs and plans were not rewritten automatically.
- When a track is repaired, remove `legacy: true` from its metadata and update
  the spec/plan to the v2 contract.
- The pre-migration directory is backed up at
  `.conductor/backups/conductor-v1-20261027-171608/`.
- v2 runs sequentially in the current worktree and creates no worktrees. If
  `.conductor/worktrees/` exists, run `git worktree prune` and delete the
  directory manually after confirming the entries are no longer needed.

# Project Workflow — Robo's Treasure Hunt

## Guiding Principles

1. **The plan is the source of truth.** Every phase, task, result, checkpoint,
   and evidence link lives in `plan.md`.
2. **The tech stack is deliberate.** A change to the stack is recorded in
   `tech-stack.md` before the implementation depends on it.
3. **Verification is agent-executed.** The phase subagent runs the configured
   checks and writes evidence. The user is not asked to manually verify routine
   work.
4. **Evidence over assertion.** A phase is complete only when the configured
   checks pass and the evidence file exists.
5. **No silent debt.** A finding is fixed, explicitly accepted with a reason, or
   tracked as an issue. It is never quietly ignored.
6. **Stay inside the phase contract.** `Touches` defines the expected blast
   radius. A required deviation is allowed, recorded, and reviewed.
7. **Non-interactive and CI-aware.** Prefer commands that terminate. Use
   `CI=true` for watch-mode tools where the ecosystem supports it.
8. **The live editor is ground truth for scenes.** `gd-tools test` proves logic;
   the running Godot editor (via godot-ai MCP) proves the game looks and plays
   right. Every phase that touches scenes, nodes, or anything visible ends with
   a live check, not just a passing test suite.

## Workflow Config

```yaml
project:
  type: "game"
  languages: ["GDScript"]
commands:
  setup: "pip install gd-tools-cli && gd-tools init"
  dev: "godot --path ."
  test: "gd-tools test"
  coverage: "gd-tools test --coverage --min 80"
  lint: "gd-tools lint"
  format: "gd-tools format"
  # typecheck retired 2026-10-27: godot --headless --check-only is too slow
  # (18+ min wall, mostly lock-blocked beside the live editor) and duplicates
  # the Godot editor's built-in GDScript language server (port 6005), which
  # type-checks every script at scan time. Static confidence now comes from
  # lint + the editor/LSP diagnostics + the suite itself (tests compile and
  # execute every script). Do not re-add a CLI typecheck gate.
  build: "godot --headless --import --path ."
  verify_phase: "gd-tools test --coverage --min 80"
coverage:
  gate: 80
  scope: "new-code"
verification:
  layers: ["static", "unit", "integration", "visual", "smoke"]
  retry: 2
  manual_exceptions: ["android-device-testing", "playtest-with-4-year-old", "windows-android-export", "editor-offline-live-checks"]
git:
  base_branch: "master"
  fetch: true
  commit_style: "conventional"
  task_commits: true
  phase_squash: true
review:
  strict: true
  issues:
    enabled: true
    auto_create: false
    min_severity: "medium"
    group_low: true
    labels: ["tech-debt", "conductor"]
pr:
  enabled: true
  tool: "gh"
  base: "master"
  media: "always"
  watch_ci: false
  watch_timeout_minutes: 15
  merge_method: "squash"
```

## Development Commands

### Setup

```bash
pip install gd-tools-cli && gd-tools init
```

### Daily Development

```bash
# Start the game (or open the project in the Godot editor)
godot --path .

# Run tests
gd-tools test

# Run coverage
gd-tools test --coverage --min 80

# Lint
gd-tools lint

# Format
gd-tools format

# Static type feedback comes from the Godot editor's built-in GDScript
# language server (port 6005), not from a CLI gate: keep the project open
# in the editor while working; a clean editor log plus a green suite means
# the scripts compile and run.

# Build (headless import check; exports are manual via the editor for Windows/Android)
godot --headless --import --path .
```

### Before Committing

```bash
gd-tools format --check && gd-tools lint && gd-tools test --coverage --min 80
```

### Godot AI Live Editor (godot-ai MCP v4.3.1)

The editor is a required companion to the test suite — not an optional extra.
The `godot_ai` addon (`addons/godot_ai`, enabled in `project.godot`) bridges the
running editor to agents over MCP. The managed server starts via `uvx`; no
bare-URL connection is accepted.

Prerequisites (once per machine, already done here):

- Godot 4.7+ with the `godot_ai` addon enabled.
- `uv`/`uvx` on `PATH` (server runs as `godot-ai 4.3.1`).

Per session (every phase, before any live check):

1. Open this project in the Godot editor (the addon connects automatically).
2. Confirm the session is live via MCP: `session_manage` (`op: "list"`) shows
   `chunky-platformer` with `readiness: "ready"`. If the list is empty, the
   editor is not open — open it and re-check. Never mark live checks passed
   while the session list is empty.

Common live checks (all agent-executed MCP tools, no shell needed):

- `editor_state` — editor version, project, current scene, play state.
- `scene_get_hierarchy` — scene-tree structure of the touched scene.
- `scene_open` + `editor_screenshot` — open the touched scene, capture a
  screenshot to `.conductor/evidence/` for the evidence file.
- `project_run` — short smoke run to prove the game starts and the touched
  scene plays (stopped state afterwards).

MCP-vs-file rules:

- **Code changes** (`*.gd`, `*.cfg`, `*.toml`, docs) go through the `edit`
  tool so every change is git-tracked. Never rewrite code via MCP script
  tools to bypass review.
- **Scene inspection and live verification** go through MCP (`scene_*`,
  `node_*` reads, `editor_screenshot`, `project_run`). Prefer MCP reads over
  hand-parsing `.tscn` files.
- **Scene edits** follow the phase contract: small `node_*` adjustments are
  allowed inside `Touches` and recorded as commits; structural scene work
  belongs to an explicit task.
- The phase subagent may use godot-ai MCP tools for reads and live
  verification. The reviewer is read-only and uses MCP reads only.

## Phase & Task Workflow

Implementation is executed one phase at a time by a phase subagent. The primary
agent owns `plan.md`, `metadata.json`, the registry, and review artifacts.

### Task Lifecycle

1. Confirm the live editor session: `session_manage` (`op: "list"`) shows
   this project with `readiness: "ready"`. If no session is connected, open
   the project in Godot and re-check before starting work.
2. Read the phase contract in `plan.md`, the relevant requirements in `spec.md`,
   and the applicable style guides.
3. Work through the phase's tasks in order.
3. Test-first for logic-bearing code: write or update the failing `GdToolsTest`
   suite before the implementation (physics tuners, save/load, hint logic,
   collectible state, door/key state, AssetFactory generation logic). Purely
   visual code (pixel-drawing DSL internals, frame data, palette records) is
   verified via deterministic snapshots (`assert_snapshot`) instead.
4. Implement the smallest change that satisfies the task.
5. Run the targeted checks for the task.
6. Commit the task with a conventional commit message.
7. Report the task's status and commit SHA to the primary agent.

The subagent does **not** edit `plan.md`. The primary marks tasks complete after
it accepts the phase.

### Deviations

- If the phase goal requires a file outside `Touches`, make the smallest
  necessary change and record it in the report under `deviations`.
- If the work requires a product or design decision, stop and report `blocked`.
- Do not silently expand scope, add a dependency, or migrate unrelated code.

### Phase Completion

1. Run the phase's `Verification` command exactly as written in `plan.md`.
2. Run `verify_phase` when it is configured and different from the phase command.
3. Run the mandatory live checks for the phase (see Verification Strategy):
   session live, touched scene opens, hierarchy sane, screenshot captured, and
   a smoke run when the phase touches anything playable. Record outputs in the
   evidence file.
4. Write the evidence file using the configured evidence path.
5. Return the structured report to the primary agent.
5. Do not merge, rebase, reset, push, open a PR, or edit Conductor state files.

## Verification Strategy

### Layers

- **Static:** lint (`gd-tools lint`), format check (`gd-tools format --check`),
  GDScript type feedback from the editor's built-in language server (port
  6005; clean editor log), import check (`godot --headless --import --path
  .`)
- **Unit:** logic-bearing behavior and edge cases (`gd-tools test`) — movement
  tuning math, save/load round-trips and corrupt recovery, key/door state
  machines, hint-timer logic, gem respawn, AssetFactory spec completeness
- **Integration:** module boundaries and scene flows via the same native
  runtime — robot enters trampoline Area2D and launches, door with 3 keys
  opens, hint timer fires after inactivity
- **Visual:** deterministic snapshot comparison (`assert_snapshot`) for
  generated textures, audio buffers, HUD digits, and palette output — plus a
  live `editor_screenshot` of every touched scene, stored under
  `.conductor/evidence/`, so review sees what the player sees.
- **Smoke (live, godot-ai MCP):** the running editor proves the game boots and
  the touched content exists in a real scene tree. `session_manage` (`op:
  "list"`) shows this project `ready`; `editor_state` agrees on project and
  scene; `scene_get_hierarchy` on the touched scene returns a sane tree;
  `project_run` starts the game and the touched scene plays (returned to
  `stopped` afterwards). Any phase touching scenes, nodes, or visible behavior
  runs these; pure-logic phases (math, save format, timers) need only the
  session-live check.

### Commands

| Layer | Command | Required |
| --- | --- | --- |
| static | `gd-tools lint` | yes |
| static | `gd-tools format --check` | yes |
| unit | `gd-tools test` | yes |
| coverage | `gd-tools test --coverage --min 80` | yes |
| integration | `gd-tools test` | yes |
| visual | `gd-tools test` | yes |
| visual (live) | `editor_screenshot` via godot-ai MCP → `.conductor/evidence/` | yes, when anything visible changes |
| smoke (live) | `session_manage` `op: "list"` via godot-ai MCP (session live, `readiness: ready`) | yes |
| smoke (live) | `scene_get_hierarchy` via godot-ai MCP (touched scene opens, tree sane) | yes, when a scene is touched |
| smoke (live) | `project_run` via godot-ai MCP (game starts, touched scene plays, back to `stopped`) | yes, when anything playable is touched |

### Services and Fixtures

- **Services:** godot-ai MCP live editor bridge (managed server via `uvx`,
  `godot-ai 4.3.1`; editor addon `godot_ai` v4.3.1; auth WS `:9500` loopback,
  HTTP `:8000`). No database, no network, no ports of our own.
- **Editor requirement:** the project must be open in Godot 4.7+ with the
  session `readiness: "ready"` for any smoke (live) check. An empty session
  list means the editor is closed — open it, do not fake the checks.
- **Containers:** none
- **Database:** none (save format is JSON via `FileAccess` to `user://`)
- **Fixtures/seed data:** area layout records (`AreaLayout`) and palette
  records in code; corrupt-save fixtures for recovery tests
- **Environment variables:** `GODOT_BIN` when the Godot binary is not on `PATH`
- **Start/stop commands:** `godot --path .` to run the game; close the window
  to stop

### Pass Criteria

- Every required command exits `0`.
- The coverage gate (80, new-code scope) is met for logic-bearing modules.
  Art/frame-data generation code is excluded from the gate.
- Every acceptance criterion has a test or a documented evidence artifact.
- The live editor session for this project reports `readiness: "ready"`.
- Every touched scene opens in the editor with a sane hierarchy, a captured
  screenshot sits under `.conductor/evidence/`, and (when anything playable
  changed) a smoke run started the game and returned to `stopped`.
- No new Critical or High review findings remain. (`review.strict: true` —
  Medium findings block until fixed, accepted with reason, or tracked.)

### Evidence

Write a report to:

```text
conductor/tracks/<track-id>/verification/phase-<n>.md
```

Include: title; track, phase, date, branch, base and head commits; result
(`verified`, `failed`, `blocked`, or `partial`); a commands table (layer,
command, exit, summary); a live-checks table (MCP tool, target scene/node,
result, screenshot path); an acceptance-criteria table (ID, criterion, evidence,
status); evidence paths; deviations; and notes. Put binaries, screenshots, and
large reports under `.conductor/evidence/`; that directory is gitignored. The
report itself is committed with the track.

### Fallback Ladder

1. Run the full configured layer.
2. If the Godot binary is missing, set `GODOT_BIN` or install Godot 4.7+ and
   re-run.
3. If the editor session is offline (empty `session_manage` list), open the
   project in Godot and re-run the live checks. If the editor genuinely cannot
   run here, complete the shell layers, mark the phase `partial` with reason
   `editor-offline-live-checks`, and name the missing screenshots/smoke run.
4. If a device-only check cannot run (Android tablet, touch input), run the
   narrowest reliable desktop subset and mark the phase `partial` with the
   reason.
4. Stop and ask the user (via the question tool) only for credentials, hardware,
   or an external approval.

### Retry Policy

- A failed check may be fixed and re-run at most **2** times.
- If it still fails, report `failed` with the command and output.
- Never mark a phase `verified` when a required check did not run.

### Human-Only Exceptions

- Android tablet testing (touch controls, 60 FPS on mid-range hardware)
- Playtest session with a real 4-year-old and the resulting tuning pass
- Windows/Android export verification from the Godot editor

## Quality Gates

Before a phase is accepted:

- [ ] Required tests pass (`gd-tools test`)
- [ ] Coverage gate is met for new logic-bearing code (`gd-tools test --coverage --min 80`)
- [ ] Lint and format checks pass (`gd-tools lint`, `gd-tools format --check`)
- [ ] Editor/LSP static feedback is clean (no script diagnostics; clean editor log)
- [ ] Live editor session for this project is `ready` (`session_manage` list)
- [ ] Touched scenes open with a sane hierarchy (`scene_get_hierarchy`)
- [ ] Screenshots of touched scenes captured to `.conductor/evidence/` and linked in evidence
- [ ] Smoke run started the game and returned to `stopped` (`project_run`, when anything playable changed)
- [ ] Code follows the applicable `conductor/code_styleguides/`
- [ ] No secrets, credentials, or PII are introduced (no network I/O, no external asset loads)
- [ ] Public behavior is documented when it changed
- [ ] Tuning values live in the constants/config file, not scattered
- [ ] Toddler experience holds: oversized touch targets, immediate feedback, no reading required
- [ ] Evidence is written and linked in `plan.md`

## Commit Guidelines

### Message Format

```text
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: new feature
- `fix`: bug fix
- `docs`: documentation only
- `style`: formatting
- `refactor`: behavior-preserving change
- `test`: tests only
- `chore`: maintenance

### Examples

```bash
git commit -m "feat(movement): add hold-to-move robot controller"
git commit -m "fix(save): recover gracefully from corrupt progress file"
git commit -m "test(hint): cover 30-second inactivity hint trigger"
```

Task-level commits are made by the phase subagent. The primary squashes them
into one phase commit on acceptance, unless a foreign commit landed in the range.
The plan update is a separate state commit.

## Definition of Done

A track is complete when:

1. Every phase is `verified` with a checkpoint and evidence.
2. The integrated verification on the track branch passes.
3. Review is `PASS`, or every finding is fixed, accepted with a reason, or
   tracked as an issue. No Critical or High finding remains unresolved without an
   explicit user override recorded in `review.md`.
4. Post-review documentation sync is complete.
5. The registry and `metadata.json` show the track as complete.
6. When a remote exists, the branch is pushed. When `pr.enabled` is true, a PR
   is open or `pr_state: "unavailable"` records that PR creation could not run.
   When `pr.enabled` is false, no PR is expected.

## Emergency Procedures

### Critical Bug Found During Playtest

1. Create a fix task in `plan.md` (do not fix outside the workflow).
2. Write a failing test reproducing the bug (logic) or define expected
   snapshot/behavior (visual).
3. Implement the minimal fix; verify with the real 4-year-old tester.

### Save Data Corruption

1. Stop further save writes.
2. Reproduce with a corrupt-file test case.
3. Ensure fallback to fresh start never crashes and never loses the whole
   session experience.
4. Document in `plan.md`.

### Security Breach

1. No networked services exist in v1; confirm no external asset or data channel
   was introduced.
2. Rotate any exposed secret and review access logs.
3. Patch the vulnerability and add a regression test.
4. Document the incident and update the recovery procedure.

## Continuous Improvement

- Review this workflow after each track.
- Update commands and verification layers when the tooling changes.
- Record recurring review findings as process improvements.
- Keep the process as small as the project allows.

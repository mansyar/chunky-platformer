# Project Workflow — Robo's Treasure Hunt

## Guiding Principles

1.  **The Plan is the Source of Truth:** All work must be tracked in `plan.md`
2.  **The Tech Stack is Deliberate:** Changes to the tech stack must be
    documented in `tech-stack.md` *before* implementation
3.  **Test-Driven Development — for logic-bearing code:** Write unit tests
    before implementing game logic (physics tuners, save/load, hint logic,
    collectible state, door/key state, AssetFactory generation logic).
    Purely visual code (pixel-drawing DSL internals, frame data, palette
    records) is exempt from TDD; it is verified via deterministic snapshot
    tests instead (see Testing Requirements).
4.  **High Code Coverage — scoped to logic:** Aim for >80% coverage of
    logic-bearing modules via `gd-tools test --coverage --min 80`.
    Art/frame-data generation code is excluded from the gate.
5.  **User Experience First:** Every decision prioritizes the 4-year-old
    player (see `product-guidelines.md`)
6.  **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use
    `CI=true` for watch-mode tools to ensure single execution.

## Task Workflow

All tasks follow a strict lifecycle:

### Standard Task Workflow

1.  **Select Task:** Choose the next available task from `plan.md` in
    sequential order

2.  **Mark In Progress:** Before beginning work, edit `plan.md` and change
    the task from `[ ]` to `[~]`

3.  **Define Verification First (Red Phase for logic tasks):**

    -   **Logic-bearing tasks:** Create a test suite extending `GdToolsTest`.
        Write tests that define expected behavior and acceptance criteria.
        **CRITICAL:** Run `gd-tools test` and confirm they fail as expected
        before implementing.
    -   **Visual/asset tasks:** Define expected outputs as a deterministic
        snapshot (`assert_snapshot`) or golden comparison first, then
        implement generation to match.
    -   **Scene/layout tasks** (TileMap layouts, node placement): verify via
        the phase's manual verification plan instead of unit tests.

4.  **Implement to Pass (Green Phase):** Write the minimum code necessary
    to make the failing tests/snapshots pass.

5.  **Refactor (Optional but Recommended):** Improve clarity and remove
    duplication with passing tests as the safety net; re-run tests.

6.  **Verify Coverage (logic tasks):** Run
    `gd-tools test --coverage --min 80 --show-uncovered`. Target >80% for
    new logic-bearing code.

7.  **Document Deviations:** If implementation differs from tech stack:

    -   **STOP** implementation
    -   Update `tech-stack.md` with the new design
    -   Add a dated note explaining the change
    -   Resume implementation

8.  **Commit Code Changes:**

    -   Stage all changes related to the task.
    -   Commit with a conventional message, e.g.
        `feat(movement): Add hold-to-move robot controller`.

9.  **Attach Task Summary with Git Notes:**

    -   **Step 9.1:** Get the commit hash: `git log -1 --format="%H"`
    -   **Step 9.2:** Draft a summary: task name, changes, files touched,
        and the core "why".
    -   **Step 9.3:** Attach it: `git notes add -m "<note content>" <hash>`

10. **Get and Record Task Commit SHA:**

    -   **Step 10.1:** Update `plan.md`: change the task from `[~]` to `[x]`
        and append the first 7 characters of the commit hash.
    -   **Step 10.2:** Write the updated `plan.md`.

11. **Commit Plan Update:**

    -   Commit with e.g. `conductor(plan): Mark task 'X' as complete`.

### Task Correction & Plan Amendment Workflows

1.  **In-Flight Refinements:** Minor gaps found while a task is `[~]` are
    fixed directly in the active stream, with passing tests before commit.
2.  **Code Review Corrections (`conductor-review`):** The review agent
    appends a `Review Fixes` phase to `plan.md` for tracked corrections.
3.  **Logical State Reversions (`conductor-revert`):** Fundamentally flawed
    tasks are reverted via git and reset to `[ ]` in `plan.md`.

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** Immediately after a task that concludes a phase in `plan.md`.

1.  **Announce Protocol Start** to the user.

2.  **Ensure Test Coverage for Phase Changes:**

    -   Determine phase scope via the previous phase's checkpoint SHA from
        `plan.md` (or all commits if none exists).
    -   List changed files: `git diff --name-only <sha> HEAD`.
    -   For each **logic-bearing** `.gd` file changed, verify a test suite
        exists; create one if missing (match existing suite naming/style).
        Pure visual/frame-data files are exempt but must have their
        snapshots still passing.

3.  **Execute Automated Tests with Proactive Debugging:**

    -   Announce the exact command first, e.g.
        **Command:** `gd-tools test --coverage --min 80`
    -   On failure: inform the user, propose fixes (maximum two attempts),
        then stop and ask for guidance if still failing.

4.  **Propose a Detailed, Actionable Manual Verification Plan:**

    Analyze `product.md`, `product-guidelines.md`, and `plan.md` to produce
    step-by-step manual verification (e.g. *"Run the scene with F5; hold
    right arrow; confirm Robo walks at constant speed and the camera
    follows; tap Space; confirm jump with forgiving coyote time"*).

5.  **Await Explicit User Feedback** — pause until the user confirms.

6.  **Identify Target Commit** (last functional commit of the phase; no
    empty checkpoint commits).

7.  **Attach Auditable Verification Report** via `git notes` to that commit.

8.  **Record Phase Checkpoint SHA:** Append `[checkpoint: <sha>]` to the
    phase heading in `plan.md` and write it.

9.  **Commit Plan Update:**
    `conductor(plan): Mark phase '<PHASE NAME>' as complete`.

10. **Announce Completion** to the user.

## Quality Gates

Before marking any task complete, verify:

- [ ] All tests/snapshots pass (`gd-tools test`)
- [ ] Logic-bearing coverage meets >80% (`gd-tools test --coverage --min 80`)
- [ ] Code follows style guides (`gd-tools format --check`, `gd-tools lint`)
- [ ] All public functions/methods documented (GDScript doc comments)
- [ ] Static typing used where practical
- [ ] No security issues (no network I/O, no external file loading)
- [ ] Works at target frame rate on mid-range hardware (delta-time-safe)
- [ ] Tuning values live in the constants/config file, not scattered
- [ ] Documentation updated if needed

## Development Commands

### Setup

```bash
pip install gd-tools-cli      # gd-tools CLI (requires Python 3.10+, Godot 4.5+)
godot --version               # verify Godot binary on PATH or GODOT_BIN
gd-tools init                 # bootstrap test/coverage addons + configs
gd-tools install-hooks --all  # pre-commit: format + lint + test
```

### Daily Development

```bash
gd-tools test                 # run test suites (GdToolsTest runtime)
gd-tools test --watch         # re-run affected suites on save
gd-tools test --coverage --min 80   # tests + coverage gate
gd-tools lint                 # gdlint
gd-tools format               # gdformat
godot --path .                # run the game (or open in editor)
```

### Before Committing

```bash
gd-tools format --check && gd-tools lint && gd-tools test
```

## Testing Requirements

### Unit Testing (logic-bearing code only)

- Suites extend `GdToolsTest` (gd-tools native runtime), live in `tests/`,
  named `test_<subject>.gd`.
- Cover: movement/physics tuning math, save/load round-trips and corrupt
  file recovery, key/door state machines, hint-timer logic, gem respawn
  logic, AssetFactory output completeness (asset spec coverage).
- Test both success and failure paths; use doubles/spies for engine-bound
  collaborators where needed.
- **Exempt from unit tests:** pixel-drawing helpers' visual output, frame
  data arrays, palette records, scene layouts.

### Snapshot Testing (visual generation)

- Generated textures/audio are deterministic; pin key outputs with
  `assert_snapshot` (gd-tools) so palette/DSL changes that accidentally
  alter visuals fail loudly. Update with `--snapshot-update` when changes
  are intentional.

### Integration Testing

- Scene-level tests for core flows: robot enters trampoline Area2D → gets
  launched; door with 3 keys → opens; hint timer fires after inactivity.

### Device Testing

- Test on Windows desktop (keyboard) and Android export (touch) before
  phase checkpoints involving input or performance.
- Verify 60 FPS behavior and delta-time correctness, especially physics.

## Code Review Process

### Self-Review Checklist

1.  **Functionality** — works as specified; no frustration states introduced
2.  **Code Quality** — style guide, DRY, clear names, comments where needed
3.  **Testing** — logic tests comprehensive; snapshots current; coverage ≥80%
4.  **Safety** — no network I/O, no external asset loads, safe save handling
5.  **Performance** — no per-frame allocations in hot paths; delta-time safe
6.  **Toddler Experience** — touch targets oversized; feedback immediate;
    no reading required; nothing loud or startling

## Commit Guidelines

### Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting only
- `refactor`: Neither fixes a bug nor adds a feature
- `test`: Adding missing tests
- `chore`: Maintenance tasks

### Examples

```bash
git commit -m "feat(movement): Add hold-to-move robot controller"
git commit -m "fix(save): Recover gracefully from corrupt progress file"
git commit -m "test(hint): Cover 30-second inactivity hint trigger"
```

## Definition of Done

A task is complete when:

1.  All code implemented to specification
2.  Logic tests written and passing (or snapshots current for visual tasks)
3.  Logic-bearing coverage meets the project threshold
4.  Code passes lint/format checks
5.  Implementation notes added to `plan.md`
6.  Changes committed with a proper message
7.  Git note with task summary attached to the commit

## Emergency Procedures

### Critical Bug Found During Playtest

1.  Create a fix task in `plan.md` (do not fix outside the workflow)
2.  Write a failing test reproducing the bug (logic) or define expected
    snapshot/behavior (visual)
3.  Implement the minimal fix; verify with the real 4-year-old tester

### Save Data Corruption

1.  Stop further save writes
2.  Reproduce with a corrupt-file test case
3.  Ensure fallback to fresh start never crashes and never loses the whole
    session experience
4.  Document in `plan.md`

## Continuous Improvement

- Review the workflow after each playtest checkpoint
- Update tuning constants based on real kid behavior; document in `plan.md`
- Keep things simple and maintainable

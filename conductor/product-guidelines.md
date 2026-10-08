# Product Guidelines — Robo's Treasure Hunt

## Design Philosophy

**The toddler is the harshest reviewer.** Every design decision is judged by:
can a 4-year-old succeed at this without reading, without instructions, and
without a grown-up's help? If a mechanic requires timing precision, memory of
rules, or text comprehension, it is wrong for this product.

## UX Principles

1. **Zero failure states.** No death, no timers, no dead ends, no "try again"
   screens. Falling is fun; being stuck triggers help automatically.
2. **No reading required.** All communication is visual (icons, sparkles,
   counters, animations) or audio (cheerful sounds). No text the child must
   understand to play.
3. **Constant feedback.** Every action produces an immediate, juicy response:
   squash on landing, sparkle on collect, wobble on bounce. The world should
   feel alive even when nothing is happening.
4. **Big everything.** Touch targets are oversized (a toddler's thumb is not
   precise). Important objects (keys, doors) are large and visually loud.
5. **Short-cycle joy.** Rewards arrive every 10–30 seconds (gem pop, bounce,
   sparkle discovery). Long stretches without feedback are a design bug.
6. **One idea at a time.** Each area introduces exactly one new visual idea.
   No combined mechanics that require understanding two systems at once.

## Voice & Tone

- The game never talks down to the child and never punishes.
- Robo (the character) is a friendly companion, not an avatar to "win" with:
  curious, bouncy, expressive. Squash & stretch on every landing; eyes/face
  react to discoveries.
- Celebrations are earned and generous: confetti, dance animation, music
  flourish when a door opens. Nothing is graded or scored against the child.

## Visual Style (Code-Generated Art)

- **Palette:** Bright, high-saturation, toddler-friendly colors. Each area has
  its own palette family (e.g. meadow: fresh greens/sky blue; cave: cool
  purples/teals with glowing gems; sunset hills: warm oranges/pinks).
- **Shapes:** Chunky, rounded silhouettes. No sharp edges, no thin fragile
  geometry. The robot is visibly "squishy" — rounded body, big eyes.
- **Rendering:** All sprites drawn in code (Polygon2D / `_draw()` /
  procedurally generated textures). Shared art pipeline with palette
  parameters so area theming is a config change, not a rewrite.
- **Animation:** Procedural (code-driven tweens and squash/stretch), no
  frame-by-frame sprite sheets.

## Audio Style (Code-Generated)

- **SFX:** Soft, rounded synthesized tones. No harsh or loud sounds; nothing
  startling. Collect = bright pop; bounce = boing; door = rising chime.
- **Music:** Gentle ambient loop per area, slow tempo, no sudden transitions.
  Volume is conservative — a background presence, never overwhelming.

## Accessibility & Safety

- No external links, no purchases, no chat, no data collection.
- Session-safe: progress saves automatically; closing the app mid-play never
  loses more than the last few seconds of movement.
- Screen-safe: no flashing faster than ~3 Hz, no full-screen abrupt flashes.

## Quality Bar for v1

- Area 1 completable by a 4-year-old unaided (verified in a real playtest).
- 60 FPS on a mid-range tablet; graceful behavior at lower frame rates
  (physics tuned with delta time, never per-frame constants).
- All tuning values (speeds, impulses, hint delay, respawn time) live in one
  constants/config file so playtest adjustments are single-line edits.

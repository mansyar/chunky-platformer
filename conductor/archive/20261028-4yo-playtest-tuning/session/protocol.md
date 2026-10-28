# Playtest Session Protocol — Area 1 (Meadow) with a 4-year-old

> Track: `20261028-4yo-playtest-tuning` · Phase 1 prep artifact.
> This protocol defines the FR-1 session conditions so any adult can re-run it
> (NFR-3). No session data lives here — observations go in `notes.md`
> (filled from `notes-template.md` in Phase 2).

## 1. Setup checklist

Do these in order, before the child picks up the device:

1. **Device:** touch tablet (landscape), charged, brightness up, notifications /
   interruptions silenced.
2. **Run method:** Godot editor open on this project; run the game from the
   editor on the tablet-visible session. If the editor run fails on the day,
   **do not silently fall back to desktop touch-emulation** — record the
   failure as a deviation and reschedule the tablet run (spec Edge Cases).
3. **Area 1 fresh save:** delete or reset `user://save_game.json` so Area 1
   (Meadow) starts unplayed — zero gems taken, door locked, robot at the
   area spawn. Confirm the title/menu leads straight into Area 1.
4. **Touch check (adult, 30 seconds):** tap left/right touch zones, tap jump —
   confirm the robot moves and jumps on the tablet. Hand the device over only
   after this passes.
5. **15-minute timer:** start a visible timer the moment the child first touches
   the screen. Hard stop at 15:00 regardless of progress.
6. **Observer kit:** this protocol + a blank copy of `notes-template.md`
   (paper or second screen). No video, no photos, no names anywhere (NFR-2).

## 2. Silent-observation rules

- **No instructions.** Do not explain controls, goals, gems, keys, or the door.
  A neutral invitation only: *"Here is a game you can play."*
- **No coaching sounds.** No "try the other way", no pointing, no reacting to
  mistakes. Neutral encouragement ("mm-hmm") is fine if the child looks at you.
- **Rescue only on hard-stuck.** A hard-stuck is: the child is visibly
  frustrated (verbal complaint, repeated failing action, or trying to hand the
  device back) AND has made no forward progress for ~60 seconds. Rescue = the
  smallest adult touch that unblocks (e.g. one jump, one walk-past), then hands
  back immediately. Every rescue is logged in the timeline as a **stuck event**
  — the stuck itself is a finding, even though play continues.
- **Upset → stop immediately.** Any crying, anger, or "I don't want to" ends
  the session on the spot (NFR-1). Partial notes still count as evidence.
  Comfort the child; the game can wait.
- **Do not extend.** When the timer ends, or the child completes Area 1, or
  the child voluntarily stops — the session is over. Thank them and stop the
  timer.

## 3. What to watch for

Record timestamps (mm:ss from first touch) for each:

- **First input latency:** seconds from hand-over to the first intentional
  touch that moves/jumps the robot. Hesitation or random tapping counts —
  note which.
- **Stalls:** any 15+ second span with no forward progress (wandering,
  repeated jumps against a wall, standing still, tapping UI). Note location
  and what the child tried.
- **Gem discovery:** first gem collected — accidental or deliberate? Does the
  child then seek more gems?
- **Key discovery:** first key collected — reaction? Does the child connect
  keys to the door?
- **Door reach:** first arrival at the door (with and without enough keys).
  What does the child do at a locked door — try, leave, stall?
- **Engagement signals:** laughing, narrating, bouncing, showing the screen
  to the adult (positive) vs sighing, frowning, device-shifting, looking away
  (negative). Note time and trigger for each clear signal.
- **Unaided completion:** did Area 1 complete with zero rescues and zero
  instructions? If yes, that is the headline result.

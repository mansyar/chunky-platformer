class_name Tuning
## Single source of truth for every gameplay tuning value.
##
## Why one file: the quality bar requires all tuning in one place so a
## parent/designer can adjust feel without hunting through scripts.
## Values are world-space pixels (tile size = 16px, see AssetSpec).
##
## Jump/bounce heights derive from impulse & gravity: h = v^2 / (2*g).
## Jump: 240^2 / (2*600) = 48px = 3 tiles. Bounce: 320^2 / (2*600) = 85px = ~5 tiles.

const TILE_SIZE := 16.0

## Horizontal movement
const WALK_SPEED := 40.0  # 2.5 tiles/s
const ACCEL_TIME := 0.1  # seconds to reach target speed (start and stop)

## Jump & gravity
const JUMP_IMPULSE := 260.0  # apex ~56px (3.5 tiles): clears 2-tile steps generously
const GRAVITY := 600.0  # gentler than Godot's 980 for floaty toddler arcs
const FALL_SPEED_CAP := 220.0  # terminal fall speed so drops never feel scary

## Trampoline
const BOUNCE_IMPULSE := 400.0
# Toddler step assist: walking into a low ledge while holding a direction
# gives an automatic hop onto it, so staircases need zero jump precision.
# The boost rises ~44px (clears a 2-tile ledge with margin); the ledge
# window is >2 tiles (32px) but well under 3 tiles (48px).
const STEP_UP_BOOST := 230.0
const STEP_UP_MAX_LEDGE := 34.0  # ~6.7-tile arc: clears the bridge; higher than a jump

## Grace timers
const COYOTE_TIME := 0.1  # seconds of forgiveness after walking off an edge
const JUMP_BUFFER := 0.1  # seconds a jump press is remembered before landing

## Animation feel
const IDLE_ANIM_FPS := 2.0  # gentle two-frame bob
const WALK_ANIM_FPS := 8.0  # brisk enough to read as walking at 2.5 tiles/s
const LAND_SQUASH_TIME := 0.15  # seconds the squash frame holds after landing

## Camera
const CAMERA_SMOOTHING := 8.0  # lerp weight for follow smoothing

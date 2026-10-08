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
const JUMP_IMPULSE := 240.0  # reaches 3 tiles high
const GRAVITY := 600.0  # gentler than Godot's 980 for floaty toddler arcs
const FALL_SPEED_CAP := 220.0  # terminal fall speed so drops never feel scary

## Trampoline
const BOUNCE_IMPULSE := 320.0  # clearly higher than a normal jump

## Grace timers
const COYOTE_TIME := 0.1  # seconds of forgiveness after walking off an edge
const JUMP_BUFFER := 0.1  # seconds a jump press is remembered before landing

## Animation feel
const IDLE_ANIM_FPS := 2.0  # gentle two-frame bob
const WALK_ANIM_FPS := 8.0  # brisk enough to read as walking at 2.5 tiles/s
const LAND_SQUASH_TIME := 0.15  # seconds the squash frame holds after landing

## Camera
const CAMERA_SMOOTHING := 8.0  # lerp weight for follow smoothing

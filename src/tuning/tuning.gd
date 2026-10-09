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
const JUMP_IMPULSE := 240.0  # apex 48px = 3 tiles: clears 2-tile steps with margin
const GRAVITY := 600.0  # gentler than Godot's 980 for floaty toddler arcs
const FALL_SPEED_CAP := 220.0  # terminal fall speed so drops never feel scary

## Trampoline
const BOUNCE_IMPULSE := 400.0  # ~6.7-tile arc: clears the bridge; higher than a jump
# Toddler step assist: walking into a low ledge while holding a direction
# gives an automatic hop onto it, so staircases need zero jump precision.
# The boost rises ~44px (clears a 2-tile ledge with margin); the ledge
# window is >2 tiles (32px) but well under 3 tiles (48px).
const STEP_UP_BOOST := 230.0
const STEP_UP_MAX_LEDGE := 34.0  # just over 2 tiles: the auto-hop ledge window

## Grace timers
const COYOTE_TIME := 0.1  # seconds of forgiveness after walking off an edge
const JUMP_BUFFER := 0.1  # seconds a jump press is remembered before landing

## Animation feel
const IDLE_ANIM_FPS := 2.0  # gentle two-frame bob
const WALK_ANIM_FPS := 8.0  # brisk enough to read as walking at 2.5 tiles/s
const LAND_SQUASH_TIME := 0.15  # seconds the squash frame holds after landing

## Camera
const CAMERA_SMOOTHING := 8.0  # lerp weight for follow smoothing

# Collect & Play (collect_play_20261008)
const GEM_RESPAWN_TIME := 10.0  # seconds a collected gem stays hidden
const GEM_BOB_AMPLITUDE := 3.0  # idle bob height in pixels
# Idle bob angular speed in rad/s (~2 second period).
const GEM_BOB_SPEED := 3.0
# Generous: a toddler should never walk past a gem without collecting it.
const GEM_PICKUP_RADIUS := 10.0
# Goal Loop (goal_loop_20261008) - keys. A key is permanent, so its bob and
# glow exist only to make it findable, never to move its sensor.
const KEY_BOB_AMPLITUDE := 3.0
const KEY_BOB_SPEED := 2.5  # slower than a gem: keys should feel more special
const KEY_PICKUP_RADIUS := 12.0  # generous: reaching a key should never be a near miss
const KEY_GLOW_DEPTH := 0.35  # how far the art tints toward KEY_GLOW_TINT
const KEY_GLOW_TINT := Color(1.35, 1.35, 0.9)  # a warm bloom, not a colour change
const KEY_COUNTER_MARGIN := Vector2(48, 140)  # directly below the gem badge
const KEY_BUMP_TIME := 0.25
# Hint system - the anti-frustration safety net. Long enough that ordinary
# wandering is never interrupted, short enough that a truly stuck child does
# not lose interest first.
const HINT_DELAY := 30.0
const HINT_SHOW_TIME := 4.0  # the trail dissolves after this; it is a nudge, not wallpaper
const HINT_SPARKLE := Color(1.0, 0.85, 0.35)  # warm gold, reads as 'go here'
const POINT_HOLD_TIME := 1.5  # how long Robo holds the pointing pose
const TRANSITION_TIME := 1.2  # seconds for the full palette fade between areas
# Collection juice (collect_play_20261008): pop ring + sparkle burst.
const POP_LIFETIME := 0.45  # seconds the pop effect lives
const POP_START_RADIUS := 4.0  # ring radius at birth
const POP_END_RADIUS := 20.0  # ring radius at death
const SPARKLE_COUNT := 6  # fixed sparkle count, no randomness
# Robo's visual-only celebration squash.
const CELEBRATE_TIME := 0.3  # total squash-and-return duration in seconds
const CELEBRATE_SQUASH := Vector2(1.25, 0.75)  # peak squash on the sprite

# HUD counter (collect_play_20261008): screen-space, top-left, big digits.
const COUNTER_SCALE := 4.0  # 8x12 digit glyph -> 32x48 on screen
const COUNTER_MARGIN := Vector2(48, 40)  # top-left inset in screen pixels
const COUNTER_BUMP_TIME := 0.25  # counter squash-pulse duration in seconds

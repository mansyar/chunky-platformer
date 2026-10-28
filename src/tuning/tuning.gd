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

# Collect & Carry (gem_shop_20261027): gems are a fixed per-area budget with
# no respawn. See AreaLayout.GEMS_PER_AREA for the per-area count.
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

# Gift machine + cosmetics (gem_shop_20261027 Phase 2): one friendly machine
# per area turns banked gems into surprise looks. Prices are numerals + gem
# pips (no words); the surprise order is cheapest-unowned-first — the kindest
# math — with duplicates only after the 6-item set is complete. The bonus
# celebration after that is free.
const GIFT_TIER_1 := 1
const GIFT_TIER_2 := 2
const GIFT_TIER_3 := 3
const COSMETIC_SET_TOTAL := 12
# World-space tap zone (diameter 48 * camera zoom 4 = 192 screen px, well
# above the 64px minimum touch target).
const MACHINE_TAP_RADIUS := 24.0
# Kind wiggle on an empty-wallet tap: duration in seconds + peak tilt.
const MACHINE_WIGGLE_TIME := 0.4
const MACHINE_WIGGLE_TILT := 0.12
# Dispense pop length; doubles as the tap serializer (one gift at a time).
const MACHINE_DISPENSE_TIME := 0.45
# Minimum screen-space touch target both ways (machine tap, Robo tap).
const MACHINE_TOUCH_MIN := 64.0
# Trail dots drawn behind Robo, and the sunny body tint, per worn cosmetic.
const TRAIL_BUBBLES_COLOR := Color(0.65, 0.9, 1.0)
const TRAIL_SPARKLE_COLOR := Color(1.0, 0.85, 0.35)
const ROBO_SUNNY_TINT := Color(1.1, 1.0, 0.8)

# Audio synthesis (audio_synthesis_20261027 Phase 1): every SFX is a
# pre-generated 8-bit mono AudioStreamWAV. Short one-shots stay instantly
# regenerable; volumes stay conservative so 8 stacked voices never startle.
const AUDIO_SAMPLE_RATE := 22050
const AUDIO_FORMAT_BITS := 8
const AUDIO_CHANNELS := 1
# Polyphonic voice cap: at most this many one-shots overlap; the oldest
# voice is stolen first so mashing never clips and never drops ambient.
const AUDIO_MAX_VOICES := 8
# Soft-envelope shape: a short linear attack plus a cosine release over the
# tail fraction, so no buffer starts or ends with a harsh transient.
const AUDIO_ATTACK_TIME := 0.012
const AUDIO_RELEASE_FRACTION := 0.35
# Per-SFX voice: duration in seconds, linear pitch sweep (start/end Hz),
# peak linear volume (conservative: never above 0.4), and an optional
# gentle vibrato (rate Hz + depth Hz, both 0 when unused) for boing/wiggle.
const AUDIO_SFX_NAMES: Array[String] = [
	"jump",
	"bounce",
	"gem",
	"key",
	"door",
	"celebrate",
	"gift_pop",
	"gift_wiggle",
	"gift_bonus",
]
const AUDIO_SFX := {
	"jump":
	{
		"duration": 0.25,
		"freq_start": 300.0,
		"freq_end": 620.0,
		"volume": 0.35,
		"wobble_rate": 0.0,
		"wobble_depth": 0.0,
	},
	"bounce":
	{
		"duration": 0.32,
		"freq_start": 180.0,
		"freq_end": 420.0,
		"volume": 0.38,
		"wobble_rate": 10.0,
		"wobble_depth": 60.0,
	},
	"gem":
	{
		"duration": 0.18,
		"freq_start": 880.0,
		"freq_end": 1320.0,
		"volume": 0.32,
		"wobble_rate": 0.0,
		"wobble_depth": 0.0,
	},
	"key":
	{
		"duration": 0.30,
		"freq_start": 660.0,
		"freq_end": 990.0,
		"volume": 0.32,
		"wobble_rate": 0.0,
		"wobble_depth": 0.0,
	},
	"door":
	{
		"duration": 0.60,
		"freq_start": 523.0,
		"freq_end": 784.0,
		"volume": 0.34,
		"wobble_rate": 0.0,
		"wobble_depth": 0.0,
	},
	"celebrate":
	{
		"duration": 0.80,
		"freq_start": 523.0,
		"freq_end": 1046.0,
		"volume": 0.38,
		"wobble_rate": 5.0,
		"wobble_depth": 30.0,
	},
	"gift_pop":
	{
		"duration": 0.20,
		"freq_start": 700.0,
		"freq_end": 1050.0,
		"volume": 0.34,
		"wobble_rate": 0.0,
		"wobble_depth": 0.0,
	},
	"gift_wiggle":
	{
		"duration": 0.40,
		"freq_start": 450.0,
		"freq_end": 550.0,
		"volume": 0.32,
		"wobble_rate": 7.0,
		"wobble_depth": 80.0,
	},
	"gift_bonus":
	{
		"duration": 0.70,
		"freq_start": 880.0,
		"freq_end": 1760.0,
		"volume": 0.36,
		"wobble_rate": 0.0,
		"wobble_depth": 0.0,
	},
}

# Audio ambience (audio_synthesis_20261027 Phase 2): one gentle loop per
# area plus the crossfade + ducking mix. Loops render at the shared sample
# rate so SFX + loops stay sub-second together; every chord frequency and
# every tremolo rate completes whole cycles inside AUDIO_AMBIENT_DURATION
# so each loop wraps click-free.
const AUDIO_AMBIENT_NAMES: Array[String] = ["meadow", "cave", "sunset"]
const AUDIO_AMBIENT_DURATION := 2.0
const AUDIO_AMBIENT_VOLUME := 0.3
# Gentle area change: outgoing and incoming loops overlap for this long.
const AUDIO_CROSSFADE_TIME := 0.8
# While a one-shot SFX plays the loop steps back by this many dB, then
# restores; notify_sfx_played holds the duck for AUDIO_DUCK_TIME.
const AUDIO_DUCK_DB := 6.0
const AUDIO_DUCK_TIME := 0.5
# Per-area voice: three-tone chord in Hz (bright meadow major, hollow low
# cave fifth + octave, warm sunset major) under a slow breathing tremolo
# (rate Hz completes whole cycles too, depth 0..1 keeps it gentle).
const AUDIO_AMBIENT := {
	"meadow":
	{
		"freqs": [262.0, 330.0, 392.0],
		"lfo_rate": 1.0,
		"lfo_depth": 0.25,
	},
	"cave":
	{
		"freqs": [110.0, 165.0, 220.0],
		"lfo_rate": 0.5,
		"lfo_depth": 0.3,
	},
	"sunset":
	{
		"freqs": [196.0, 247.0, 294.0],
		"lfo_rate": 1.5,
		"lfo_depth": 0.2,
	},
}

# Parent gate (parent_gate_20261028): a hidden hold-to-quit in the extreme
# top-right corner. A stationary hold of QUIT_HOLD_SECONDS inside a
# QUIT_ZONE_RADIUS circle around the corner flushes the save and quits.
const QUIT_ZONE_RADIUS := 64.0
const QUIT_HOLD_SECONDS := 3.0
# Hold feedback (parent_gate_20261028 Phase 2): the ring that fills at the
# touch point plus the soft tick clock. One gentle tick per second keeps the
# wait legible without nagging; the small ring stays fully on screen.
const QUIT_TICK_INTERVAL := 1.0
const QUIT_RING_RADIUS := 28.0
const QUIT_RING_WIDTH := 6.0
